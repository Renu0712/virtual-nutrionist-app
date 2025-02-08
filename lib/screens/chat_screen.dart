// Suggested code may be subject to a license. Learn more: ~LicenseLog:332226529.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3939809719.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3750218317.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:4277078423.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:221042264.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3499119174.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3176197313.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2803987861.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:915738713.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2389520447.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:5098865.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2462201913.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3944710899.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3665087815.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1453192911.

import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hello!", sender: "user"),
    ChatMessage(text: "Hi there!", sender: "sender"),
    ChatMessage(text: "How are you?", sender: "user"),
    ChatMessage(text: "I'm good, thanks!", sender: "sender"),
  ];

  final TextEditingController _textController = TextEditingController();

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, sender: "user"));
    });
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: "Send a message",
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder:
                  (_, int index) => ChatBubble(message: _messages[index]),
              itemCount: _messages.length,
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == "user";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isUser) const CircleAvatar(child: Text("S")),
          Container(
            margin: const EdgeInsets.only(left: 16.0, right: 16.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: isUser ? Colors.white : Colors.black),
            ),
          ),
          if (isUser) const CircleAvatar(child: Text("U")),
        ],
      ),
    );
  }
}
