import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/geo_location.dart';
import '../screens/map_location_picker.dart';
import '../screens/payment_screen.dart';
import '../services/booking_service.dart';
import 'expandable_address_row.dart';

class RentBottomSheet extends StatefulWidget {
  final Map<String, dynamic> car;

  const RentBottomSheet({super.key, required this.car});

  @override
  State<RentBottomSheet> createState() => _RentBottomSheetState();
}

class _RentBottomSheetState extends State<RentBottomSheet> {
  DateTime? pickupDate;
  DateTime? returnDate;
  GeoLocation? pickupLocation;
  GeoLocation? dropoffLocation;

  double get _pricePerDay =>
      (widget.car['pricePerDay'] as num?)?.toDouble() ?? 0;

  int get _days {
    if (pickupDate == null || returnDate == null) return 0;
    return returnDate!.difference(pickupDate!).inDays + 1;
  }

  double get _total => _pricePerDay * _days;

  Future<void> _pickDate(bool isPickup) async {
    final now = DateTime.now();
    final initial = isPickup
        ? (pickupDate ?? now)
        : (returnDate ??
            pickupDate?.add(const Duration(days: 1)) ??
            now.add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isPickup) {
        pickupDate = picked;
        if (returnDate != null && returnDate!.isBefore(picked)) {
          returnDate = picked.add(const Duration(days: 1));
        }
      } else {
        returnDate = picked;
      }
    });
  }

  Future<void> _pickLocation({required bool isPickup}) async {
    final result = await Navigator.push<GeoLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          title: isPickup ? 'Pickup Location' : 'Drop-off Location',
          initial: isPickup ? pickupLocation : dropoffLocation,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (isPickup) {
        pickupLocation = result;
      } else {
        dropoffLocation = result;
      }
    });
  }

  void _proceedToPayment() {
    if (pickupDate == null || returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and return dates')),
      );
      return;
    }
    if (returnDate!.isBefore(pickupDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return date must be after pickup date')),
      );
      return;
    }
    if (_days < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rental must be at least 1 day')),
      );
      return;
    }
    if (pickupLocation == null || dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and drop-off locations'),
        ),
      );
      return;
    }

    final rental = RentalDetails(
      carId: widget.car['id'] as String,
      carName: widget.car['name'] as String,
      brand: widget.car['brand'] as String? ?? '',
      pricePerDay: _pricePerDay,
      pickupDate: pickupDate!,
      returnDate: returnDate!,
      days: _days,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
    );

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(rental: rental)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.car['name']?.toString() ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.car['brand'] ?? ''} · EGP $_pricePerDay / day',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            _DateRow(
              label: 'Pickup Date',
              value:
                  pickupDate != null ? dateFmt.format(pickupDate!) : 'Select date',
              onTap: () => _pickDate(true),
            ),
            const SizedBox(height: 12),
            _DateRow(
              label: 'Return Date',
              value:
                  returnDate != null ? dateFmt.format(returnDate!) : 'Select date',
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 12),
            _LocationRow(
              icon: Icons.place,
              label: 'Pickup Location',
              address: pickupLocation?.address ?? 'Select on map',
              onTap: () => _pickLocation(isPickup: true),
            ),
            const SizedBox(height: 12),
            _LocationRow(
              icon: Icons.flag,
              label: 'Drop-off Location',
              address: dropoffLocation?.address ?? 'Select on map',
              iconColor: Colors.blue,
              onTap: () => _pickLocation(isPickup: false),
            ),
            if (_days > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_days day(s) × EGP $_pricePerDay'),
                    Text(
                      'EGP ${_total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFFF8C00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedToPayment,
                child: const Text('Continue to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: const Color(0xFFFF8C00), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String label;
  final String address;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;

  const _LocationRow({
    required this.label,
    required this.address,
    required this.onTap,
    this.icon = Icons.place,
    this.iconColor = const Color(0xFFFF8C00),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  ExpandableAddressText(text: address),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
