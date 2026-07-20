import 'package:url_launcher/url_launcher.dart';

import '../models/geo_location.dart';

class MapsLauncher {
  static Future<void> openDirections({
    GeoLocation? destination,
    GeoLocation? origin,
  }) async {
    if (destination == null || !destination.isValid) return;

    final dest = '${destination.lat},${destination.lng}';
    final originParam = origin != null && origin.isValid
        ? '&origin=${origin.lat},${origin.lng}'
        : '';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$dest$originParam',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openLocation(GeoLocation location) async {
    if (!location.isValid) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.lat},${location.lng}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> callPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return;
    await launchUrl(Uri.parse('tel:$cleaned'));
  }
}
