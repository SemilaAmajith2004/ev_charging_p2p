import 'package:flutter/material.dart';
import '../../core/theme/app_color.dart';

class WalletScreen extends StatefulWidget {
  final double initialBalance;
  final List<Map<String, dynamic>>? newTransactions;

  const WalletScreen({
    super.key,
    this.initialBalance = 2500.00,
    this.newTransactions,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late double currentBalance;
  late List<Map<String, dynamic>> transactions;

  @override
  void initState() {
    super.initState();
    currentBalance = widget.initialBalance;
    
    // Default initial transactions list
    transactions = widget.newTransactions ?? [
      {
        'title': 'Slot Booking - Colombo Fast Station',
        'date': 'Today, 08:45 AM',
        'amount': 450.00,
        'isDebit': true,
      },
      {
        'title': 'Wallet Top-Up (Card **** 4321)',
        'date': 'Yesterday, 04:15 PM',
        'amount': 2000.00,
        'isDebit': false,
      },
      {
        'title': 'Slot Booking - Kandy Charge Point',
        'date': '10 Sep 2026, 02:30 PM',
        'amount': 350.00,
        'isDebit': true,
      },
    ];
  }

  void _showTopUpDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Top-Up EV Wallet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter amount to add to your account:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Amount (LKR)',
                  labelStyle: const TextStyle(color: AppColors.neonGreen),
                  prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.neonGreen),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.neonGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.neonGreen),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [500, 1000, 2000].map((quickAmount) {
                  return ChoiceChip(
                    label: Text('+ LKR $quickAmount'),
                    selected: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.neonGreen,
                    labelStyle: const TextStyle(color: AppColors.neonGreen, fontSize: 12),
                    onSelected: (_) {
                      amountController.text = quickAmount.toString();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final double? amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  setState(() {
                    currentBalance += amount;
                    transactions.insert(0, {
                      'title': 'Wallet Top-Up',
                      'date': 'Just Now',
                      'amount': amount,
                      'isDebit': false,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully reloaded LKR ${amount.toStringAsFixed(2)}!'),
                      backgroundColor: AppColors.neonGreen,
                    ),
                  );
                }
              },
              child: const Text('Add Funds'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'My Wallet',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: AppColors.neonGreen),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- WALLET CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.neonGreen.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Balance',
                          style: TextStyle(color: Color.fromARGB(255, 252, 252, 252), fontSize: 17),
                        ),
                        Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.neonGreen,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'LKR ${currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showTopUpDialog,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text(
                          'Top-Up Wallet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- TRANSACTIONS HISTORY HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${transactions.length} Activity',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- TRANSACTION LIST ---
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final bool isDebit = tx['isDebit'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDebit
                              ? Colors.redAccent.withValues(alpha: 0.15)
                              : AppColors.neonGreen.withValues(alpha: 0.15),
                          child: Icon(
                            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isDebit ? Colors.redAccent : AppColors.neonGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx['title'],
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx['date'],
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isDebit ? "-" : "+"} LKR ${tx['amount'].abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isDebit ? Colors.redAccent : AppColors.neonGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}