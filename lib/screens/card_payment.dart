import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardPaymentScreen extends StatefulWidget {
  final double amount;

  const CardPaymentScreen({super.key, required this.amount});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final card1 = TextEditingController();
  final card2 = TextEditingController();
  final card3 = TextEditingController();
  final card4 = TextEditingController();
  final name = TextEditingController();
  final month = TextEditingController();
  final year = TextEditingController();
  final cvv = TextEditingController();

  final card1Focus = FocusNode();
  final card2Focus = FocusNode();
  final card3Focus = FocusNode();
  final card4Focus = FocusNode();
  final nameFocus = FocusNode();
  final monthFocus = FocusNode();
  final yearFocus = FocusNode();
  final cvvFocus = FocusNode();

  bool _loading = false;

  @override
  void dispose() {
    card1.dispose();
    card2.dispose();
    card3.dispose();
    card4.dispose();
    name.dispose();
    month.dispose();
    year.dispose();
    cvv.dispose();
    card1Focus.dispose();
    card2Focus.dispose();
    card3Focus.dispose();
    card4Focus.dispose();
    nameFocus.dispose();
    monthFocus.dispose();
    yearFocus.dispose();
    cvvFocus.dispose();
    super.dispose();
  }

  void _onDigitsChanged({
    required String value,
    required int maxLength,
    required FocusNode? nextFocus,
    required FocusNode? previousFocus,
    required TextEditingController controller,
  }) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits != value) {
      controller.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
      return;
    }

    if (digits.length >= maxLength && nextFocus != null) {
      nextFocus.requestFocus();
    } else if (digits.isEmpty && previousFocus != null) {
      previousFocus.requestFocus();
    }
  }

  Future<void> _checkout() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Payment')),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'Checkout with credit card',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _cardBox(
                          controller: card1,
                          focusNode: card1Focus,
                          nextFocus: card2Focus,
                        ),
                        _cardBox(
                          controller: card2,
                          focusNode: card2Focus,
                          nextFocus: card3Focus,
                          previousFocus: card1Focus,
                        ),
                        _cardBox(
                          controller: card3,
                          focusNode: card3Focus,
                          nextFocus: card4Focus,
                          previousFocus: card2Focus,
                        ),
                        _cardBox(
                          controller: card4,
                          focusNode: card4Focus,
                          nextFocus: nameFocus,
                          previousFocus: card3Focus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: name,
                      focusNode: nameFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => monthFocus.requestFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Card Owner',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _digitField(
                            controller: month,
                            focusNode: monthFocus,
                            label: 'MM',
                            maxLength: 2,
                            nextFocus: yearFocus,
                            previousFocus: nameFocus,
                            validator: (v) {
                              if (v == null || v.length != 2) return 'MM';
                              final m = int.tryParse(v);
                              if (m == null || m < 1 || m > 12) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _digitField(
                            controller: year,
                            focusNode: yearFocus,
                            label: 'YYYY',
                            maxLength: 4,
                            nextFocus: cvvFocus,
                            previousFocus: monthFocus,
                            validator: (v) {
                              if (v == null || v.length != 4) return 'YYYY';
                              final y = int.tryParse(v);
                              if (y == null || y < DateTime.now().year) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _digitField(
                            controller: cvv,
                            focusNode: cvvFocus,
                            label: 'CVV',
                            maxLength: 3,
                            obscureText: true,
                            previousFocus: yearFocus,
                            validator: (v) =>
                                v == null || v.length != 3 ? 'CVV' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'EGP ${widget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFFF8C00),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _checkout,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    FocusNode? previousFocus,
  }) {
    return SizedBox(
      width: 70,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 4,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        onChanged: (value) => _onDigitsChanged(
          value: value,
          maxLength: 4,
          nextFocus: nextFocus,
          previousFocus: previousFocus,
          controller: controller,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(),
          hintText: '••••',
        ),
        validator: (v) => v == null || v.length != 4 ? '' : null,
      ),
    );
  }

  Widget _digitField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required int maxLength,
    FocusNode? nextFocus,
    FocusNode? previousFocus,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLength: maxLength,
      obscureText: obscureText,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      onChanged: (value) => _onDigitsChanged(
        value: value,
        maxLength: maxLength,
        nextFocus: nextFocus,
        previousFocus: previousFocus,
        controller: controller,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
