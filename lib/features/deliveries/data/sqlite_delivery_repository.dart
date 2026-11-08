/*
Purpose of file: Stores deliveries, their packages, and latest statuses in SQLite.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/delivery.dart';
import '../models/delivery_status.dart';
import '../models/package.dart';
import 'delivery_repository.dart';
import 'mock_deliveries.dart';

class SQLiteDeliveryRepository implements DeliveryRepository {
  SQLiteDeliveryRepository({String? databasePath})
    : _databasePath = databasePath;

  final String? _databasePath;
  Future<Database>? _opening;

  Future<Database> _database() => _opening ??= _open();

  Future<Database> _open() async {
    try {
      return await openDatabase(
        _databasePath ??
            path.join(await getDatabasesPath(), 'breaze_backup.db'),
        version: 5,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE deliveries (
              id INTEGER PRIMARY KEY,
              customer_name TEXT NOT NULL,
              address TEXT NOT NULL,
              delivery_notes TEXT NOT NULL,
              status TEXT NOT NULL CHECK (status IN ('pending','delivered','failed')),
              updated_at TEXT
            )
          ''');
          for (final delivery in mockDeliveries) {
            await db.insert('deliveries', {
              'id': delivery.id,
              'customer_name': delivery.customerName,
              'address': delivery.address,
              'delivery_notes': delivery.deliveryNotes,
              'status': delivery.status.storedValue,
              'updated_at': null,
            });
          }
          await _createPackages(db);
        },
        // Schema 5 adds packages while preserving saved delivery statuses.
        onUpgrade: (db, oldVersion, newVersion) => _createPackages(db),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  @override
  Future<List<Delivery>> getDeliveries() async {
    final db = await _database();
    final rows = await db.query('deliveries', orderBy: 'id ASC');
    final packages = await db.query('packages', orderBy: 'package_id ASC');
    return rows
        .map(
          (row) => _delivery(
            row,
            packages.where((package) => package['delivery_id'] == row['id']),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Delivery> updateStatus(int id, DeliveryStatus status) async {
    if (!status.isOutcome) throw ArgumentError('Choose Delivered or Failed.');
    final db = await _database();
    return db.transaction((txn) async {
      final rows = await txn.query(
        'deliveries',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) throw StateError('Delivery $id was not found.');
      final packages = await txn.query(
        'packages',
        where: 'delivery_id = ?',
        whereArgs: [id],
        orderBy: 'package_id ASC',
      );
      final current = _delivery(rows.single, packages);
      // Repeating the same status changes nothing, including its timestamp.
      if (current.status == status) return current;
      final time = DateTime.now().toUtc();
      await txn.update(
        'deliveries',
        {'status': status.storedValue, 'updated_at': time.toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      return current.withStatus(status, time);
    });
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }

  static Future<void> _createPackages(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE packages (
      package_id INTEGER PRIMARY KEY,
      description TEXT NOT NULL,
      delivery_id INTEGER NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE
    )''');
    // Upgrades may contain only a subset of the demo's delivery IDs.
    final existing = (await db.query(
      'deliveries',
      columns: ['id'],
    )).map((row) => row['id']).toSet();
    for (final delivery in mockDeliveries) {
      if (!existing.contains(delivery.id)) continue;
      for (final package in delivery.packages) {
        await db.insert('packages', {
          'package_id': package.packageID,
          'description': package.description,
          'delivery_id': package.deliveryID,
        });
      }
    }
  }

  static Delivery _delivery(
    Map<String, Object?> row,
    Iterable<Map<String, Object?>> packages,
  ) => Delivery(
    id: row['id'] as int,
    customerName: row['customer_name'] as String,
    address: row['address'] as String,
    deliveryNotes: row['delivery_notes'] as String,
    status: DeliveryStatus.fromStorage(row['status'] as String),
    packages: packages
        .map(
          (package) => Package(
            packageID: package['package_id'] as int,
            description: package['description'] as String,
            deliveryID: package['delivery_id'] as int,
          ),
        )
        .toList(growable: false),
    updatedAt: row['updated_at'] == null
        ? null
        : DateTime.parse(row['updated_at'] as String).toUtc(),
  );
}
