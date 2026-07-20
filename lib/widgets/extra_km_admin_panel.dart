import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import '../services/km_billing_service.dart';
import 'admin_charts.dart';

class ExtraKmAdminPanel extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> booking;
  final bool compact;

  const ExtraKmAdminPanel({
    super.key,
    required this.bookingId,
    required this.booking,
    this.compact = false,
  });

  @override
  State<ExtraKmAdminPanel> createState() => _ExtraKmAdminPanelState();
}

class _ExtraKmAdminPanelState extends State<ExtraKmAdminPanel> {
  bool _loading = false;

  Map<String, dynamic> get _booking => widget.booking;

  Future<void> _setPaid(bool paid) async {
    final label = paid ? 'paid' : 'pending';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          paid ? 'Confirm payment received?' : 'Mark as unpaid?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          paid
              ? 'Mark the extra kilometer charge as paid for this booking.'
              : 'Set the extra kilometer charge back to pending.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              paid ? 'Mark paid' : 'Mark pending',
              style: TextStyle(color: paid ? Colors.green : Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await BookingService.setExtraKmPaymentStatus(
        bookingId: widget.bookingId,
        paid: paid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extra km marked as $label'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final odometer = parseOdometer(_booking);
    final km = parseKmAllowance(_booking);
    final startKm = odometer?['startKm'];
    final endKm = odometer?['endKm'];
    final hasKmData = startKm != null || endKm != null;
    final hasExtra = bookingHasExtraKmCharge(_booking);
    final paymentStatus = (_booking['extraKmPaymentStatus'] ?? '').toString();
    final isPending = paymentStatus == 'pending';
    final isPaid = paymentStatus == 'paid';
    final finalAmount = (_booking['final_amount'] as num?)?.toDouble();
    final baseAmount = (_booking['total_amount'] as num?)?.toDouble() ?? 0;

    if (!hasKmData && !hasExtra) {
      return Text(
        'No odometer readings yet',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                'Odometer & extra km',
                style: TextStyle(
                  color: Colors.grey.shade200,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (startKm != null)
            _line('Pickup km', startKm.toString()),
          if (endKm != null) _line('Return km', endKm.toString()),
          if (km != null) ...[
            if (km['drivenKm'] != null)
              _line('Driven', '${km['drivenKm']} km'),
            if (km['allowedKm'] != null)
              _line('Allowed', '${km['allowedKm']} km'),
            if ((km['extraKm'] as num? ?? 0) > 0)
              _line(
                'Extra km',
                '${km['extraKm']} km × '
                '${KmBillingService.extraKmRateEgp.toStringAsFixed(0)} EGP',
              ),
            if ((km['extraKmChargeEgp'] as num? ?? 0) > 0)
              _line(
                'Extra charge',
                'EGP ${(km['extraKmChargeEgp'] as num).toStringAsFixed(0)}',
                highlight: true,
              ),
          ],
          if (finalAmount != null && endKm != null)
            _line(
              'Final total',
              'EGP ${finalAmount.toStringAsFixed(0)} '
              '(base EGP ${baseAmount.toStringAsFixed(0)})',
            ),
          if (hasExtra) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Payment: ',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: extraKmPaymentStatusColor(_booking)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    extraKmPaymentStatusLabel(_booking).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: extraKmPaymentStatusColor(_booking),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasExtra && (isPending || isPaid)) ...[
            const SizedBox(height: 10),
            if (_loading)
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (widget.compact)
              Wrap(
                spacing: 8,
                children: [
                  if (isPending)
                    ElevatedButton.icon(
                      onPressed: () => _setPaid(true),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Mark paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (isPaid)
                    OutlinedButton.icon(
                      onPressed: () => _setPaid(false),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Mark pending'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isPending)
                    ElevatedButton.icon(
                      onPressed: () => _setPaid(true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve — extra km paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  if (isPaid) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _setPaid(false),
                      icon: const Icon(Icons.undo),
                      label: const Text('Mark as unpaid'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlight ? Colors.orange : Colors.grey.shade300,
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
