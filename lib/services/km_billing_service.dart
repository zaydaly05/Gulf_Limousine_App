class KmBillingResult {
  final int drivenKm;
  final int allowedKm;
  final int extraKm;
  final double extraKmChargeEgp;

  const KmBillingResult({
    required this.drivenKm,
    required this.allowedKm,
    required this.extraKm,
    required this.extraKmChargeEgp,
  });
}

class KmBillingService {
  static const int kmPerDay = 120;
  static const double extraKmRateEgp = 5.0;

  static int allowedKm(int rentalDays) =>
      rentalDays.clamp(1, 3650) * kmPerDay;

  static KmBillingResult calculate({
    required int startKm,
    required int endKm,
    required int rentalDays,
  }) {
    if (endKm < startKm) {
      throw ArgumentError('End km must be greater than or equal to start km');
    }

    final driven = endKm - startKm;
    final allowed = allowedKm(rentalDays);
    final extra = driven > allowed ? driven - allowed : 0;
    final charge = extra * extraKmRateEgp;

    return KmBillingResult(
      drivenKm: driven,
      allowedKm: allowed,
      extraKm: extra,
      extraKmChargeEgp: charge,
    );
  }

  static double finalAmount({
    required double baseAmount,
    required KmBillingResult billing,
  }) =>
      baseAmount + billing.extraKmChargeEgp;
}
