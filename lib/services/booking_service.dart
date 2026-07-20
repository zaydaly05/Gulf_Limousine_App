import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/geo_location.dart';
import 'km_billing_service.dart';

class RentalDetails {
  final String carId;
  final String carName;
  final String brand;
  final double pricePerDay;
  final DateTime pickupDate;
  final DateTime returnDate;
  final int days;
  final GeoLocation? pickupLocation;
  final GeoLocation? dropoffLocation;

  const RentalDetails({
    required this.carId,
    required this.carName,
    required this.brand,
    required this.pricePerDay,
    required this.pickupDate,
    required this.returnDate,
    required this.days,
    this.pickupLocation,
    this.dropoffLocation,
  });

  double get totalAmount => pricePerDay * days;

  Map<String, dynamic> toMap() => {
        'carId': carId,
        'carName': carName,
        'brand': brand,
        'pricePerDay': pricePerDay,
        'pickupDate': pickupDate.toIso8601String(),
        'returnDate': returnDate.toIso8601String(),
        'days': days,
        'totalAmount': totalAmount,
        if (pickupLocation != null) 'pickupLocation': pickupLocation!.toMap(),
        if (dropoffLocation != null) 'dropoffLocation': dropoffLocation!.toMap(),
      };

  factory RentalDetails.fromMap(Map<String, dynamic> map) {
    return RentalDetails(
      carId: map['carId'] as String,
      carName: map['carName'] as String,
      brand: map['brand'] as String? ?? '',
      pricePerDay: (map['pricePerDay'] as num).toDouble(),
      pickupDate: DateTime.parse(map['pickupDate'] as String),
      returnDate: DateTime.parse(map['returnDate'] as String),
      days: map['days'] as int,
      pickupLocation: GeoLocation.tryParse(map['pickupLocation']),
      dropoffLocation: GeoLocation.tryParse(map['dropoffLocation']),
    );
  }
}

