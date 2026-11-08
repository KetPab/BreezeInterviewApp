/*
Purpose of file: Displays an accessible delivery status badge.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:flutter/material.dart';

import '../models/delivery_status.dart';

class DeliveryStatusLabel extends StatelessWidget {
  const DeliveryStatusLabel({required this.status, super.key});
  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      DeliveryStatus.pending => (
        const Color(0xFFFFEFC2),
        const Color(0xFF634700),
        Icons.schedule,
      ),
      DeliveryStatus.delivered => (
        const Color(0xFFD6F2DF),
        const Color(0xFF18552D),
        Icons.check_circle_outline,
      ),
      DeliveryStatus.failed => (
        const Color(0xFFFDE1DE),
        const Color(0xFF8A2420),
        Icons.error_outline,
      ),
    };
    // Announce the badge once, without separate decorative icon semantics.
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
