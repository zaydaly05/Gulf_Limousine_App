/// API keys for premium features.
/// Replace placeholder values with your real keys from Google AI Studio.
class ApiKeys {
  /// Google Gemini (AI Studio).
  static const gemini = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY',
  );

  static bool get hasGeminiKey =>
      gemini.isNotEmpty && !gemini.startsWith('YOUR_');
}
