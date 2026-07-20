import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/geo_location.dart';
import '../services/maps_launcher.dart';

class TrackTripScreen extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const TrackTripScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = GeoLocation.tryParse(bookingData['pickupLocation']);
    final dropoff = GeoLocation.tryParse(bookingData['dropoffLocation']);
    final chauffeurName =
        (bookingData['chauffeurName'] ?? 'Chauffeur').toString();
    final chauffeurPhone = (bookingData['chauffeurPhone'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Track Trip')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          final data =
              snapshot.data?.data() as Map<String, dynamic>? ?? bookingData;
          final live = LiveLocation.fromMap(
            data['liveLocation'] is Map
                ? Map<String, dynamic>.from(data['liveLocation'] as Map)
                : null,
          );
          final tripStatus = (data['tripStatus'] ?? 'assigned').toString();

          final LatLng center;
          if (live.isValid) {
            center = LatLng(live.lat, live.lng);
          } else if (pickup != null) {
            center = LatLng(pickup.lat, pickup.lng);
          } else {
            center = const LatLng(30.0444, 31.2357);
          }

          final markers = <Marker>[
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
            if (dropoff != null)
              Marker(
                point: LatLng(dropoff.lat, dropoff.lng),
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.flag,
                  color: Colors.blue,
                  size: 36,
                ),
              ),
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
          ];

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.g_l_t_final',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Status: ${tripStatus.replaceAll('_', ' ').toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Chauffeur: $chauffeurName'),
                      if (!live.isValid)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Live location will appear once your chauffeur starts the trip.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (chauffeurPhone.isNotEmpty)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    MapsLauncher.callPhone(chauffeurPhone),
                                icon: const Icon(Icons.call),
                                label: const Text('Call'),
                              ),
                            ),
                          if (chauffeurPhone.isNotEmpty && pickup != null)
                            const SizedBox(width: 8),
                          if (pickup != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => MapsLauncher.openDirections(
                                  destination: pickup,
                                ),
                                icon: const Icon(Icons.directions),
                                label: const Text('Pickup'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
