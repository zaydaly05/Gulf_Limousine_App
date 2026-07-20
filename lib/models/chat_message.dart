import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestions;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'createdAt': Timestamp.fromDate(timestamp),
      if (suggestions.isNotEmpty) 'suggestions': suggestions,
    };
  }

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      text: data['text']?.toString() ?? '',
      isUser: data['isUser'] == true,
      timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      suggestions: (data['suggestions'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }
}
