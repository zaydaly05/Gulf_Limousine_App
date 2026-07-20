import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_charts.dart';
import '../widgets/extra_km_admin_panel.dart';
import 'edit_booking_screen.dart';
import 'new_booking_screen.dart';

class ManageBookingsScreen extends StatelessWidget {
  const ManageBookingsScreen({super.key});

  Future<void> _deleteBooking(BuildContext context, String id) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Delete Booking',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this booking?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(id)
                  .delete();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewBookingScreen()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading bookings',
                style: TextStyle(color: Colors.red.shade300),
              ),
            );
          }

          final docs = _sortedDocs(snapshot.data?.docs ?? []);
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No bookings found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 80 + bottomPad),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final booking = doc.data() as Map<String, dynamic>;
              final status = (booking['status'] ?? 'pending').toString();
              final carName = resolveBookingCar(booking);
              final customer = resolveBookingName(booking);
              final email = booking['user_email']?.toString() ?? '';
              final pickup = formatBookingDate(
                booking['pickupDate'] ?? booking['startDate'],
              );
              final returnDate = formatBookingDate(booking['returnDate']);
              final total = booking['total_amount'];
              final finalAmount = booking['final_amount'];
              final hasExtraKm = bookingHasExtraKmCharge(booking);

              return Card(
                color: Colors.grey.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              carName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status)
                                  .withValues(alpha: 0.2),
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
                      const SizedBox(height: 10),
                      Text(
                        'Customer: $customer',
                        style: TextStyle(color: Colors.grey.shade300),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          'Email: $email',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      if (pickup.isNotEmpty)
                        Text(
                          'Pickup: $pickup',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      if (returnDate.isNotEmpty)
                        Text(
                          'Return: $returnDate',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      if (booking['pickupLocation'] is Map &&
                          (booking['pickupLocation']['address'] ?? '')
                              .toString()
                              .isNotEmpty)
                        Text(
                          'From: ${booking['pickupLocation']['address']}',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      if (booking['dropoffLocation'] is Map &&
                          (booking['dropoffLocation']['address'] ?? '')
                              .toString()
                              .isNotEmpty)
                        Text(
                          'To: ${booking['dropoffLocation']['address']}',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      if ((booking['chauffeurName'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text(
                          'Chauffeur: ${booking['chauffeurName']}',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      if ((booking['tripStatus'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text(
                          'Trip: ${booking['tripStatus']}',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      if (total != null)
                        Text(
                          'Base rental: EGP ${(total as num).toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      if (finalAmount != null &&
                          finalAmount != total &&
                          booking['odometer'] is Map &&
                          (booking['odometer'] as Map)['endKm'] != null)
                        Text(
                          'Final total: EGP ${(finalAmount as num).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (hasExtraKm) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Extra km: ',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: extraKmPaymentStatusColor(booking)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                extraKmPaymentStatusLabel(booking).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: extraKmPaymentStatusColor(booking),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      ExtraKmAdminPanel(
                        bookingId: doc.id,
                        booking: booking,
                        compact: true,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditBookingScreen(
                                    bookingId: doc.id,
                                    bookingData: booking,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBooking(context, doc.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
