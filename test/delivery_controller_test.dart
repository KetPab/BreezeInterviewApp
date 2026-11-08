/*
Purpose of file: Tests shared state, duplicate taps, status changes, and recovery.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'dart:async';

import 'package:breaze_backup/features/deliveries/models/delivery_status.dart';
import 'package:breaze_backup/features/deliveries/state/delivery_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_delivery_repository.dart';

void main() {
  late FakeDeliveryRepository repository;
  late DeliveryController controller;
  setUp(() {
    repository = FakeDeliveryRepository();
    controller = DeliveryController(repository);
    addTearDown(controller.dispose);
  });

  test(
    'loads five immutable assignments and changes only the selected one',
    () async {
      await controller.loadDeliveries();
      expect(controller.deliveries.map((d) => d.id), [101, 102, 103, 104, 105]);
      expect(() => controller.deliveries.clear(), throwsUnsupportedError);
      await controller.markDelivered(104);
      expect(controller.deliveryById(104)!.status, DeliveryStatus.delivered);
      expect(
        controller.deliveries
            .where((d) => d.id != 104)
            .every((d) => d.status == DeliveryStatus.pending),
        isTrue,
      );
    },
  );

  test(
    'duplicate taps during and after saving make one storage call',
    () async {
      await controller.loadDeliveries();
      repository.saveGate = Completer<void>();
      final save = controller.markDelivered(101);
      await controller.markDelivered(101);
      await controller.markFailed(101);
      expect(repository.saveCalls, 1);
      expect(controller.deliveryById(101)!.status, DeliveryStatus.pending);
      repository.saveGate!.complete();
      await save;
      await controller.markDelivered(101);
      expect(repository.saveCalls, 1);
      expect(controller.deliveryById(101)!.status, DeliveryStatus.delivered);
    },
  );

  test('a driver can correct either completed status', () async {
    await controller.loadDeliveries();
    await controller.markFailed(101);
    expect(controller.deliveryById(101)!.status, DeliveryStatus.failed);
    await controller.markDelivered(101);
    expect(controller.deliveryById(101)!.status, DeliveryStatus.delivered);
    await controller.markFailed(101);
    expect(controller.deliveryById(101)!.status, DeliveryStatus.failed);
  });

  test('initial load failure can be retried', () async {
    repository.failLoad = true;
    await controller.loadDeliveries();
    expect(controller.loadError, isNotNull);
    repository.failLoad = false;
    await controller.retryLoad();
    expect(controller.loadError, isNull);
    expect(controller.deliveries, hasLength(5));
  });

  test(
    'uncertain save blocks retries until reload discovers committed state',
    () async {
      await controller.loadDeliveries();
      repository.failSave = true;
      repository.commitBeforeError = true;
      await controller.markDelivered(101);
      expect(controller.deliveryById(101)!.status, DeliveryStatus.pending);
      expect(controller.errorFor(101), isNotNull);
      await controller.markDelivered(101);
      expect(repository.saveCalls, 1);
      repository.failLoad = true;
      await controller.retryLoad();
      expect(controller.canRecord(101), isFalse);
      repository.failLoad = false;
      await controller.retryLoad();
      expect(controller.deliveryById(101)!.status, DeliveryStatus.delivered);
      expect(controller.errorFor(101), isNull);
    },
  );

  test('reload waits for active writes and blocks new saves', () async {
    await controller.loadDeliveries();
    repository.saveGate = Completer<void>();
    final save = controller.markDelivered(101);
    final reload = controller.retryLoad();
    await controller.markFailed(102);
    expect(repository.saveCalls, 1);
    repository.saveGate!.complete();
    await Future.wait([save, reload]);
    expect(controller.deliveryById(101)!.status, DeliveryStatus.delivered);
  });

  test(
    'unknown IDs do not write and disposal allows active save to finish',
    () async {
      final separate = DeliveryController(repository);
      await separate.loadDeliveries();
      await separate.markDelivered(999);
      expect(repository.saveCalls, 0);
      repository.saveGate = Completer<void>();
      final save = separate.markDelivered(101);
      separate.dispose();
      repository.saveGate!.complete();
      await save;
      expect(repository.records.first.status, DeliveryStatus.delivered);
    },
  );
}
