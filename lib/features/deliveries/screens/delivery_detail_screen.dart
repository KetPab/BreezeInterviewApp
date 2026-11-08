/*
Purpose of file: Displays delivery details, assigned packages, and status actions.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/delivery_status.dart';
import '../state/delivery_controller.dart';
import '../widgets/delivery_status_label.dart';
import '../widgets/recovery_notice.dart';

class DeliveryDetailScreen extends StatelessWidget {
  const DeliveryDetailScreen({required this.deliveryId, super.key});
  final int deliveryId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveryController>();
    final delivery = controller.deliveryById(deliveryId);
    final enabled = controller.canRecord(deliveryId);
    final error = controller.errorFor(deliveryId) ?? controller.loadError;
    return Scaffold(
      appBar: AppBar(title: Text('Delivery #$deliveryId')),
      body: SafeArea(
        child: delivery == null
            ? const Center(child: Text('Delivery not found'))
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    key: const ValueKey('delivery-details'),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        delivery.customerName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DeliveryStatusLabel(status: delivery.status),
                      ),
                      const SizedBox(height: 24),
                      _field(context, 'Delivery address', delivery.address),
                      _field(
                        context,
                        'Delivery notes',
                        delivery.deliveryNotes.isEmpty
                            ? 'No delivery notes'
                            : delivery.deliveryNotes,
                      ),
                      if (error != null) ...[
                        RecoveryNotice(
                          message: error,
                          onRetry: controller.isLoading
                              ? null
                              : controller.retryLoad,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (controller.isSaving(deliveryId) ||
                          controller.isLoading) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          controller.isLoading
                              ? 'Reloading deliveries…'
                              : 'Saving status…',
                        ),
                        const SizedBox(height: 16),
                      ],
                      FilledButton.icon(
                        key: const ValueKey('mark-delivered'),
                        onPressed:
                            enabled &&
                                delivery.status != DeliveryStatus.delivered
                            ? () => controller.markDelivered(deliveryId)
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark Delivered'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const ValueKey('mark-failed'),
                        onPressed:
                            enabled && delivery.status != DeliveryStatus.failed
                            ? () => controller.markFailed(deliveryId)
                            : null,
                        icon: const Icon(Icons.error_outline),
                        label: const Text('Mark Failed'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Packages (${delivery.packages.length})',
                        key: const ValueKey('delivery-packages'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (delivery.packages.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Text('No packages assigned.'),
                        ),
                      for (final package in delivery.packages)
                        _field(
                          context,
                          'Package #${package.packageID}',
                          package.description,
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _field(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}
