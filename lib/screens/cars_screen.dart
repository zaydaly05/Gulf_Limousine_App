import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/rent_bottom_sheet.dart';
import 'favorites_screen.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  String selectedBrand = 'All';
  String searchQuery = '';
  Set<String> _favoriteIds = {};

  final CollectionReference _carsRef =
      FirebaseFirestore.instance.collection('cars');

  @override
  void initState() {
    super.initState();
    FavoritesService.watchFavoriteIds().listen((ids) {
      if (mounted) setState(() => _favoriteIds = ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Cars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or brand...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _carsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final brands = <String>{'All'};
                for (final doc in snapshot.data!.docs) {
                  final brand =
                      (doc.data() as Map<String, dynamic>)['brand']?.toString();
                  if (brand != null && brand.isNotEmpty) brands.add(brand);
                }

                return SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: brands.map((brand) {
                      final selected = selectedBrand == brand;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(brand),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => selectedBrand = brand),
                          selectedColor:
                              const Color(0xFFFF8C00).withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _carsRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No cars available'));
                  }

                  final cars = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final price = (data['price_per_day'] ?? 0).toDouble();
                    return {
                      'id': doc.id,
                      'name': (data['name'] ?? '').toString(),
                      'brand': (data['brand'] ?? '').toString(),
                      'fuel_type': (data['fuel_type'] ?? '').toString(),
                      'seats': data['seats'],
                      'pricePerDay': price,
                      'price': 'EGP ${price.toStringAsFixed(0)} / day',
                      'imageUrl': data['image_url'],
                      'available': data['available'] != false,
                      'avgRating': data['avgRating'],
                      'reviewCount': data['reviewCount'],
                    };
                  }).toList();

                  final filtered = cars.where((car) {
                    if (car['available'] != true) return false;
                    final name = car['name'].toString().toLowerCase();
                    final brand = car['brand'].toString().toLowerCase();
                    final matchesBrand =
                        selectedBrand == 'All' || car['brand'] == selectedBrand;
                    final q = searchQuery.toLowerCase();
                    final matchesSearch =
                        q.isEmpty || name.contains(q) || brand.contains(q);
                    return matchesBrand && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No cars match your search'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final car = filtered[index];
                      final id = car['id'] as String;
                      final isFav = _favoriteIds.contains(id);
                      final avg = (car['avgRating'] as num?)?.toDouble();
                      final count = (car['reviewCount'] as num?)?.toInt() ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: car['imageUrl'] != null &&
                                          car['imageUrl'].toString().isNotEmpty
                                      ? Image.network(
                                          car['imageUrl'],
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _imageFallback(),
                                        )
                                      : _imageFallback(),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      icon: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          FavoritesService.toggle(id, car),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          car['name'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${car['brand']} · ${car['fuel_type']} · ${car['seats'] ?? '-'} seats',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (avg != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '★ ${avg.toStringAsFixed(1)} ($count)',
                                            style: const TextStyle(
                                              color: Color(0xFFFF8C00),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          car['price'] as String,
                                          style: const TextStyle(
                                            color: Color(0xFFFF8C00),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        builder: (_) =>
                                            RentBottomSheet(car: car),
                                      );
                                    },
                                    child: const Text('Rent'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: const Icon(Icons.directions_car, size: 80, color: Colors.grey),
    );
  }
}
