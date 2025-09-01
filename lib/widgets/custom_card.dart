import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
final int credits_used;
final int credits_remaining;

  const CustomCard({
    super.key,
    required this.credits_used,
    required this.credits_remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
                color: Colors.white,
                elevation: 9,
                shadowColor: Colors.black.withOpacity(1.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading:
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.green[700],
                        size: 40,
                      ),
                  title: const Text(
                    'Credits Remaining',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Text(
                    'Used: ${credits_used ?? 0}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  trailing: Text(
                    '${credits_remaining ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
    );
  }
}