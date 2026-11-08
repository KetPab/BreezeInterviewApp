/*
Purpose of file: Provides controllable in-memory storage for tests.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'dart:async';

import 'package:breaze_backup/features/deliveries/data/delivery_repository.dart';
import 'package:breaze_backup/features/deliveries/data/mock_deliveries.dart';
import 'package:breaze_backup/features/deliveries/models/delivery.dart';
import 'package:breaze_backup/features/deliveries/models/delivery_status.dart';

class FakeDeliveryRepository implements DeliveryRepository {
  FakeDeliveryRepository({List<Delivery>? initial})
    : records = List.of(initial ?? mockDeliveries);

  List<Delivery> records;
  Completer<void>? loadGate;
  Completer<void>? saveGate;
  bool failLoad = false;
  bool failSave = false;
  bool commitBeforeError = false;
  int saveCalls = 0;

  @override
  Future<List<Delivery>> getDeliveries() async {
    if (loadGate case final gate?) await gate.future;
    if (failLoad) throw StateError('Load failed');
    return List.of(records);
  }

  @override
  Future<Delivery> updateStatus(int id, DeliveryStatus status) async {
    saveCalls++;
    if (saveGate case final gate?) await gate.future;
    if (failSave && !commitBeforeError) throw StateError('Save failed');
    final index = records.indexWhere((d) => d.id == id);
    if (index < 0) throw StateError('Delivery not found');
    records[index] = records[index].withStatus(
      status,
      DateTime.utc(2026, 11, 8),
    );
    if (failSave) throw StateError('Confirmation lost');
    return records[index];
  }
}
