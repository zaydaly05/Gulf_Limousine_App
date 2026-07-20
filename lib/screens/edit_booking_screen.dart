import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/geo_location.dart';
import '../widgets/extra_km_admin_panel.dart';
import 'map_location_picker.dart';
import 'update_trip_location_screen.dart';

class EditBookingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const EditBookingScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  String? selectedCarId;
  String selectedCarName = '';
  String selectedBrand = '';
  double pricePerDay = 0;
  String status = 'pending';
  String tripStatus = 'pending';
  String? chauffeurId;
  String chauffeurName = '';
  String chauffeurPhone = '';
  GeoLocation? pickupLocation;
  GeoLocation? dropoffLocation;

  DateTime? pickupDate;
  DateTime? returnDate;
  bool _isLoading = false;

  static const _statuses = [
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  ];

  static const _tripStatuses = [
    'pending',
    'assigned',
    'en_route',
    'arrived',
    'in_progress',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.bookingData;

    nameController = TextEditingController(
      text: (data['customerName'] ?? data['userName'] ?? '').toString(),
    );
    emailController = TextEditingController(
      text: (data['user_email'] ?? '').toString(),
    );
    phoneController = TextEditingController(
      text: (data['phone'] ?? data['phone_number'] ?? '').toString(),
    );

    selectedCarId = data['car_id']?.toString() ?? data['carId']?.toString();
    selectedCarName = (data['carName'] ?? data['car_name'] ?? '').toString();
    selectedBrand = (data['brand'] ?? '').toString();
    pricePerDay = (data['price_per_day'] as num?)?.toDouble() ?? 0;
    status = (data['status'] ?? 'pending').toString().toLowerCase();
    if (!_statuses.contains(status)) status = 'pending';
    tripStatus = (data['tripStatus'] ?? 'pending').toString().toLowerCase();
    if (!_tripStatuses.contains(tripStatus)) tripStatus = 'pending';

    chauffeurId = data['chauffeurId']?.toString();
    chauffeurName = (data['chauffeurName'] ?? '').toString();
    chauffeurPhone = (data['chauffeurPhone'] ?? '').toString();
    pickupLocation = GeoLocation.tryParse(data['pickupLocation']);
    dropoffLocation = GeoLocation.tryParse(data['dropoffLocation']);

    pickupDate = _parseDate(data['pickupDate'] ?? data['startDate']);
    returnDate = _parseDate(data['returnDate']);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  int get _days {
    if (pickupDate == null || returnDate == null) return 0;
    final diff = returnDate!.difference(pickupDate!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _total => pricePerDay * _days;

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

  Future<void> _updateBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCarName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a car'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (pickupDate == null || returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and return dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final previousTrip = (widget.bookingData['tripStatus'] ?? '').toString();
      final previousChauffeur =
          (widget.bookingData['chauffeurId'] ?? '').toString();

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'customerName': nameController.text.trim(),
        'userName': nameController.text.trim(),
        'user_email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        if (selectedCarId != null) 'car_id': selectedCarId,
        'car_name': selectedCarName,
        'carName': selectedCarName,
        'brand': selectedBrand,
        'pickupDate': Timestamp.fromDate(pickupDate!),
        'returnDate': Timestamp.fromDate(returnDate!),
        'startDate': Timestamp.fromDate(pickupDate!),
        'days': _days,
        'price_per_day': pricePerDay,
        'total_amount': _total,
        'status': status,
        'tripStatus': tripStatus,
        if (chauffeurId != null) 'chauffeurId': chauffeurId,
        'chauffeurName': chauffeurName,
        'chauffeurPhone': chauffeurPhone,
        if (pickupLocation != null) 'pickupLocation': pickupLocation!.toMap(),
        if (dropoffLocation != null)
          'dropoffLocation': dropoffLocation!.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userId = widget.bookingData['userId']?.toString();
      if (userId != null && userId.isNotEmpty) {
        if (chauffeurId != null &&
            chauffeurId!.isNotEmpty &&
            chauffeurId != previousChauffeur) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .add({
            'title': 'Chauffeur assigned',
            'body':
                '$chauffeurName will drive your trip. Track from My Bookings.',
            'type': 'chauffeur_assigned',
            'bookingId': widget.bookingId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else if (tripStatus != previousTrip) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .add({
            'title': 'Trip update',
            'body': 'Your trip is now ${tripStatus.replaceAll('_', ' ')}.',
            'type': 'trip_$tripStatus',
            'bookingId': widget.bookingId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final initial = isPickup
        ? (pickupDate ?? DateTime.now())
        : (returnDate ?? pickupDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: initial,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Booking'),
        backgroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            _field(nameController, 'Customer Name'),
            _field(
              emailController,
              'Email',
              type: TextInputType.emailAddress,
              required: false,
            ),
            _field(
              phoneController,
              'Phone',
              type: TextInputType.phone,
              required: false,
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cars').snapshots(),
              builder: (context, snapshot) {
                final cars = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: selectedCarId != null &&
                          cars.any((c) => c.id == selectedCarId)
                      ? selectedCarId
                      : null,
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Car'),
                  hint: Text(
                    selectedCarName.isNotEmpty ? selectedCarName : 'Select car',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  items: cars.map((doc) {
                    final car = doc.data() as Map<String, dynamic>;
                    final name = (car['name'] ?? 'Car').toString();
                    final brand = (car['brand'] ?? '').toString();
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text('$brand $name'.trim()),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final doc = cars.firstWhere((c) => c.id == id);
                    final car = doc.data() as Map<String, dynamic>;
                    setState(() {
                      selectedCarId = id;
                      selectedCarName = (car['name'] ?? 'Car').toString();
                      selectedBrand = (car['brand'] ?? '').toString();
                      pricePerDay =
                          (car['price_per_day'] as num?)?.toDouble() ?? 0;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: status,
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Status'),
              items: _statuses
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => status = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: tripStatus,
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration('Trip Status'),
              items: _tripStatuses
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.replaceAll('_', ' ').toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => tripStatus = v);
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chauffeurs')
                  .where('active', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final chauffeurs = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: chauffeurId != null &&
                          chauffeurs.any((c) => c.id == chauffeurId)
                      ? chauffeurId
                      : null,
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Chauffeur'),
                  hint: Text(
                    chauffeurName.isNotEmpty ? chauffeurName : 'Assign chauffeur',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('None'),
                    ),
                    ...chauffeurs.map((doc) {
                      final c = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text('${c['name']} · ${c['phone'] ?? ''}'),
                      );
                    }),
                  ],
                  onChanged: (id) {
                    if (id == null || id.isEmpty) {
                      setState(() {
                        chauffeurId = null;
                        chauffeurName = '';
                        chauffeurPhone = '';
                        if (tripStatus == 'assigned') tripStatus = 'pending';
                      });
                      return;
                    }
                    final doc = chauffeurs.firstWhere((c) => c.id == id);
                    final c = doc.data() as Map<String, dynamic>;
                    setState(() {
                      chauffeurId = id;
                      chauffeurName = (c['name'] ?? '').toString();
                      chauffeurPhone = (c['phone'] ?? '').toString();
                      if (tripStatus == 'pending') tripStatus = 'assigned';
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _locationButton(
              'Pickup Location',
              pickupLocation?.address,
              () => _pickLocation(isPickup: true),
            ),
            _locationButton(
              'Drop-off Location',
              dropoffLocation?.address,
              () => _pickLocation(isPickup: false),
            ),
            _dateButton(
              'Pickup Date',
              pickupDate,
              () => _pickDate(isPickup: true),
            ),
            _dateButton(
              'Return Date',
              returnDate,
              () => _pickDate(isPickup: false),
            ),
            if (_days > 0 && pricePerDay > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$_days day(s) × EGP ${pricePerDay.toStringAsFixed(0)} = EGP ${_total.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
            const SizedBox(height: 16),
            ExtraKmAdminPanel(
              bookingId: widget.bookingId,
              booking: widget.bookingData,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdateTripLocationScreen(
                      bookingId: widget.bookingId,
                      bookingData: {
                        ...widget.bookingData,
                        if (pickupLocation != null)
                          'pickupLocation': pickupLocation!.toMap(),
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.gps_fixed, color: Colors.orange),
              label: const Text(
                'Update live location',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: _isLoading ? null : _updateBooking,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Update Booking',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.orange),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: _decoration(label),
      ),
    );
  }

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade700),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.orange),
            const SizedBox(width: 10),
            Text(
              date == null
                  ? label
                  : '$label: ${DateFormat('dd MMM yyyy').format(date)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationButton(String label, String? address, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade700),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            const Icon(Icons.place, size: 18, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                address == null || address.isEmpty ? label : '$label: $address',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
