import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const _phone = '+201001116666';
  static const _email = 'info@gulflimousine.com';

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "We'd love to hear from you",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'For bookings, support, or inquiries, reach out through any channel below.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            _ContactTile(
              icon: Icons.phone,
              title: 'Phone',
              value: _phone,
              onTap: () => _launch(Uri.parse('tel:$_phone')),
            ),
            _ContactTile(
              icon: Icons.email,
              title: 'Email',
              value: _email,
              onTap: () => _launch(Uri.parse('mailto:$_email')),
            ),
            _ContactTile(
              icon: Icons.location_on,
              title: 'Location',
              value: 'Cairo, Egypt',
              onTap: () => _launch(
                Uri.parse('https://maps.google.com/?q=Cairo,Egypt'),
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Text(
                    'Gulf Limousine Travel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Luxury rides, reliable service',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFFF8C00).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFF8C00),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(value,
                          style: TextStyle(
                              fontSize: 15, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, color: Colors.grey.shade500, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
