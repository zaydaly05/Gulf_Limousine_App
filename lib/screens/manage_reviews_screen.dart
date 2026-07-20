import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageReviewsScreen extends StatelessWidget {
  const ManageReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Fallback without orderBy if index missing
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
              builder: (context, snap2) {
                final docs = snap2.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No reviews yet',
                        style: TextStyle(color: Colors.white70)),
                  );
                }
                return _list(context, docs);
              },
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No reviews yet',
                  style: TextStyle(color: Colors.white70)),
            );
          }
          return _list(context, docs);
        },
      ),
    );
  }

  Widget _list(BuildContext context, List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final rating = (data['rating'] as num?)?.toInt() ?? 0;
        return Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              data['carName']?.toString() ?? 'Car',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${'★' * rating}${'☆' * (5 - rating)}\n'
              '${data['userName'] ?? 'User'}: ${data['comment'] ?? ''}',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await doc.reference.delete();
              },
            ),
          ),
        );
      },
    );
  }
}
