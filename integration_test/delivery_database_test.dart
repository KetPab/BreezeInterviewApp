/*
Purpose of file: Tests package persistence, status updates, and package schema upgrades.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:breaze_backup/features/deliveries/data/sqlite_delivery_repository.dart';
import 'package:breaze_backup/features/deliveries/data/mock_deliveries.dart';
import 'package:breaze_backup/features/deliveries/models/delivery_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late String databasePath;
  late SQLiteDeliveryRepository repository;

  setUp(() async {
    databasePath = path.join(await getDatabasesPath(), 'breaze_scope_test.db');
    await deleteDatabase(databasePath);
    repository = SQLiteDeliveryRepository(databasePath: databasePath);
  });
  tearDown(() async {
    await repository.close();
    await deleteDatabase(databasePath);
  });

  testWidgets('seeds five assignments; both statuses survive database reopen', (
    tester,
  ) async {
    final initial = await repository.getDeliveries();
    expect(initial, hasLength(5));
    expect(initial.map((d) => d.packages.length), [2, 1, 3, 2, 1]);
    expect(initial.every((d) => d.status == DeliveryStatus.pending), isTrue);
    await repository.updateStatus(101, DeliveryStatus.delivered);
    await repository.updateStatus(102, DeliveryStatus.failed);
    await repository.close();
    final restored = await repository.getDeliveries();
    expect(restored[0].status, DeliveryStatus.delivered);
    expect(restored[1].status, DeliveryStatus.failed);
    expect(
      restored.skip(2).every((d) => d.status == DeliveryStatus.pending),
      isTrue,
    );
    expect(restored.first.address, initial.first.address);
    for (var i = 0; i < restored.length; i++) {
      expect(
        restored[i].packages.map(
          (p) => (p.packageID, p.description, p.deliveryID),
        ),
        mockDeliveries[i].packages.map(
          (p) => (p.packageID, p.description, p.deliveryID),
        ),
      );
    }
  });

  testWidgets(
    'repeated status preserves timestamp; corrections work; unknown IDs fail',
    (tester) async {
      final first = await repository.updateStatus(
        101,
        DeliveryStatus.delivered,
      );
      final repeated = await repository.updateStatus(
        101,
        DeliveryStatus.delivered,
      );
      expect(repeated.updatedAt, first.updatedAt);
      expect(first.packages, hasLength(2));
      expect(repeated.packages, hasLength(2));
      expect(
        (await repository.updateStatus(101, DeliveryStatus.failed)).status,
        DeliveryStatus.failed,
      );
      await expectLater(
        repository.updateStatus(999, DeliveryStatus.failed),
        throwsStateError,
      );
      await expectLater(
        repository.updateStatus(101, DeliveryStatus.pending),
        throwsArgumentError,
      );
      expect(await repository.getDeliveries(), hasLength(5));
    },
  );

  testWidgets(
    'version 4 upgrade adds packages once and enforces delivery ownership',
    (tester) async {
      final db = await openDatabase(
        databasePath,
        version: 4,
        onCreate: (db, version) async {
          await db.execute(
            '''CREATE TABLE deliveries (
        id INTEGER PRIMARY KEY, customer_name TEXT NOT NULL, address TEXT NOT NULL,
        delivery_notes TEXT NOT NULL, status TEXT NOT NULL, updated_at TEXT)''',
          );
          await db.insert('deliveries', {
            'id': 103,
            'customer_name': 'Existing customer',
            'address': 'Existing address',
            'delivery_notes': '',
            'status': 'failed',
            'updated_at': '2026-11-08T12:00:00.000Z',
          });
        },
      );
      await db.close();
      final restored = (await repository.getDeliveries()).single;
      expect(restored.status, DeliveryStatus.failed);
      expect(restored.customerName, 'Existing customer');
      expect(restored.packages.map((p) => p.packageID), [1004, 1005, 1006]);
      await repository.close();
      expect((await repository.getDeliveries()).single.packages, hasLength(3));
      final inspection = await openDatabase(databasePath);
      await expectLater(
        inspection.insert('packages', {
          'package_id': 9999,
          'description': 'Orphan package',
          'delivery_id': 999,
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );
}
