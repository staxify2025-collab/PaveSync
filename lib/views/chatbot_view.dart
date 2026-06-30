import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({super.key});

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text': 'Hello! I am PaveQuery, your compliance advisor. Ask me anything about FHWA, AASHTO, PASER, ALDOT, or FDOT guidelines.'
    }
  ];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    'FDOT Crack Rating Formula',
    'FDOT Rutting Score Rules',
    'AASHTO PCI standard info',
    'FHWA Shoulder Drop-off Risk',
    'MUTCD retroreflectivity standards'
  ];

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final response = await ChatbotService.sendMessage(text);

    setState(() {
      _messages.add({'sender': 'bot', 'text': response});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      width: isMobile ? double.infinity : 360,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(
          left: BorderSide(color: Colors.black12, width: isMobile ? 0 : 1),
        ),
      ),
      child: Column(
        children: [
          // Gradient Chatbot Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEAECF0), Color(0xFFFAFAFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PaveQuery Compliance AI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF101828),
                      ),
                    ),
                    Text(
                      'FHWA, AASHTO, ALDOT & FDOT Advisor',
                      style: TextStyle(fontSize: 11, color: Color(0xFF475467)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Chat Messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isBot = msg['sender'] == 'bot';
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isBot ? const Color(0xFFEAECF0) : Colors.amber.withOpacity(0.25),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isBot ? Radius.zero : const Radius.circular(12),
                        bottomRight: isBot ? const Radius.circular(12) : Radius.zero,
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(
                        color: Color(0xFF1D2939),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
              ),
            ),

          // Suggestion Chips list
          if (_messages.length == 1)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(_suggestions[index]),
                      backgroundColor: const Color(0xFFEAECF0),
                      labelStyle: TextStyle(color: Colors.amber[800], fontSize: 11),
                      onPressed: () => _sendMessage(_suggestions[index]),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),

          // Bottom Input bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFF101828), fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ask about ALDOT/FDOT specs...',
                      hintStyle: const TextStyle(color: Color(0xFF475467), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFEAECF0),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: () => _sendMessage(_controller.text),
                  backgroundColor: Colors.amber,
                  child: const Icon(Icons.send, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
