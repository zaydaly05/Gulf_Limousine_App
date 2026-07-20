import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';

class ChatbotReply {
  final String text;
  final List<String> suggestions;

  const ChatbotReply({
    required this.text,
    this.suggestions = const [],
  });
}

class ChatbotService {
  ChatbotService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const welcomeSuggestions = [
    'Show available cars',
    'My bookings',
    'Payment methods',
    'Contact support',
  ];

  CollectionReference<Map<String, dynamic>>? _messagesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages');
  }

  Stream<List<ChatMessage>> watchMessages(String userId) {
    return _messagesRef(userId)!
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChatMessage.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> saveMessage(String userId, ChatMessage message) async {
    await _messagesRef(userId)!.doc(message.id).set(message.toMap());
  }

  Future<void> clearHistory(String userId) async {
    final snapshot = await _messagesRef(userId)!.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  ChatbotReply welcomeMessage({String? userName}) {
    final name = userName?.trim();
    final greeting = name != null && name.isNotEmpty ? 'Hi $name!' : 'Hi there!';

    return ChatbotReply(
      text:
          '$greeting I am Gulf Limousine Assistant.\n\n'
          'I can help you browse cars, check your bookings, explain payments, '
          'and answer common questions about our luxury rental service.',
      suggestions: welcomeSuggestions,
    );
  }

  Future<ChatbotReply> generateReply(String input) async {
    final message = input.trim().toLowerCase();
    if (message.isEmpty) {
      return const ChatbotReply(
        text: 'Please type a message or tap one of the quick suggestions.',
        suggestions: welcomeSuggestions,
      );
    }

    if (_matches(message, ['hello', 'hi', 'hey', 'good morning', 'good evening'])) {
      return ChatbotReply(
        text: 'Hello! How can I help you with your Gulf Limousine experience today?',
        suggestions: welcomeSuggestions,
      );
    }

    if (_matches(message, ['car', 'cars', 'fleet', 'available', 'rent', 'vehicle'])) {
      return _availableCarsReply();
    }

    if (_matches(message, ['booking', 'bookings', 'reservation', 'my booking', 'rental'])) {
      return _bookingsReply();
    }

    if (_matches(message, ['payment', 'pay', 'wallet', 'card', 'cash', 'instapay', 'checkout'])) {
      return const ChatbotReply(
        text:
            'We support these payment options:\n'
            '• Credit / Debit Card\n'
            '• Digital Wallet\n'
            '• InstaPay\n'
            '• Cash on pickup\n\n'
            'Cash bookings stay pending until confirmed at pickup. '
            'Other methods confirm your booking immediately after payment.',
        suggestions: ['My bookings', 'Show available cars', 'Contact support'],
      );
    }

    if (_matches(message, ['price', 'cost', 'rate', 'how much', 'fee', 'pricing'])) {
      return _pricingReply();
    }

    if (_matches(message, ['cancel', 'cancellation', 'refund'])) {
      return const ChatbotReply(
        text:
            'To cancel or change a booking, open My Bookings from your dashboard '
            'or contact our support team as soon as possible.\n\n'
            'Refund eligibility depends on booking status and pickup time.',
        suggestions: ['My bookings', 'Contact support'],
      );
    }

    if (_matches(message, ['profile', 'account', 'password', 'email'])) {
      return const ChatbotReply(
        text:
            'You can update your name, phone, and profile photo from the Profile screen. '
            'Use Forgot Password on the login page if you need to reset your password.',
        suggestions: ['Contact support'],
      );
    }

    if (_matches(message, ['contact', 'phone', 'email', 'support', 'help', 'call'])) {
      return const ChatbotReply(
        text:
            'Need human support? Reach us at:\n'
            '• Phone: +20 100 111 6666\n'
            '• Email: info@gulflimousine.com\n'
            '• Location: Cairo, Egypt',
        suggestions: ['Show available cars', 'My bookings'],
      );
    }

    if (_matches(message, ['location', 'where', 'cairo', 'address', 'pickup'])) {
      return const ChatbotReply(
        text:
            'Gulf Limousine Travel is based in Cairo, Egypt.\n'
            'Pickup details are confirmed in your booking summary after you reserve a car.',
        suggestions: ['Show available cars', 'Contact support'],
      );
    }

    if (_matches(message, ['thank', 'thanks'])) {
      return const ChatbotReply(
        text: 'You are welcome! Let me know if you need anything else.',
        suggestions: welcomeSuggestions,
      );
    }

    return const ChatbotReply(
      text:
          'I am not sure I understood that yet. Try asking about available cars, '
          'your bookings, payment methods, or contact support.',
      suggestions: welcomeSuggestions,
    );
  }

  bool _matches(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  Future<ChatbotReply> _availableCarsReply() async {
    final snapshot = await _firestore.collection('cars').get();
    if (snapshot.docs.isEmpty) {
      return const ChatbotReply(
        text: 'No cars are listed in the fleet right now. Please check again soon.',
        suggestions: ['Contact support'],
      );
    }

    final available = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['available'] != false;
    }).toList();

    if (available.isEmpty) {
      return const ChatbotReply(
        text:
            'All cars are currently booked. New availability is updated regularly, '
            'so please check again later or contact support.',
        suggestions: ['Contact support', 'My bookings'],
      );
    }

    final buffer = StringBuffer(
      'We currently have ${available.length} available car(s):\n',
    );

    final preview = available.take(5);
    for (final doc in preview) {
      final data = doc.data();
      final name = data['name'] ?? data['car_name'] ?? 'Car';
      final brand = data['brand']?.toString();
      final price = data['price_per_day'] ?? data['price'];
      buffer.writeln(
        '• $name${brand != null && brand.isNotEmpty ? ' ($brand)' : ''}'
        '${price != null ? ' — EGP $price/day' : ''}',
      );
    }

    if (available.length > preview.length) {
      buffer.writeln('\nOpen Browse Cars to see the full fleet.');
    } else {
      buffer.writeln('\nOpen Browse Cars to reserve one.');
    }

    return ChatbotReply(
      text: buffer.toString().trim(),
      suggestions: const ['My bookings', 'Payment methods'],
    );
  }

  Future<ChatbotReply> _bookingsReply() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const ChatbotReply(
        text: 'Please sign in to view your bookings.',
        suggestions: welcomeSuggestions,
      );
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .get();
    } catch (_) {
      final email = user.email;
      if (email == null || email.isEmpty) {
        return const ChatbotReply(
          text: 'I could not load your bookings right now. Please try again.',
          suggestions: ['Contact support'],
        );
      }
      snapshot = await _firestore
          .collection('bookings')
          .where('user_email', isEqualTo: email)
          .get();
    }

    if (snapshot.docs.isEmpty) {
      return const ChatbotReply(
        text:
            'You do not have any bookings yet.\n'
            'Browse available cars and complete checkout to create your first rental.',
        suggestions: ['Show available cars', 'Payment methods'],
      );
    }

    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final aDate = a.data()['createdAt'];
        final bDate = b.data()['createdAt'];
        if (aDate is! Timestamp && bDate is! Timestamp) return 0;
        if (aDate is! Timestamp) return 1;
        if (bDate is! Timestamp) return -1;
        return bDate.compareTo(aDate);
      });

    final buffer = StringBuffer('Here are your latest bookings:\n');
    for (final doc in docs.take(5)) {
      final data = doc.data();
      final carName = data['car_name'] ?? data['carName'] ?? 'Car';
      final status = data['status'] ?? 'pending';
      buffer.writeln('• $carName — $status');
    }

    if (docs.length > 5) {
      buffer.writeln('\nOpen My Bookings for the full list.');
    }

    return ChatbotReply(
      text: buffer.toString().trim(),
      suggestions: const ['Show available cars', 'Payment methods', 'Contact support'],
    );
  }

  Future<ChatbotReply> _pricingReply() async {
    final snapshot = await _firestore
        .collection('cars')
        .where('available', isEqualTo: true)
        .limit(10)
        .get();

    if (snapshot.docs.isEmpty) {
      return const ChatbotReply(
        text:
            'Pricing depends on the car model and rental duration. '
            'Open Browse Cars to see current daily rates.',
        suggestions: ['Show available cars', 'Contact support'],
      );
    }

    double? minPrice;
    double? maxPrice;
    for (final doc in snapshot.docs) {
      final price = doc.data()['price_per_day'] ?? doc.data()['price'];
      if (price is! num) continue;
      final value = price.toDouble();
      minPrice = minPrice == null ? value : (value < minPrice ? value : minPrice);
      maxPrice = maxPrice == null ? value : (value > maxPrice ? value : maxPrice);
    }

    if (minPrice == null || maxPrice == null) {
      return const ChatbotReply(
        text:
            'Rates vary by vehicle. Browse Cars shows the exact daily price before checkout.',
        suggestions: ['Show available cars'],
      );
    }

    final range = minPrice == maxPrice
        ? 'EGP ${minPrice.toStringAsFixed(0)} per day'
        : 'EGP ${minPrice.toStringAsFixed(0)} – ${maxPrice.toStringAsFixed(0)} per day';

    return ChatbotReply(
      text:
          'Current available cars are priced around $range.\n'
          'Your final total also depends on rental days and selected dates.',
      suggestions: const ['Show available cars', 'Payment methods'],
    );
  }
}
