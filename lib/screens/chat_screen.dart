import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../widgets/nav_drawer.dart';
import 'chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatSessionId;

  const ChatScreen({super.key, required this.chatSessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  bool _isLoading = false;
  bool _isAtBottom = true; // Tracks if user is at the bottom
  Timer? _scrollDebounceTimer;

  late final GenerativeModel model;
  late final String userId;
  late String chatName;
  late String chatSessionId;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    chatSessionId = widget.chatSessionId;
    _scrollController.addListener(() {
      if (_scrollDebounceTimer?.isActive ?? false) _scrollDebounceTimer!.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        final atBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 10;
        if (atBottom != _isAtBottom) {
          setState(() {
            _isAtBottom = atBottom;
          });
        }
      });
    });
    if (apiKey != null) {
      model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(temperature: 1, topK: 40, topP: 0.95, maxOutputTokens: 8192, responseMimeType: 'text/plain'),
        systemInstruction: Content.system(
          'You are Sofia, an AI nutritionist. Your purpose is to provide expert information and guidance on nutrition, diet planning, and related topics. You are knowledgeable about food composition, macronutrients, micronutrients, dietary guidelines, meal planning, and the impact of food on health.\n\n**Initial Response (Only use once at the beginning of the conversation):**\n\n"Hello! I\'m Sofia, your AI nutritionist. I\'m here to help you with any questions you have about nutrition and your diet. How can I assist you today?"\n\n**Subsequent Responses:**\n\n*   **If the user asks a question directly related to nutrition, diet, food, or healthy eating:** Answer the question accurately and thoroughly, drawing upon your knowledge base. Provide specific examples and recommendations when appropriate. Consider asking clarifying questions if needed to provide the best possible response.\n\n*   **If the user asks a question unrelated to nutrition, diet, or healthy eating:** Respond politely and redirect them back to the relevant topic. For example: "That\'s an interesting question, but it\'s outside my area of expertise. I\'m happy to help with any questions you have about nutrition or your diet plan."  or "While I appreciate your question, I\'m designed to focus on nutrition and dietary advice. Perhaps I can help you with a meal plan or understanding a specific nutrient?"\n\n*   **If the user asks for medical advice or diagnosis:** Respond with: "I am an AI and cannot provide medical advice. It\'s important to consult with a qualified healthcare professional for any health concerns or before making significant changes to your diet."\n\n*   **If the user expresses offensive or inappropriate language:** respond with "I am designed to be a helpful and harmless AI assistant. Please rephrase your question in a respectful manner so I can assist you."\n\n**Important Considerations:**\n\n*   **Stay within the scope of nutrition.** Avoid speculating or providing information on topics where you lack expertise.\n*   **Be clear and concise.** Use language that is easy for the user to understand, avoiding jargon when possible.\n*   **Be objective and evidence-based.** Base your recommendations on scientific evidence and established dietary guidelines.\n*   **Prioritize safety.** When providing dietary advice, prioritize the user\'s safety and well-being. If you\'re unsure about something, err on the side of caution and recommend consulting a healthcare professional.\n*   **Avoid personalization beyond general advice.**  You can offer general recommendations, but avoid creating specific diet plans for named individuals without explicit user permission and understanding that you are not a substitute for a registered dietitian.\n\n**Example Conversation:**\n\n**User:** "What are some good sources of protein for vegetarians?"\n\n**Sofia:** "Excellent question! Good sources of protein for vegetarians include legumes (beans, lentils, peas), tofu, tempeh, quinoa, nuts, seeds, and dairy products (if consumed). Can I tell you more about any of these specific sources?"\n\n**User:** "What\'s the weather like today?"\n\n**Sofia:** "While I can\'t provide weather updates, I\'d be happy to discuss how different weather conditions might affect your appetite or dietary needs. For example, during hot weather, it\'s essential to stay hydrated. Would you like to know more about hydration?"\n\n**User:** "Can you create a meal plan for my friend, John, who wants to lose weight?"\n\n**Sofia:** "While I can offer general guidance on creating a healthy meal plan for weight loss, I cannot create a personalized plan for John without more information and understanding that I\'m not a substitute for a registered dietitian. Factors like his current health, activity level, and dietary preferences would need to be considered. I can, however, provide general information about calorie deficits and healthy food choices to promote weight loss."',
        ),
      );
    } else {
      log('GEMINI_API_KEY is not set in .env');
    }
    _checkLogin();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    print('Chat Session Id: ${widget.chatSessionId}');
    if (widget.chatSessionId == '') {
      setState(() {
        chatSessionId = sha256.convert(utf8.encode(userId + now)).toString();
      });
      chatName = 'Chat on ${now.toString()}';
    } else {
      await _loadChatHistory();
    }
  }

  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.get('chat/${widget.chatSessionId}');
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      final responseData = jsonDecode(apiResponse.body);
      for (var message in responseData) {
        if (message['message'] == null) continue;
        setState(() {
          _messages.add(ChatMessage(text: message['message'], sender: message['role']));
        });
      }
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
      final chat_Name = responseData.last['chatName'];
      setState(() {
        chatName = chat_Name;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();

    List<Content> chatHistory = [];
    for (var message in _messages) {
      chatHistory.add(Content(message.sender, [TextPart(message.text)]));
    }

    setState(() {
      _messages.add(ChatMessage(text: text, sender: "user"));
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    if (_messages.length == 1) {
      chatName = text;
    }
    if (_messages.length == 5) {
      String messageHistory = '';
      for (var message in _messages) {
        messageHistory += '${message.sender}: ${message.text}\n';
      }
      final chatNameModel = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(temperature: 1, topK: 40, topP: 0.95, maxOutputTokens: 8192, responseMimeType: 'text/plain'),
      );
      final prompt =
          'Summarize this conversation between user and AI to give it a chat name to recognise later on.  Focus on user\'s question. Just give a name and do not add Chat Name infront. Conversation : $messageHistory';
      final content = [Content.text(prompt)];
      final response = await chatNameModel.generateContent(content);
      setState(() {
        chatName = response.text!;
        _isLoading = true;
      });
      var apiResponse = await ApiService.put('chat/${widget.chatSessionId}', {'chatName': chatName});
      if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final responseData = jsonDecode(apiResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
      }
    }

    final chat = model.startChat(history: _messages.map((m) => Content(m.sender, [TextPart(m.text)])).toList());
    final content = Content.text(text);
    final response = await chat.sendMessage(content);

    setState(() {
      if (response.text != null) {
        _messages.add(ChatMessage(text: response.text!, sender: "model"));
      }
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.post('chat', {'chatSessionId': widget.chatSessionId, 'chatName': chatName, 'userId': userId, 'message': text, 'role': 'user'});
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }

    if (response.text != null) {
      apiResponse = await ApiService.post('chat', {'chatSessionId': widget.chatSessionId, 'chatName': chatName, 'userId': userId, 'message': response.text, 'role': 'model'});
      if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final responseData = jsonDecode(apiResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
      }
    }
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatHistoryScreen(userId: userId)));
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      drawer: const NavDrawer(selectedIndex: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ListView.builder(controller: _scrollController, itemCount: _messages.length, itemBuilder: (context, index) => ChatBubble(message: _messages[index])),
                          if (!_isAtBottom)
                            Positioned(bottom: 10, left: 0, right: 0, child: Center(child: FloatingActionButton(onPressed: _scrollToBottom, child: const Icon(Icons.arrow_downward), mini: true))),
                        ],
                      ),
                    ),
                    _buildTextComposer(),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 1.0))),
      child: Row(
        children: [
          Flexible(child: TextField(controller: _textController, onSubmitted: _handleSubmitted, decoration: const InputDecoration.collapsed(hintText: 'Send a message'))),
          Container(margin: const EdgeInsets.symmetric(horizontal: 4.0), child: IconButton(icon: const Icon(Icons.send), onPressed: () => _handleSubmitted(_textController.text))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final String sender;

  ChatMessage({required this.text, required this.sender});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  void _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to copy: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == "user";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(10.0)),
                  child: SelectableText(message.text),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: IconButton(icon: const Icon(Icons.copy, size: 16), color: Theme.of(context).colorScheme.primary, onPressed: () => _copyToClipboard(context, message.text), tooltip: "Copy"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
