import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'nutritions_list_screen.dart';

class NutritionChatScreen extends StatefulWidget {
  const NutritionChatScreen({super.key});

  @override
  State<NutritionChatScreen> createState() => _NutritionChatScreenState();
}

class _NutritionChatScreenState extends State<NutritionChatScreen> {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  bool _isLoading = false;
  bool _isAtBottom = true; // Tracks if user is at the bottom
  Timer? _scrollDebounceTimer;

  late final GenerativeModel model;
  late final String userId;
  late String chatName;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _checkLogin();

    _scrollController.addListener(() {
      if (_scrollDebounceTimer?.isActive ?? false) {
        _scrollDebounceTimer!.cancel();
      }
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        final atBottom =
            _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 10;
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
        generationConfig: GenerationConfig(
          temperature: 1,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'application/json',
          responseSchema: Schema(
            SchemaType.object,
            requiredProperties: ["nutrition", "response", "is_nutrition"],
            properties: {
              "nutrition": Schema(
                SchemaType.object,
                requiredProperties: ["title", "nutrition entry"],
                properties: {
                  "title": Schema(SchemaType.string),
                  "nutrition entry": Schema(SchemaType.string),
                },
              ),
              "response": Schema(SchemaType.string),
              "is_nutrition": Schema(SchemaType.boolean),
            },
          ),
        ),
        systemInstruction: Content.system(
          '"You are an expert nutritionist AI, designed to create personalized nutrition plans. Your primary goal is to gather information from the user to tailor a diet plan that aligns with their health goals and current health status. You will ONLY respond in the following JSON format:\\n\\n```json\\n{\\n  \\"type\\": \\"object\\",\\n  \\"properties\\": {\\n    \\"nutrition\\": {\\n      \\"type\\": \\"object\\",\\n      \\"properties\\": {\\n        \\"title\\": {\\n          \\"type\\": \\"string\\",\\n          \\"description\\": \\"Title of the nutrition entry (e.g., Breakfast, Lunch, Snack).\\"\\n        },\\n        \\"nutrition entry\\": {\\n          \\"type\\": \\"string\\",\\n          \\"description\\": \\"Detailed description of the meal or dietary recommendation, including food items, quantities, and preparation instructions.  This includes details such as:\\n            - Serving size (e.g., 1 cup, 1 medium apple)\\n            - Food items and ingredients (e.g., 1 cup oatmeal with berries, 1 tbsp almond butter)\\n            - Preparation methods (e.g., baked, grilled, steamed)\\n            - Any specific nutritional information (e.g., approx. 300 calories, high in fiber)\\"\\n        }\\n      },\\n      \\"required\\": [\\n        \\"title\\",\\n        \\"nutrition entry\\"\\n      ]\\n    },\\n    \\"response\\": {\\n      \\"type\\": \\"string\\",\\n      \\"description\\": \\"Your response to the user, guiding the conversation and providing helpful information. This is the human-readable part. It can include questions, explanations, and feedback to the user.\\"\\n    },\\n    \\"is_nutrition\\": {\\n      \\"type\\": \\"boolean\\",\\n      \\"description\\": \\"Indicates whether the response includes nutrition plan data.  Set to \'true\' when providing a nutrition plan entry and \'false\' for general conversation or gathering information.\\"\\n    }\\n  },\\n  \\"required\\": [\\n    \\"nutrition\\",\\n    \\"response\\",\\n    \\"is_nutrition\\"\\n  ]\\n}\\n```\\n\\nHere\'s how the conversation will work:\\n\\n1.  **Initial Information Gathering:** Start by asking the user about their health goals (e.g., weight loss, muscle gain, improved energy), current health conditions, allergies, dietary restrictions, and activity level. Ask specific questions to gather detailed information. Break down your questions for better understanding\\n\\n2.  **Diet Plan Creation:** Based on the information provided, you will generate a personalized diet plan.  The diet plan should be comprehensive and include:\\n    *   Specific meal suggestions with detailed instructions.\\n    *   Estimated grocery list.\\n    *   Approximate cost of the groceries.\\n    *   Estimated cooking time.\\n\\n3.  **Ongoing Support:** After providing the initial plan, offer the user the option to make adjustments or ask further questions. Adapt the plan as needed based on the user\'s feedback.\\n\\n4.  **Focus:** Stick strictly to the nutrition plan creation process. If the user asks unrelated questions, politely redirect them back to the topic of creating their nutrition plan.\\n\\n5.  **Clarity and Detail:** Provide very clear and detailed information in your responses.  Use specific food items and quantities. Avoid vague language. Clearly mention the nutritional information along with the food items whenever possible.\\n\\n6.  **Cost and Time Estimates:** Provide realistic, and *approximate* cost and cooking time estimations. These can be ranges (e.g., \\"Cooking time: 20-30 minutes\\") or based on an average (e.g., \\"Grocery Cost: \$50-\\\$75 per week\\").\\n\\n7.  **Grocery List Specificity:**  The grocery list should be precise, including the specific items needed for the plan, and the approximate quantities.\\n\\n8. **Examples to guide responses**\\n\\n**Initial Information Gathering Example**\\n\\n```json\\n{\\n \\"nutrition\\": {\\n    \\"title\\": \\"\\",\\n    \\"nutrition entry\\": \\"\\"\\n  },\\n  \\"response\\": \\"Hello! I\'m here to help you create a personalized nutrition plan. To get started, could you please tell me about your main health goals? Are you aiming to lose weight, gain muscle, improve your energy levels, or something else? Also, do you have any allergies or dietary restrictions?\\",\\n  \\"is_nutrition\\": false\\n}\\n```\\n\\n**Example of a nutrition plan entry (Breakfast)**\\n\\n```json\\n{\\n  \\"nutrition\\": {\\n    \\"title\\": \\"Breakfast\\",\\n    \\"nutrition entry\\": \\"**Oatmeal with Berries and Almond Butter:** 1/2 cup rolled oats, cooked with 1 cup water or unsweetened almond milk. Add 1/2 cup mixed berries (strawberries, blueberries, raspberries) and 1 tablespoon of almond butter. Approx. 350 calories, high in fiber.\\"\\n  },\\n  \\"response\\": \\"Here\'s a suggestion for breakfast. What do you think? Do you have any changes you\'d like to make to this?\\",\\n  \\"is_nutrition\\": true\\n}\\n```\\n\\n**Example of a grocery list part**\\n\\n```json\\n{\\n  \\"nutrition\\": {\\n    \\"title\\": \\"Grocery List\\",\\n    \\"nutrition entry\\": \\"* Rolled Oats (1 bag)\\n* Mixed Berries (1 container)\\n* Almond Butter (1 jar)\\"\\n  },\\n  \\"response\\": \\"Here\'s a part of grocery list for the above nutrition entry. What do you think?\\",\\n  \\"is_nutrition\\": true\\n}\\n```\\n\\n**Example of a cost and cooking time estimation**\\n\\n```json\\n{\\n  \\"nutrition\\": {\\n    \\"title\\": \\"\\",\\n    \\"nutrition entry\\": \\"\\"\\n  },\\n  \\"response\\": \\"Cooking time: 10-15 minutes. Grocery Cost: Approximately \$10-\$15\\",\\n  \\"is_nutrition\\": true\\n}\\n```\\n"',
        ),
      );
    } else {
      log('GEMINI_API_KEY is not set in .env');
    }
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  Future<void> _saveNutritionEntry(
    String title, 
    String nutritionEntry,
  ) async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.post('nutrition', {
      'userId': userId,
      'title': title,
      'nutrition_entry': nutritionEntry,
    });
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const NutritionListScreen()),
        (Route<dynamic> route) => false, // This removes all previous routes
      );
    } else {
      final responseData = jsonDecode(apiResponse.body);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
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
      _isLoading = true;
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    final chat = model.startChat(
      history:
          _messages.map((m) => Content(m.sender, [TextPart(m.text)])).toList(),
    );
    final content = Content.text(text);
    final response = await chat.sendMessage(content);

    if (response.text != null) {
      print(response.text);
      final Map<String, dynamic> data = jsonDecode(response.text!);

      // Check the 'is_nutrition' field.
      if (data['is_nutrition'] == true) {
        // Parse the nutrition object.
        final Map<String, dynamic> nutrition = data['nutrition'];
        final String nutritionEntry = nutrition['nutrition entry'];
        final String title = nutrition['title'];

        // Display the parsed nutrition fields along with the response.
        if (kDebugMode) {
          print('Nutrition Entry: $nutritionEntry');
          print('Title: $title');
          print('Response: ${data['response']}');
        }

        final modelMessage =
            '${data['response']}\n\nNutrition Plan: \n\n Title: $title\n Nutrition Plan: $nutritionEntry';
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(text: modelMessage, sender: "model"));
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Add Nutrition Plan'),
              content: SingleChildScrollView(child: Text(modelMessage)),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    _saveNutritionEntry(title, nutritionEntry);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Only display the response.
        if (kDebugMode) {
          print('Response: ${data['response']}');
        }
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(text: data['response'], sender: "model"));
        });
      }
    }

    setState(() {});
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

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
      appBar: AppBar(title: const Text('Nutrition Planning Chat')),
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
                          ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder:
                                (context, index) =>
                                    ChatBubble(message: _messages[index]),
                          ),
                          if (!_isAtBottom)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: FloatingActionButton(
                                  onPressed: _scrollToBottom,
                                  mini: true,
                                  child: const Icon(Icons.arrow_downward),
                                ),
                              ),
                            ),
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
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
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
  const ChatBubble({super.key, required this.message});

  void _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to copy: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == "user";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color:
                        isUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SelectableText(message.text),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => _copyToClipboard(context, message.text),
                  tooltip: "Copy",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}