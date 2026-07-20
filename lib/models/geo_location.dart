import 'package:cloud_firestore/cloud_firestore.dart';

class GeoLocation {
  final double lat;
  final double lng;
  final String address;

  const GeoLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'address': address,
      };

  factory GeoLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const GeoLocation(lat: 0, lng: 0, address: '');
    }
    return GeoLocation(
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      address: (map['address'] ?? '').toString(),
    );
  }

  bool get isValid => address.isNotEmpty && (lat != 0 || lng != 0);

  static GeoLocation? tryParse(dynamic value) {
    if (value is Map<String, dynamic>) {
      final loc = GeoLocation.fromMap(value);
      return loc.isValid ? loc : null;
    }
    if (value is Map) {
      final loc = GeoLocation.fromMap(Map<String, dynamic>.from(value));
      return loc.isValid ? loc : null;
    }
    return null;
  }

  /// Cairo city center default.
  static const cairo = GeoLocation(
    lat: 30.0444,
    lng: 31.2357,
    address: 'Cairo, Egypt',
  );
}

class LiveLocation {
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  const LiveLocation({
    required this.lat,
    required this.lng,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
  };

  factory LiveLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const LiveLocation(lat: 0, lng: 0);
    }
    final updated = map['updatedAt'];
    return LiveLocation(
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }

  bool get isValid => lat != 0 || lng != 0;
}
