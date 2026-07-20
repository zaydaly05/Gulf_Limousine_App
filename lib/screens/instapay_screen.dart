import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class InstaPayScreen extends StatefulWidget {
  final double amount;

  const InstaPayScreen({super.key, required this.amount});

  @override
  State<InstaPayScreen> createState() => _InstaPayScreenState();
}

class _InstaPayScreenState extends State<InstaPayScreen> {
  static const String instapayUsername = 'zaydaly@instapay';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.egyptianbanks.instapay';

  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _copyUsername();
  }

  Future<void> _copyUsername() async {
    await Clipboard.setData(const ClipboardData(text: instapayUsername));
    setState(() => _copied = true);
  }

  Future<void> _openInstaPay() async {
    final instapayUri = Uri.parse('instapay://');
    if (await canLaunchUrl(instapayUri)) {
      await launchUrl(instapayUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse(playStoreUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InstaPay')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phone_android, size: 64, color: Color(0xFFFF8C00)),
            const SizedBox(height: 16),
            Text(
              'Pay EGP ${widget.amount.toStringAsFixed(0)} via InstaPay',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Send payment to:'),
                  const SizedBox(height: 8),
                  Text(
                    instapayUsername,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                  if (_copied)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Copied to clipboard',
                          style: TextStyle(color: Colors.green, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Open InstaPay\n2. Send Money\n3. Paste the username\n4. Enter the amount shown above\n5. Return here and confirm',
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _openInstaPay,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open InstaPay App'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('I Have Paid'),
            ),
          ],
        ),
      ),
    );
  }
}