class BookingService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<String> completeRental({
    required RentalDetails rental,
    required String paymentMethod,
    String paymentStatus = 'paid',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final userName = userData['name'] ?? user.displayName ?? 'User';
    final userEmail = user.email ?? userData['email'] ?? '';

    final status = paymentStatus == 'paid' ? 'confirmed' : 'pending';

    final bookingRef = await _firestore.collection('bookings').add({
      'userId': user.uid,
      'user_email': userEmail,
      'userName': userName,
      'customerName': userName,
      'car_id': rental.carId,
      'car_name': rental.carName,
      'carName': rental.carName,
      'brand': rental.brand,
      'pickupDate': Timestamp.fromDate(rental.pickupDate),
      'returnDate': Timestamp.fromDate(rental.returnDate),
      'startDate': Timestamp.fromDate(rental.pickupDate),
      'days': rental.days,
      'price_per_day': rental.pricePerDay,
      'total_amount': rental.totalAmount,
      'status': status,
      'payment_method': paymentMethod,
      'tripStatus': 'pending',
      if (rental.pickupLocation != null)
        'pickupLocation': rental.pickupLocation!.toMap(),
      if (rental.dropoffLocation != null)
        'dropoffLocation': rental.dropoffLocation!.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('payments').add({
      'userId': user.uid,
      'user_email': userEmail,
      'booking_id': bookingRef.id,
      'car_name': rental.carName,
      'amount': rental.totalAmount,
      'method': paymentMethod,
      'status': paymentStatus,
      'payment_date': FieldValue.serverTimestamp(),
    });

    // In-app notifications (never fail the payment if rules block a write)
    try {
      await _notifyUser(
        userId: user.uid,
        title: status == 'confirmed' ? 'Booking confirmed' : 'Booking received',
        body:
            'Your ${rental.carName} rental is $status. Open My Bookings for details.',
        type: 'booking_$status',
        bookingId: bookingRef.id,
      );
    } catch (_) {}

    try {
      await _notifyAdmins(
        title: 'New booking',
        body: '$userName booked ${rental.carName}',
        type: 'new_booking',
        bookingId: bookingRef.id,
      );
    } catch (_) {}

    return bookingRef.id;
  }

  static Future<void> cancelBooking(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final ref = _firestore.collection('bookings').doc(bookingId);
    final doc = await ref.get();
    if (!doc.exists) throw Exception('Booking not found');

    final data = doc.data()!;
    if (data['userId'] != user.uid && data['user_email'] != user.email) {
      throw Exception('Not allowed');
    }

    final status = (data['status'] ?? '').toString().toLowerCase();
    if (status != 'pending' && status != 'confirmed') {
      throw Exception('Only pending or confirmed bookings can be cancelled');
    }

    final pickup = data['pickupDate'];
    if (pickup is Timestamp && pickup.toDate().isBefore(DateTime.now())) {
      throw Exception('Cannot cancel after pickup date');
    }

    await ref.update({
      'status': 'cancelled',
      'tripStatus': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    try {
      await _notifyUser(
        userId: user.uid,
        title: 'Booking cancelled',
        body:
            'Your booking for ${data['carName'] ?? data['car_name'] ?? 'car'} was cancelled.',
        type: 'booking_cancelled',
        bookingId: bookingId,
      );
    } catch (_) {}
  }

  static Future<void> assignChauffeur({
    required String bookingId,
    required String chauffeurId,
    required String chauffeurName,
    required String chauffeurPhone,
  }) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final doc = await bookingRef.get();
    final userId = doc.data()?['userId']?.toString();

    final currentTrip = (doc.data()?['tripStatus'] ?? 'pending').toString();
    await bookingRef.update({
      'chauffeurId': chauffeurId,
      'chauffeurName': chauffeurName,
      'chauffeurPhone': chauffeurPhone,
      if (currentTrip == 'pending' || currentTrip.isEmpty) 'tripStatus': 'assigned',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (userId != null && userId.isNotEmpty) {
      await _notifyUser(
        userId: userId,
        title: 'Chauffeur assigned',
        body: '$chauffeurName will drive your trip. Track from My Bookings.',
        type: 'chauffeur_assigned',
        bookingId: bookingId,
      );
    }
  }

  static Future<void> updateTripStatus({
    required String bookingId,
    required String tripStatus,
  }) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final doc = await bookingRef.get();
    final userId = doc.data()?['userId']?.toString();

    final updates = <String, dynamic>{
      'tripStatus': tripStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (tripStatus == 'completed') {
      updates['status'] = 'completed';
    }

    await bookingRef.update(updates);

    if (userId != null && userId.isNotEmpty) {
      final label = tripStatus.replaceAll('_', ' ');
      await _notifyUser(
        userId: userId,
        title: 'Trip update',
        body: 'Your trip is now $label.',
        type: 'trip_$tripStatus',
        bookingId: bookingId,
      );
    }
  }

  static Future<void> updateLiveLocation({
    required String bookingId,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'liveLocation': {
        'lat': lat,
        'lng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  static Future<void> _notifyUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? bookingId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'bookingId': ?bookingId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _notifyAdmins({
    required String title,
    required String body,
    required String type,
    String? bookingId,
  }) async {
    // Users cannot write into other users' docs; use a shared alerts collection.
    await _firestore.collection('admin_alerts').add({
      'title': title,
      'body': body,
      'type': type,
      'bookingId': ?bookingId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> userBookingsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  static Stream<QuerySnapshot> userBookingsStreamByEmail() {
    final email = _auth.currentUser?.email;
    if (email == null) return const Stream.empty();
    return _firestore
        .collection('bookings')
        .where('user_email', isEqualTo: email)
        .snapshots();
  }

  static int? _odometerKm(Map<String, dynamic>? odometer, String key) {
    if (odometer == null) return null;
    final v = odometer[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  static Future<void> recordStartKm({
    required String bookingId,
    required int km,
    required String photoUrl,
    required String photoPublicId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final ref = _firestore.collection('bookings').doc(bookingId);
    final doc = await ref.get();
    if (!doc.exists) throw Exception('Booking not found');

    final data = doc.data()!;
    if (data['userId'] != user.uid && data['user_email'] != user.email) {
      throw Exception('Not allowed');
    }

    final status = (data['status'] ?? '').toString().toLowerCase();
    if (status == 'cancelled' || status == 'completed') {
      throw Exception('Cannot record km for this booking');
    }

    final existing = data['odometer'];
    if (existing is Map && existing['startKm'] != null) {
      throw Exception('Pickup km already recorded');
    }

    final carId = data['car_id']?.toString() ?? data['carId']?.toString();

    await ref.update({
      'odometer': {
        'startKm': km,
        'startPhotoUrl': photoUrl,
        'startPhotoPublicId': photoPublicId,
        'startCapturedAt': FieldValue.serverTimestamp(),
        'startCapturedBy': user.uid,
      },
      'tripStatus': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (carId != null && carId.isNotEmpty) {
      try {
        await _firestore.collection('cars').doc(carId).update({
          'current_odometer': km,
        });
      } catch (_) {}
    }

    try {
      await _notifyAdmins(
        title: 'Pickup km recorded',
        body:
            '${data['carName'] ?? data['car_name'] ?? 'Car'} pickup at $km km',
        type: 'odometer_start',
        bookingId: bookingId,
      );
    } catch (_) {}
  }

  static Future<void> recordEndKmAndFinalize({
    required String bookingId,
    required int km,
    required String photoUrl,
    required String photoPublicId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final ref = _firestore.collection('bookings').doc(bookingId);
    final doc = await ref.get();
    if (!doc.exists) throw Exception('Booking not found');

    final data = doc.data()!;
    if (data['userId'] != user.uid && data['user_email'] != user.email) {
      throw Exception('Not allowed');
    }

    final odometer = data['odometer'];
    if (odometer is! Map) {
      throw Exception('Record pickup km first');
    }

    final startKm = _odometerKm(Map<String, dynamic>.from(odometer), 'startKm');
    if (startKm == null) throw Exception('Record pickup km first');
    if (odometer['endKm'] != null) {
      throw Exception('Return km already recorded');
    }
    if (km < startKm) {
      throw Exception('Return km must be at least $startKm');
    }

    final days = (data['days'] as num?)?.toInt() ?? 1;
    final baseAmount = (data['total_amount'] as num?)?.toDouble() ?? 0;
    final billing = KmBillingService.calculate(
      startKm: startKm,
      endKm: km,
      rentalDays: days,
    );
    final finalAmount = KmBillingService.finalAmount(
      baseAmount: baseAmount,
      billing: billing,
    );

    final carId = data['car_id']?.toString() ?? data['carId']?.toString();
    final carName =
        (data['carName'] ?? data['car_name'] ?? 'car').toString();

    await ref.update({
      'odometer': {
        ...Map<String, dynamic>.from(odometer),
        'endKm': km,
        'endPhotoUrl': photoUrl,
        'endPhotoPublicId': photoPublicId,
        'endCapturedAt': FieldValue.serverTimestamp(),
        'endCapturedBy': user.uid,
      },
      'kmAllowance': {
        'kmPerDay': KmBillingService.kmPerDay,
        'allowedKm': billing.allowedKm,
        'drivenKm': billing.drivenKm,
        'extraKm': billing.extraKm,
        'extraKmRateEgp': KmBillingService.extraKmRateEgp,
        'extraKmChargeEgp': billing.extraKmChargeEgp,
      },
      'final_amount': finalAmount,
      'extraKmPaymentStatus':
          billing.extraKm > 0 ? 'pending' : 'not_applicable',
      'status': 'completed',
      'tripStatus': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (carId != null && carId.isNotEmpty) {
      try {
        await _firestore.collection('cars').doc(carId).update({
          'current_odometer': km,
        });
      } catch (_) {}
    }

    if (billing.extraKmChargeEgp > 0) {
      await _firestore.collection('payments').add({
        'userId': user.uid,
        'user_email': user.email ?? data['user_email'],
        'booking_id': bookingId,
        'car_name': carName,
        'amount': billing.extraKmChargeEgp,
        'method': 'extra_km',
        'status': 'pending',
        'description':
            'Extra ${billing.extraKm} km (${billing.drivenKm} driven, '
            '${billing.allowedKm} allowed)',
        'payment_date': FieldValue.serverTimestamp(),
      });
    }

    try {
      await _notifyUser(
        userId: user.uid,
        title: 'Rental completed',
        body: billing.extraKm > 0
            ? '$carName returned. Extra ${billing.extraKm} km: '
                'EGP ${billing.extraKmChargeEgp.toStringAsFixed(0)} due.'
            : '$carName returned. No extra km charges.',
        type: 'rental_completed',
        bookingId: bookingId,
      );
    } catch (_) {}

    try {
      await _notifyAdmins(
        title: 'Return km recorded',
        body: '$carName returned at $km km. '
            'Extra: ${billing.extraKm} km (EGP ${billing.extraKmChargeEgp.toStringAsFixed(0)})',
        type: 'odometer_end',
        bookingId: bookingId,
      );
    } catch (_) {}
  }

  static Future<void> _requireAdmin() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.data()?['role'] != 'admin') {
      throw Exception('Admin access required');
    }
  }

  /// Admin marks extra km charge as paid or pending.
  static Future<void> setExtraKmPaymentStatus({
    required String bookingId,
    required bool paid,
  }) async {
    await _requireAdmin();

    final ref = _firestore.collection('bookings').doc(bookingId);
    final doc = await ref.get();
    if (!doc.exists) throw Exception('Booking not found');

    final data = doc.data()!;
    final status = paid ? 'paid' : 'pending';
    final user = _auth.currentUser!;

    await ref.update({
      'extraKmPaymentStatus': status,
      if (paid) ...{
        'extraKmPaidAt': FieldValue.serverTimestamp(),
        'extraKmApprovedBy': user.uid,
      },
      if (!paid) ...{
        'extraKmPaidAt': FieldValue.delete(),
        'extraKmApprovedBy': FieldValue.delete(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final payments = await _firestore
        .collection('payments')
        .where('booking_id', isEqualTo: bookingId)
        .get();

    for (final payment in payments.docs) {
      final method = (payment.data()['method'] ?? '').toString();
      if (method != 'extra_km') continue;
      await payment.reference.update({
        'status': status,
        if (paid) 'paid_at': FieldValue.serverTimestamp(),
        if (!paid) 'paid_at': FieldValue.delete(),
      });
    }

    final userId = data['userId']?.toString();
    if (userId != null && userId.isNotEmpty) {
      try {
        final km = data['kmAllowance'];
        final charge = km is Map
            ? (km['extraKmChargeEgp'] as num?)?.toDouble() ?? 0
            : 0.0;
        await _notifyUser(
          userId: userId,
          title: paid ? 'Extra km payment confirmed' : 'Extra km payment pending',
          body: paid
              ? 'Your extra km charge of EGP ${charge.toStringAsFixed(0)} is marked as paid.'
              : 'Your extra km charge of EGP ${charge.toStringAsFixed(0)} is pending payment.',
          type: paid ? 'extra_km_paid' : 'extra_km_pending',
          bookingId: bookingId,
        );
      } catch (_) {}
    }
  }
}
