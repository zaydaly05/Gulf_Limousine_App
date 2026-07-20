import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/geo_location.dart';

class MapLocationPicker extends StatefulWidget {
  final String title;
  final GeoLocation? initial;

  const MapLocationPicker({
    super.key,
    required this.title,
    this.initial,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _pin;
  String _address = '';
  bool _resolving = false;
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _geocoding = Geocoding();

  static final _presets = <String, LatLng>{
    'Cairo Downtown': const LatLng(30.0444, 31.2357),
    'Cairo Airport': const LatLng(30.1219, 31.4056),
    'Giza Pyramids': const LatLng(29.9792, 31.1342),
    'New Cairo': const LatLng(30.0300, 31.4700),
    'Zamalek': const LatLng(30.0611, 31.2197),
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null && initial.isValid) {
      _pin = LatLng(initial.lat, initial.lng);
      _address = initial.address;
    } else {
      _pin = const LatLng(30.0444, 31.2357);
      _address = 'Cairo, Egypt';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _pin = point;
      _resolving = true;
    });
    try {
      final places = await _geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final parts = <String>[
          if (p.street != null && p.street!.trim().isNotEmpty) p.street!.trim(),
          if (p.subLocality != null && p.subLocality!.trim().isNotEmpty)
            p.subLocality!.trim(),
          if (p.locality != null && p.locality!.trim().isNotEmpty)
            p.locality!.trim(),
          if (p.administrativeArea != null &&
              p.administrativeArea!.trim().isNotEmpty)
            p.administrativeArea!.trim(),
        ];
        _address = parts.isEmpty
            ? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'
            : parts.join(', ');
      } else {
        _address =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      }
    } catch (_) {
      _address =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    }
    if (mounted) setState(() => _resolving = false);
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _resolving = true);
    try {
      final results =
          await _geocoding.locationFromAddress('$query, Cairo, Egypt');
      if (results.isNotEmpty) {
        final loc = results.first;
        final point = LatLng(loc.latitude, loc.longitude);
        _mapController.move(point, 15);
        await _reverseGeocode(point);
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _resolving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address not found. Try a Cairo landmark.')),
      );
    }
  }

  Future<void> _useMyLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      _mapController.move(point, 15);
      await _reverseGeocode(point);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }
  }

  void _confirm() {
    Navigator.pop(
      context,
      GeoLocation(lat: _pin.latitude, lng: _pin.longitude, address: _address),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'My location',
            icon: const Icon(Icons.my_location),
            onPressed: _useMyLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search address in Cairo...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onSubmitted: (_) => _searchAddress(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _presets.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(e.key),
                    onPressed: () async {
                      _mapController.move(e.value, 14);
                      await _reverseGeocode(e.value);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pin,
                    initialZoom: 13,
                    onTap: (_, point) => _reverseGeocode(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.g_l_t_final',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pin,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFFF8C00),
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_resolving)
                  const Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _address.isEmpty
                        ? 'Tap the map to choose a location'
                        : _address,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _address.isEmpty ? null : _confirm,
                    child: const Text('Confirm Location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
