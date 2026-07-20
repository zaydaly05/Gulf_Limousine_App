import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/booking_service.dart';
import '../services/cloudinary_service.dart';
import '../services/km_billing_service.dart';
import '../services/odometer_service.dart';

enum OdometerCaptureMode { start, end }

class OdometerCaptureScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final OdometerCaptureMode mode;

  const OdometerCaptureScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
    required this.mode,
  });

  @override
  State<OdometerCaptureScreen> createState() => _OdometerCaptureScreenState();
}

class _OdometerCaptureScreenState extends State<OdometerCaptureScreen> {
  final _kmController = TextEditingController();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();

  File? _imageFile;
  String? _uploadedUrl;
  String? _uploadedPublicId;
  bool _processing = false;
  bool _ocrRunning = false;
  String? _error;

  bool get _isStart => widget.mode == OdometerCaptureMode.start;

  String get _title =>
      _isStart ? 'Record pickup odometer' : 'Record return odometer';

  int get _rentalDays {
    final days = widget.bookingData['days'];
    if (days is num) return days.toInt().clamp(1, 3650);
    return 1;
  }

  int? get _startKm {
    final odometer = widget.bookingData['odometer'];
    if (odometer is Map) {
      final v = odometer['startKm'];
      if (v is num) return v.toInt();
    }
    return null;
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto(ImageSource source) async {
    setState(() {
      _error = null;
    });

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (image == null || !mounted) return;

    setState(() {
      _imageFile = File(image.path);
      _uploadedUrl = null;
      _uploadedPublicId = null;
      _ocrRunning = true;
    });

    final bytes = await image.readAsBytes();
    final detected = await OdometerService.extractKmFromImage(bytes);

    if (!mounted) return;
    setState(() {
      _ocrRunning = false;
      if (detected != null) {
        _kmController.text = detected.toString();
      }
    });

    if (detected == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read odometer automatically. Enter the km manually.',
          ),
        ),
      );
    }
  }

  void _showCaptureOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _capturePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _capturePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final kmText = _kmController.text.trim().replaceAll(',', '');
    final km = int.tryParse(kmText);
    if (km == null || km <= 0) {
      setState(() => _error = 'Enter a valid odometer reading in km');
      return;
    }

    if (_imageFile == null) {
      setState(() => _error = 'Take a photo of the odometer first');
      return;
    }

    if (!_isStart) {
      final start = _startKm;
      if (start != null && km < start) {
        setState(
          () => _error = 'Return reading must be at least $start km',
        );
        return;
      }
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      String photoUrl = _uploadedUrl ?? '';
      String photoPublicId = _uploadedPublicId ?? '';

      if (photoUrl.isEmpty) {
        final bytes = await _imageFile!.readAsBytes();
        final upload = await _cloudinary.uploadBytes(
          bytes,
          filename: 'odometer_${widget.bookingId}.jpg',
        );
        if (upload == null) {
          throw Exception('Failed to upload photo');
        }
        photoUrl = upload['secure_url']?.toString() ?? '';
        photoPublicId = upload['public_id']?.toString() ?? '';
      }

      if (_isStart) {
        await BookingService.recordStartKm(
          bookingId: widget.bookingId,
          km: km,
          photoUrl: photoUrl,
          photoPublicId: photoPublicId,
        );
      } else {
        await BookingService.recordEndKmAndFinalize(
          bookingId: widget.bookingId,
          km: km,
          photoUrl: photoUrl,
          photoPublicId: photoPublicId,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildBillingPreview() {
    if (_isStart) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Allowance: ${KmBillingService.allowedKm(_rentalDays)} km '
          '(${KmBillingService.kmPerDay} km × $_rentalDays day(s)). '
          'Extra km charged at ${KmBillingService.extraKmRateEgp.toStringAsFixed(0)} EGP/km.',
          style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
        ),
      );
    }

    final start = _startKm;
    final endText = _kmController.text.trim().replaceAll(',', '');
    final end = int.tryParse(endText);
    if (start == null || end == null || end < start) {
      return const SizedBox.shrink();
    }

    final billing = KmBillingService.calculate(
      startKm: start,
      endKm: end,
      rentalDays: _rentalDays,
    );
    final base = (widget.bookingData['total_amount'] as num?)?.toDouble() ?? 0;
    final finalAmount = KmBillingService.finalAmount(
      baseAmount: base,
      billing: billing,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: billing.extraKm > 0 ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Driven: ${billing.drivenKm} km'),
          Text('Allowed: ${billing.allowedKm} km'),
          Text(
            'Extra km: ${billing.extraKm} × '
            '${KmBillingService.extraKmRateEgp.toStringAsFixed(0)} EGP = '
            'EGP ${billing.extraKmChargeEgp.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: billing.extraKm > 0
                  ? Colors.orange.shade900
                  : Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Final total: EGP ${finalAmount.toStringAsFixed(0)} '
            '(base EGP ${base.toStringAsFixed(0)} + extra)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isStart
                  ? 'Photograph the odometer when you receive the car.'
                  : 'Photograph the odometer when you return the car.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _processing ? null : _showCaptureOptions,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
                          if (_ocrRunning)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Reading odometer…',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.speed,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to capture odometer photo',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Odometer reading (km)',
                hintText: _isStart ? 'e.g. 45230' : 'e.g. 45450',
                border: const OutlineInputBorder(),
                suffixText: 'km',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (!_isStart && _startKm != null) ...[
              const SizedBox(height: 8),
              Text(
                'Pickup reading: $_startKm km',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            _buildBillingPreview(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _processing ? null : _submit,
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isStart ? Icons.login : Icons.logout),
              label: Text(_isStart ? 'Confirm pickup km' : 'Confirm return km'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
