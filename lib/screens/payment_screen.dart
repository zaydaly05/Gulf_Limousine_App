import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/booking_service.dart';
import '../widgets/expandable_address_row.dart';
import 'card_payment.dart';
import 'instapay_screen.dart';
import 'payment_success_screen.dart';
import 'wallet_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  final RentalDetails rental;

  const PaymentScreen({super.key, required this.rental});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  Future<void> _payWithMethod(String method, Widget screen) async {
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (confirmed == true) {
      await _completePayment(method);
    }
  }

  Future<void> _completePayment(String method) async {
    setState(() => _isProcessing = true);
    try {
      final status = method == 'cash' ? 'pending' : 'paid';
      await BookingService.completeRental(
        rental: widget.rental,
        paymentMethod: method,
        paymentStatus: status,
      );
      if (!mounted) return;
      final isCash = method == 'cash';
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            title: isCash ? 'Order Confirmed' : 'Payment Successful',
            message: isCash
                ? 'Thank you for choosing Gulf Limousine Travel.\nPay cash when you collect the car.'
                : 'Thank you for choosing Gulf Limousine Travel.\nYour car has been successfully booked.',
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rental = widget.rental;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(
                    children: [
                      _summaryRow('Car', rental.carName),
                      if (rental.brand.isNotEmpty)
                        _summaryRow('Brand', rental.brand),
                      _summaryRow('Pickup', dateFmt.format(rental.pickupDate)),
                      _summaryRow('Return', dateFmt.format(rental.returnDate)),
                      if (rental.pickupLocation != null)
                        ExpandableAddressRow(
                          label: 'Pickup location',
                          address: rental.pickupLocation!.address,
                          icon: Icons.place,
                        ),
                      if (rental.dropoffLocation != null)
                        ExpandableAddressRow(
                          label: 'Drop-off location',
                          address: rental.dropoffLocation!.address,
                          icon: Icons.flag,
                          iconColor: Colors.blue,
                        ),
                      _summaryRow('Duration', '${rental.days} day(s)'),
                      _summaryRow('Rate', 'EGP ${rental.pricePerDay.toStringAsFixed(0)} / day'),
                      const Divider(height: 24),
                      _summaryRow(
                        'Total',
                        'EGP ${rental.totalAmount.toStringAsFixed(0)}',
                        bold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _PaymentMethodTile(
                    icon: Icons.credit_card,
                    title: 'Credit / Debit Card',
                    onTap: () => _payWithMethod(
                      'card',
                      CardPaymentScreen(amount: rental.totalAmount),
                    ),
                  ),
                  _PaymentMethodTile(
                    icon: Icons.account_balance_wallet,
                    title: 'Mobile Wallet',
                    onTap: () => _payWithMethod(
                      'wallet',
                      WalletPaymentScreen(amount: rental.totalAmount),
                    ),
                  ),
                  _PaymentMethodTile(
                    icon: Icons.phone_android,
                    title: 'InstaPay',
                    onTap: () => _payWithMethod(
                      'instapay',
                      InstaPayScreen(amount: rental.totalAmount),
                    ),
                  ),
                  _PaymentMethodTile(
                    icon: Icons.money,
                    title: 'Cash on Pickup',
                    subtitle: 'Pay when you collect the car',
                    onTap: () => _completePayment('cash'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 18 : 14,
              color: bold ? const Color(0xFFFF8C00) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Widget> children;

  const _SummaryCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF8C00).withValues(alpha: 0.15),
          child: Icon(icon, color: const Color(0xFFFF8C00)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
