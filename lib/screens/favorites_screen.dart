import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/rent_bottom_sheet.dart';

class FavoritesService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>? get _ref {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  static Stream<Set<String>> watchFavoriteIds() {
    final ref = _ref;
    if (ref == null) return Stream.value({});
    return ref.snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }

  static Future<void> toggle(String carId, Map<String, dynamic> car) async {
    final ref = _ref;
    if (ref == null) return;
    final doc = ref.doc(carId);
    final exists = await doc.get();
    if (exists.exists) {
      await doc.delete();
    } else {
      await doc.set({
        'carId': carId,
        'name': car['name'],
        'brand': car['brand'],
        'image_url': car['imageUrl'] ?? car['image_url'],
        'price_per_day': car['pricePerDay'] ?? car['price_per_day'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<bool> isFavorite(String carId) async {
    final ref = _ref;
    if (ref == null) return false;
    return (await ref.doc(carId).get()).exists;
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FavoritesService._ref?.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No favorites yet. Tap the heart on a car.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final carId = docs[index].id;
              final price = (data['price_per_day'] as num?)?.toDouble() ?? 0;
              final car = {
                'id': carId,
                'name': data['name']?.toString() ?? 'Car',
                'brand': data['brand']?.toString() ?? '',
                'pricePerDay': price,
                'imageUrl': data['image_url'],
                'available': true,
              };
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: data['image_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['image_url'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.directions_car),
                          ),
                        )
                      : const Icon(Icons.directions_car),
                  title: Text(car['name'] as String),
                  subtitle: Text(
                    '${car['brand']} · EGP ${price.toStringAsFixed(0)}/day',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => FavoritesService.toggle(carId, car),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => RentBottomSheet(car: car),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
