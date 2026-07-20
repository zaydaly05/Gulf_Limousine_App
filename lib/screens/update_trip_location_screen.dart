import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/geo_location.dart';
import '../services/booking_service.dart';
import 'map_location_picker.dart';

class UpdateTripLocationScreen extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const UpdateTripLocationScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  Future<void> _setLocation(BuildContext context, LatLng point) async {
    await BookingService.updateLiveLocation(
      bookingId: bookingId,
      lat: point.latitude,
      lng: point.longitude,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live location updated')),
    );
  }

  Future<void> _simulateTowardPickup(BuildContext context) async {
    final pickup = GeoLocation.tryParse(bookingData['pickupLocation']);
    final liveMap = bookingData['liveLocation'] is Map
        ? Map<String, dynamic>.from(bookingData['liveLocation'] as Map)
        : null;
    final live = LiveLocation.fromMap(liveMap);

    double lat;
    double lng;
    if (live.isValid) {
      final targetLat = pickup?.lat ?? 30.0444;
      final targetLng = pickup?.lng ?? 31.2357;
      lat = live.lat + (targetLat - live.lat) * 0.25;
      lng = live.lng + (targetLng - live.lng) * 0.25;
    } else if (pickup != null) {
      lat = pickup.lat - 0.02;
      lng = pickup.lng - 0.02;
    } else {
      lat = 30.03;
      lng = 31.22;
    }

    await BookingService.updateLiveLocation(
      bookingId: bookingId,
      lat: lat,
      lng: lng,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulated move toward pickup')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickup = GeoLocation.tryParse(bookingData['pickupLocation']);
    final initial = pickup != null
        ? LatLng(pickup.lat, pickup.lng)
        : const LatLng(30.0444, 31.2357);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Update Live Location'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>? ??
                    bookingData;
                final live = LiveLocation.fromMap(
                  data['liveLocation'] is Map
                      ? Map<String, dynamic>.from(data['liveLocation'] as Map)
                      : null,
                );
                final center =
                    live.isValid ? LatLng(live.lat, live.lng) : initial;

                return FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                    onTap: (_, point) => _setLocation(context, point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.g_l_t_final',
                    ),
                    MarkerLayer(
                      markers: [
                        if (live.isValid)
                          Marker(
                            point: LatLng(live.lat, live.lng),
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                        if (pickup != null)
                          Marker(
                            point: LatLng(pickup.lat, pickup.lng),
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.place,
                              color: Color(0xFFFF8C00),
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Tap the map to set the car location, or simulate movement.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final loc = await Navigator.push<GeoLocation>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MapLocationPicker(
                                  title: 'Set car location',
                                ),
                              ),
                            );
                            if (loc == null || !context.mounted) return;
                            await _setLocation(
                              context,
                              LatLng(loc.lat, loc.lng),
                            );
                          },
                          child: const Text('Pick on full map'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _simulateTowardPickup(context),
                          child: const Text('Simulate move'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
