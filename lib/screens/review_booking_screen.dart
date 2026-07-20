import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewBookingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const ReviewBookingScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final carId = (widget.bookingData['car_id'] ??
              widget.bookingData['carId'] ??
              '')
          .toString();
      final carName = (widget.bookingData['carName'] ??
              widget.bookingData['car_name'] ??
              'Car')
          .toString();

      await FirebaseFirestore.instance.collection('reviews').add({
        'bookingId': widget.bookingId,
        'carId': carId,
        'carName': carName,
        'rating': _rating,
        'comment': _comment.text.trim(),
        'userId': widget.bookingData['userId'],
        'userName': widget.bookingData['userName'] ??
            widget.bookingData['customerName'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'reviewed': true, 'rating': _rating});

      if (carId.isNotEmpty) {
        final reviews = await FirebaseFirestore.instance
            .collection('reviews')
            .where('carId', isEqualTo: carId)
            .get();
        double sum = 0;
        for (final doc in reviews.docs) {
          sum += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
        }
        final avg = reviews.docs.isEmpty ? _rating.toDouble() : sum / reviews.docs.length;
        await FirebaseFirestore.instance.collection('cars').doc(carId).set({
          'avgRating': avg,
          'reviewCount': reviews.docs.length,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your review!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = (widget.bookingData['carName'] ??
            widget.bookingData['car_name'] ??
            'Car')
        .toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Rate your trip')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              car,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('How was your experience?'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFF8C00),
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
