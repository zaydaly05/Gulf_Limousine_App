import 'package:flutter/material.dart';

class WalletPaymentScreen extends StatefulWidget {
  final double amount;

  const WalletPaymentScreen({super.key, required this.amount});

  @override
  State<WalletPaymentScreen> createState() => _WalletPaymentScreenState();
}

class _WalletPaymentScreenState extends State<WalletPaymentScreen> {
  String? _selectedWallet;
  bool _loading = false;

  final List<String> wallets = [
    'Vodafone Cash',
    'Orange Cash',
    'Etisalat Cash',
  ];

  Future<void> _pay() async {
    if (_selectedWallet == null) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay EGP ${widget.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Choose your mobile wallet:'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  final selected = _selectedWallet == wallet;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: selected
                        ? const Color(0xFFFF8C00).withValues(alpha: 0.1)
                        : null,
                    child: ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet,
                        color: selected ? const Color(0xFFFF8C00) : Colors.grey,
                      ),
                      title: Text(wallet),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: Color(0xFFFF8C00))
                          : null,
                      onTap: () => setState(() => _selectedWallet = wallet),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedWallet == null || _loading ? null : _pay,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
