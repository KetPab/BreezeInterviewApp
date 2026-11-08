/*
Purpose of file: Defines the delivery loading and status update contract.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import '../models/delivery.dart';
import '../models/delivery_status.dart';

abstract interface class DeliveryRepository {
  Future<List<Delivery>> getDeliveries();

  /// Returns the saved delivery, including its packages, after storage commits.
  /// Repeating the current status preserves its existing timestamp.
  Future<Delivery> updateStatus(int id, DeliveryStatus status);
}
