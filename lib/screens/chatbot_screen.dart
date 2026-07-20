import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../services/chatbot_service.dart';
import '../services/gemini_chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  final String? userName;
  final bool adminMode;

  const ChatbotScreen({super.key, this.userName, this.adminMode = false});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatbot = ChatbotService();
  final _gemini = GeminiChatService();

  bool _isTyping = false;
  bool _welcomeSent = false;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _ensureWelcomeMessage(List<ChatMessage> messages) async {
    final userId = _userId;
    if (userId == null || _welcomeSent || messages.isNotEmpty) return;

    _welcomeSent = true;
    final welcome = _chatbot.welcomeMessage(userName: widget.userName);
    await _chatbot.saveMessage(
      userId,
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: welcome.text,
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: welcome.suggestions,
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final userId = _userId;
    final trimmed = text.trim();
    if (userId == null || trimmed.isEmpty || _isTyping) return;

    _messageController.clear();

    await _chatbot.saveMessage(
      userId,
      ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_user',
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    setState(() => _isTyping = true);
    await _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 650));

    final reply = await _gemini.generateReply(
      trimmed,
      admin: widget.adminMode,
    );
    await _chatbot.saveMessage(
      userId,
      ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}_bot',
        text: reply.text,
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: reply.suggestions,
      ),
    );

    if (mounted) setState(() => _isTyping = false);
    await _scrollToBottom();
  }

  Future<void> _clearChat() async {
    final userId = _userId;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will remove your conversation history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _chatbot.clearHistory(userId);
    _welcomeSent = false;
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gulf Assistant')),
        body: const Center(child: Text('Please sign in to use the assistant.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gulf Assistant'),
            Text(
              'Luxury rental support',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatbot.watchMessages(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _ensureWelcomeMessage(messages);
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == messages.length) {
                      return const _TypingBubble();
                    }

                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      onSuggestionTap: _sendMessage,
                    );
                  },
                );
              },
            ),
          ),
          _ChatInput(
            controller: _messageController,
            enabled: !_isTyping,
            onSend: () => _sendMessage(_messageController.text),
            onSuggestionTap: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<String> onSuggestionTap;

  const _MessageBubble({
    required this.message,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final time = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFFF8C00),
                  child: Icon(Icons.smart_toy_outlined,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFFF8C00) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isUser ? 0 : 40,
              right: isUser ? 4 : 0,
            ),
            child: Text(
              time,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
          if (!isUser && message.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestions
                    .map(
                      (suggestion) => ActionChip(
                        label: Text(suggestion),
                        onPressed: () => onSuggestionTap(suggestion),
                        backgroundColor:
                            const Color(0xFFFF8C00).withValues(alpha: 0.12),
                        labelStyle: const TextStyle(
                          color: Color(0xFFFF8C00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFFF8C00),
            child:
                Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final ValueChanged<String> onSuggestionTap;

  const _ChatInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ChatbotService.welcomeSuggestions
                    .map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(suggestion),
                          onPressed:
                              enabled ? () => onSuggestionTap(suggestion) : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    textInputAction: TextInputAction.send,
                    onSubmitted: enabled ? (_) => onSend() : null,
                    decoration: InputDecoration(
                      hintText: 'Ask about cars, bookings, payments...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFF8C00),
                  child: IconButton(
                    onPressed: enabled ? onSend : null,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
