import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/geo_location.dart';
import '../services/booking_service.dart';
import '../services/km_billing_service.dart';
import '../services/maps_launcher.dart';
import '../widgets/admin_charts.dart';
import 'odometer_capture_screen.dart';
import 'review_booking_screen.dart';
import 'track_trip_screen.dart';

List<QueryDocumentSnapshot> _sortedDocs(List<QueryDocumentSnapshot> docs) {
  final sorted = List<QueryDocumentSnapshot>.from(docs);
  sorted.sort((a, b) {
    final aData = a.data() as Map<String, dynamic>;
    final bData = b.data() as Map<String, dynamic>;
    final aDate = aData['createdAt'];
    final bDate = bData['createdAt'];
    if (aDate is Timestamp && bDate is Timestamp) {
      return bDate.compareTo(aDate);
    }
    return 0;
  });
  return sorted;
}

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: BookingService.userBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _BookingsFallbackByEmail();
          }

          final docs = _sortedDocs(snapshot.data?.docs ?? []);
          if (docs.isEmpty) {
            return const _EmptyBookings();
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _BookingCard(bookingId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No bookings yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse our fleet and rent your first luxury car.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsFallbackByEmail extends StatelessWidget {
  const _BookingsFallbackByEmail();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: BookingService.userBookingsStreamByEmail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = _sortedDocs(snapshot.data?.docs ?? []);
        if (docs.isEmpty) {
          return const _EmptyBookings();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _BookingCard(bookingId: doc.id, data: data);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;

  const _BookingCard({required this.bookingId, required this.data});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await BookingService.cancelBooking(bookingId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString();
    final tripStatus = (data['tripStatus'] ?? '').toString();
    final carName = resolveBookingCar(data);
    final pickup = formatBookingDate(data['pickupDate'] ?? data['startDate']);
    final returnD = formatBookingDate(data['returnDate']);
    final total = data['total_amount'];
    final days = data['days'];
    final pickupLoc = GeoLocation.tryParse(data['pickupLocation']);
    final dropoffLoc = GeoLocation.tryParse(data['dropoffLocation']);
    final hasChauffeur = (data['chauffeurId'] ?? '').toString().isNotEmpty;
    final canCancel =
        status == 'pending' || status == 'confirmed';
    final canTrack = hasChauffeur &&
        status != 'cancelled' &&
        tripStatus != 'completed' &&
        tripStatus != 'cancelled';
    final canReview =
        status == 'completed' && data['reviewed'] != true;

    final odometer = data['odometer'];
    final kmAllowance = data['kmAllowance'];
    final startKm = odometer is Map ? odometer['startKm'] : null;
    final endKm = odometer is Map ? odometer['endKm'] : null;
    final hasStartKm = startKm != null;
    final hasEndKm = endKm != null;
    final canRecordStart = !hasStartKm &&
        status != 'cancelled' &&
        status != 'completed' &&
        (status == 'confirmed' || status == 'pending');
    final canRecordEnd = hasStartKm &&
        !hasEndKm &&
        status != 'cancelled';
    final finalAmount = data['final_amount'];
    final extraKmCharge = kmAllowance is Map
        ? (kmAllowance['extraKmChargeEgp'] as num?)?.toDouble()
        : null;
    final drivenKm =
        kmAllowance is Map ? (kmAllowance['drivenKm'] as num?)?.toInt() : null;
    final allowedKm =
        kmAllowance is Map ? (kmAllowance['allowedKm'] as num?)?.toInt() : null;
    final extraKm =
        kmAllowance is Map ? (kmAllowance['extraKm'] as num?)?.toInt() : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: Color(0xFFFF8C00)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    carName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pickup.isNotEmpty) _row(Icons.event, 'Pickup', pickup),
            if (returnD.isNotEmpty)
              _row(Icons.event_available, 'Return', returnD),
            if (days != null) _row(Icons.timelapse, 'Duration', '$days day(s)'),
            if (total != null)
              _row(
                Icons.payments_outlined,
                'Total',
                'EGP ${(total as num).toStringAsFixed(0)}',
              ),
            if (data['payment_method'] != null)
              _row(Icons.credit_card, 'Paid via',
                  data['payment_method'].toString()),
            if (pickupLoc != null)
              _row(Icons.place, 'From', pickupLoc.address),
            if (dropoffLoc != null)
              _row(Icons.flag, 'To', dropoffLoc.address),
            if (hasChauffeur) ...[
              _row(Icons.person, 'Chauffeur',
                  (data['chauffeurName'] ?? '').toString()),
              if ((data['chauffeurPhone'] ?? '').toString().isNotEmpty)
                _row(Icons.phone, 'Driver phone',
                    data['chauffeurPhone'].toString()),
            ],
            if (tripStatus.isNotEmpty)
              _row(Icons.route, 'Trip', tripStatus.replaceAll('_', ' ')),
            if (hasStartKm)
              _row(Icons.speed, 'Pickup km', startKm.toString()),
            if (hasEndKm) _row(Icons.speed, 'Return km', endKm.toString()),
            if (drivenKm != null && allowedKm != null)
              _row(
                Icons.straighten,
                'Distance',
                '$drivenKm km ($allowedKm km allowed)',
              ),
            if (extraKm != null && extraKm > 0)
              _row(
                Icons.add_road,
                'Extra km',
                '$extraKm km × ${KmBillingService.extraKmRateEgp.toStringAsFixed(0)} EGP',
              ),
            if (extraKmCharge != null && extraKmCharge > 0)
              _row(
                Icons.receipt_long,
                'Extra km charge',
                'EGP ${extraKmCharge.toStringAsFixed(0)}',
              ),
            if (finalAmount != null && hasEndKm)
              _row(
                Icons.payments,
                'Final total',
                'EGP ${(finalAmount as num).toStringAsFixed(0)}',
              ),
            if (extraKmCharge != null &&
                extraKmCharge > 0 &&
                data['extraKmPaymentStatus'] != null)
              _row(
                Icons.account_balance_wallet_outlined,
                'Extra km status',
                extraKmPaymentStatusLabel(data),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (pickupLoc != null)
                  OutlinedButton.icon(
                    onPressed: () => MapsLauncher.openDirections(
                      destination: pickupLoc,
                    ),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Directions'),
                  ),
                if (canTrack)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackTripScreen(
                            bookingId: bookingId,
                            bookingData: data,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Track trip'),
                  ),
                if (hasChauffeur &&
                    (data['chauffeurPhone'] ?? '').toString().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => MapsLauncher.callPhone(
                      data['chauffeurPhone'].toString(),
                    ),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                  ),
                if (canRecordStart)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OdometerCaptureScreen(
                            bookingId: bookingId,
                            bookingData: data,
                            mode: OdometerCaptureMode.start,
                          ),
                        ),
                      );
                      if (ok == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pickup km recorded'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Record pickup km'),
                  ),
                if (canRecordEnd)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OdometerCaptureScreen(
                            bookingId: bookingId,
                            bookingData: data,
                            mode: OdometerCaptureMode.end,
                          ),
                        ),
                      );
                      if (ok == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Return km recorded'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.camera_enhance, size: 18),
                    label: const Text('Record return km'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: () => _cancel(context),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 18, color: Colors.red),
                    label: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
                if (canReview)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewBookingScreen(
                            bookingId: bookingId,
                            bookingData: data,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('Rate'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
