import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'Credit / Debit Card';
  final TextEditingController _promoController = TextEditingController();
  final double _slotReservation = 250;
  final double _estimatedKwh = 14.6;
  final double _serviceFee = 85;

  double get _totalAmount {
    final subtotal = _slotReservation + _serviceFee;
    final discount = _promoController.text.trim().toUpperCase() == 'EVSAVE'
        ? 120.0
        : 0.0;
    return subtotal - discount;
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentOptions = [
      'Credit / Debit Card',
      'Digital Wallet',
      'Cash on Site',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Summary',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Slot Reservation',
                      'LKR ${_slotReservation.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 12),
                    _summaryRow(
                      'Estimated kWh',
                      '${_estimatedKwh.toStringAsFixed(1)} kWh',
                    ),
                    const SizedBox(height: 12),
                    _summaryRow(
                      'Service Fee',
                      'LKR ${_serviceFee.toStringAsFixed(0)}',
                    ),
                    const Divider(color: Colors.white12, height: 28),
                    _summaryRow(
                      'Total Amount',
                      'LKR ${_totalAmount.toStringAsFixed(0)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'Payment Method',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ...paymentOptions.map((method) {
                final selected = _selectedMethod == method;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMethod = method),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.neonGreen.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.neonGreen.withValues(alpha: 0.5)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.neonGreen
                                  : Colors.white38,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.neonGreen,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                method == 'Credit / Debit Card'
                                    ? 'Visa • MasterCard • Amex'
                                    : method == 'Digital Wallet'
                                    ? 'Apple Pay • Google Pay'
                                    : 'Pay at the station after charging',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 18),

              const Text(
                'Promo Code',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _promoController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter code (e.g. EVSAVE)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(
                    Icons.discount_rounded,
                    color: AppColors.neonGreen,
                  ),
                  suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _promoController.text.trim().toUpperCase() ==
                                    'EVSAVE'
                                ? 'Promo applied successfully.'
                                : 'Promo code not valid.',
                          ),
                          backgroundColor:
                              _promoController.text.trim().toUpperCase() ==
                                  'EVSAVE'
                              ? AppColors.neonGreen
                              : Colors.redAccent,
                        ),
                      );
                    },
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: AppColors.neonGreen),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.neonGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.neonGreen),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Payment via $_selectedMethod is ready for checkout.',
                        ),
                        backgroundColor: AppColors.neonGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Pay LKR ${_totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.textPrimary : Colors.white70,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppColors.neonGreen : AppColors.textPrimary,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
