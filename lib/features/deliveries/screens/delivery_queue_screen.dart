/*
Purpose of file: Displays the delivery queue, current statuses, and loading errors.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/delivery_controller.dart';
import '../widgets/delivery_status_label.dart';
import '../widgets/recovery_notice.dart';
import 'delivery_detail_screen.dart';

class DeliveryQueueScreen extends StatelessWidget {
  const DeliveryQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveryController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breaze Backup'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.local_shipping_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _content(context, controller),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, DeliveryController controller) {
    // After the first load, keep confirmed records visible during reloads.
    if (!controller.hasLoaded && controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!controller.hasLoaded && controller.loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: RecoveryNotice(
          message: controller.loadError!,
          actionLabel: 'Retry',
          onRetry: controller.retryLoad,
        ),
      );
    }
    return ListView(
      key: const ValueKey('delivery-queue'),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Delivery queue',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${controller.deliveries.length} deliveries · Stored on this device',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (controller.isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        if (controller.loadError != null) ...[
          RecoveryNotice(
            message: controller.loadError!,
            onRetry: controller.isLoading ? null : controller.retryLoad,
          ),
          const SizedBox(height: 16),
        ],
        if (controller.deliveries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No deliveries available')),
          ),
        for (final delivery in controller.deliveries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('delivery-${delivery.id}'),
                // Pass an ID so details reads the latest shared snapshot.
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DeliveryDetailScreen(deliveryId: delivery.id),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERY #${delivery.id}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              delivery.customerName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(delivery.address),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          DeliveryStatusLabel(status: delivery.status),
                          if (controller.isSaving(delivery.id))
                            const Text('Saving status…'),
                        ],
                      ),
                      if (controller.errorFor(delivery.id)
                          case final error?) ...[
                        const SizedBox(height: 12),
                        RecoveryNotice(
                          message: error,
                          onRetry: controller.isLoading
                              ? null
                              : controller.retryLoad,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
