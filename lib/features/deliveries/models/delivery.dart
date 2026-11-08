/*
Purpose of file: Represents a delivery, its packages, and its current status.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'delivery_status.dart';
import 'package.dart';

class Delivery {
  Delivery({
    required this.id,
    required this.customerName,
    required this.address,
    required this.deliveryNotes,
    this.status = DeliveryStatus.pending,
    this.updatedAt,
    List<Package> packages = const [],
  }) : packages = List.unmodifiable(packages) {
    if (this.packages.any((package) => package.deliveryID != id)) {
      throw ArgumentError('Every package must belong to this delivery.');
    }
  }

  final int id;
  final String customerName;
  final String address;
  final String deliveryNotes;
  final DeliveryStatus status;
  final DateTime? updatedAt;

  /// Read-only packages belonging to this delivery; a status change keeps them.
  final List<Package> packages;

  Delivery withStatus(DeliveryStatus status, DateTime updatedAt) => Delivery(
    id: id,
    customerName: customerName,
    address: address,
    deliveryNotes: deliveryNotes,
    status: status,
    updatedAt: updatedAt,
    packages: packages,
  );
}
