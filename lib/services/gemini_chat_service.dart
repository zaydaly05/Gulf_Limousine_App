import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import 'chatbot_service.dart';

class GeminiChatService {
  GeminiChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ChatbotService? fallback,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _fallback = fallback ?? ChatbotService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ChatbotService _fallback;

  static const _model = 'gemini-2.0-flash';

  Future<ChatbotReply> generateReply(String input, {bool admin = false}) async {
    if (!ApiKeys.hasGeminiKey) {
      return _fallback.generateReply(input);
    }

    try {
      final context = admin
          ? await _buildAdminContext()
          : await _buildUserContext();

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=${ApiKeys.gemini}',
      );

      final system = admin
          ? 'You are the Gulf Limousine admin operations assistant. '
              'Be concise. Use the context for fleet and booking stats. '
              'If unsure, say so. Never invent revenue numbers not in context.'
          : 'You are Gulf Limousine Travel assistant for luxury car rentals in Cairo. '
              'Be helpful, concise, and professional. Use the live context below. '
              'You can explain bookings, payments (card, wallet, InstaPay, cash), '
              'pickup/drop-off maps, chauffeur tracking, and contact support. '
              'If something is missing from context, say so and suggest Browse Cars or Contact.';

      final body = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    '$system\n\nCONTEXT:\n$context\n\nUSER MESSAGE:\n$input\n\n'
                    'Reply in plain text. Suggest next steps briefly when useful.',
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 512,
        },
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return _fallback.generateReply(input);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return _fallback.generateReply(input);
      }
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      final text = parts?.first['text']?.toString().trim();
      if (text == null || text.isEmpty) {
        return _fallback.generateReply(input);
      }

      return ChatbotReply(
        text: text,
        suggestions: admin
            ? const ['Pending bookings', 'Fleet status', 'Revenue']
            : ChatbotService.welcomeSuggestions,
      );
    } catch (_) {
      return _fallback.generateReply(input);
    }
  }

  Future<String> _buildUserContext() async {
    final buffer = StringBuffer();
    final cars = await _firestore.collection('cars').limit(15).get();
    buffer.writeln('Available cars:');
    for (final doc in cars.docs) {
      final d = doc.data();
      if (d['available'] == false) continue;
      buffer.writeln(
        '- ${d['name']} (${d['brand']}) EGP ${d['price_per_day']}/day, '
        '${d['seats'] ?? '-'} seats',
      );
    }

    final user = _auth.currentUser;
    if (user != null) {
      buffer.writeln('\nUser: ${user.email}');
      try {
        final bookings = await _firestore
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .limit(5)
            .get();
        buffer.writeln('Recent bookings:');
        for (final doc in bookings.docs) {
          final d = doc.data();
          buffer.writeln(
            '- ${d['carName'] ?? d['car_name']}: ${d['status']} '
            'trip=${d['tripStatus'] ?? 'n/a'}',
          );
        }
      } catch (_) {}
    }

    buffer.writeln(
      '\nPayments: card, wallet, InstaPay, cash on pickup. '
      'Users can pick map locations and track chauffeurs after assignment.',
    );
    return buffer.toString();
  }

  Future<String> _buildAdminContext() async {
    final cars = await _firestore.collection('cars').get();
    final bookings = await _firestore.collection('bookings').get();
    final users = await _firestore.collection('users').get();
    final payments = await _firestore.collection('payments').get();

    double revenue = 0;
    for (final p in payments.docs) {
      final amount = p.data()['amount'];
      if (amount is num) revenue += amount.toDouble();
    }

    final pending = bookings.docs
        .where((b) => (b.data()['status'] ?? '') == 'pending')
        .length;
    final confirmed = bookings.docs
        .where((b) => (b.data()['status'] ?? '') == 'confirmed')
        .length;

    return 'Fleet cars: ${cars.docs.length}\n'
        'Users: ${users.docs.length}\n'
        'Bookings: ${bookings.docs.length} (pending $pending, confirmed $confirmed)\n'
        'Payments recorded: ${payments.docs.length}\n'
        'Revenue sum: EGP ${revenue.toStringAsFixed(0)}';
  }
}
