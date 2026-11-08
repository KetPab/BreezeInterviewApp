/*
Purpose of file: Displays an error message and retry action.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:flutter/material.dart';

class RecoveryNotice extends StatelessWidget {
  const RecoveryNotice({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Reload deliveries',
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    // Let assistive technology announce newly displayed errors without a tap.
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
}
