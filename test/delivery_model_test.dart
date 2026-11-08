/*
Purpose of file: Tests package ownership, immutable lists, and status changes.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:breaze_backup/features/deliveries/models/delivery.dart';
import 'package:breaze_backup/features/deliveries/models/delivery_status.dart';
import 'package:breaze_backup/features/deliveries/models/package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('packages are immutable and preserved when delivery status changes', () {
    final packages = [
      const Package(packageID: 1, description: 'Books', deliveryID: 101),
    ];
    final delivery = Delivery(
      id: 101,
      customerName: 'Customer',
      address: 'Address',
      deliveryNotes: '',
      packages: packages,
    );
    packages.clear();
    expect(delivery.packages, hasLength(1));
    expect(() => delivery.packages.clear(), throwsUnsupportedError);
    final updated = delivery.withStatus(
      DeliveryStatus.delivered,
      DateTime.utc(2026),
    );
    expect(updated.packages.single.packageID, 1);
    expect(updated.packages.single.description, 'Books');
    expect(updated.packages.single.deliveryID, 101);
  });

  test('a delivery rejects packages assigned to another delivery', () {
    expect(
      () => Delivery(
        id: 101,
        customerName: 'Customer',
        address: 'Address',
        deliveryNotes: '',
        packages: const [
          Package(packageID: 1, description: 'Books', deliveryID: 102),
        ],
      ),
      throwsArgumentError,
    );
  });
}
