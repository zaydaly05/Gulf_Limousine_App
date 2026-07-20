import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();

  String? selectedCarId;
  String selectedCarName = '';
  String selectedBrand = '';
  double pricePerDay = 0;
  String status = 'pending';

  DateTime? pickupDate;
  DateTime? returnDate;
  bool _isLoading = false;

  static const _statuses = [
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  ];

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  int get _days {
    if (pickupDate == null || returnDate == null) return 0;
    final diff = returnDate!.difference(pickupDate!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _total => pricePerDay * _days;

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCarId == null || selectedCarName.isEmpty) {
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

    if (returnDate!.isBefore(pickupDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return date must be after pickup date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance.collection('bookings').add({
        'customerName': name.text.trim(),
        'userName': name.text.trim(),
        'user_email': email.text.trim(),
        'phone': phone.text.trim(),
        'car_id': selectedCarId,
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
        'payment_method': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created successfully'),
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
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2035),
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
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
        backgroundColor: Colors.black,
        title: const Text('New Booking'),
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
            _field(name, 'Customer Name'),
            _field(
              email,
              'Email',
              type: TextInputType.emailAddress,
              required: false,
            ),
            _field(
              phone,
              'Phone Number',
              type: TextInputType.phone,
              required: false,
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cars').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final cars = snapshot.data?.docs ?? [];
                if (cars.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'No cars available. Add a car first.',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  initialValue: selectedCarId,
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Car'),
                  hint: const Text(
                    'Select car',
                    style: TextStyle(color: Colors.white70),
                  ),
                  items: cars.map((doc) {
                    final car = doc.data() as Map<String, dynamic>;
                    final carName = (car['name'] ?? 'Car').toString();
                    final brand = (car['brand'] ?? '').toString();
                    final price =
                        (car['price_per_day'] as num?)?.toDouble() ?? 0;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                        '$brand $carName · EGP ${price.toStringAsFixed(0)}/day'
                            .trim(),
                      ),
                    );
                  }).toList(),
                  validator: (v) => v == null ? 'Required' : null,
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
            _dateButton(
              'Select Pickup Date',
              pickupDate,
              () => _pickDate(isPickup: true),
            ),
            _dateButton(
              'Select Return Date',
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
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: _isLoading ? null : _createBooking,
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
                      'Confirm Booking',
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
                  : DateFormat('dd MMM yyyy').format(date),
            ),
          ],
        ),
      ),
    );
  }
}
