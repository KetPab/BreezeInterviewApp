/*
Purpose of file: Coordinates shared delivery state, guarded saves, and error recovery.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/delivery_repository.dart';
import '../models/delivery.dart';
import '../models/delivery_status.dart';

class DeliveryController extends ChangeNotifier {
  DeliveryController(this._repository);

  final DeliveryRepository _repository;
  List<Delivery> _deliveries = const [];
  final Map<int, Future<void>> _writes = {};
  final Map<int, String> _errors = {};
  final Set<int> _unresolvedIds = {};
  Future<void>? _loadFuture;
  bool _disposed = false;
  bool _hasLoaded = false;
  String? _loadError;

  List<Delivery> get deliveries => _deliveries;
  bool get isLoading => _loadFuture != null;
  bool get hasLoaded => _hasLoaded;
  String? get loadError => _loadError;
  bool isSaving(int id) => _writes.containsKey(id);
  bool needsReload(int id) => _unresolvedIds.contains(id);
  String? errorFor(int id) => _errors[id];
  Delivery? deliveryById(int id) {
    for (final delivery in _deliveries) {
      if (delivery.id == id) return delivery;
    }
    return null;
  }

  bool canRecord(int id) =>
      !_disposed &&
      !isLoading &&
      !isSaving(id) &&
      !needsReload(id) &&
      deliveryById(id) != null;

  Future<void> loadDeliveries() {
    if (_disposed) return Future.value();
    if (_loadFuture case final loading?) return loading;
    final completion = Completer<void>();
    _loadFuture = completion.future;
    _loadError = null;
    _publish();
    unawaited(_load(completion));
    return completion.future;
  }

  Future<void> _load(Completer<void> completion) async {
    try {
      // Loading blocks new actions; finish active saves before replacing state.
      await Future.wait(_writes.values.toList());
      if (_disposed) return;
      final records = await _repository.getDeliveries();
      if (_disposed) return;
      _deliveries = List.unmodifiable(records);
      _hasLoaded = true;
      _errors.clear();
      _unresolvedIds.clear();
    } catch (_) {
      if (!_disposed) {
        _loadError = 'Could not load deliveries. Please try again.';
      }
    } finally {
      _loadFuture = null;
      _publish();
      completion.complete();
    }
  }

  Future<void> retryLoad() => loadDeliveries();

  Future<void> markDelivered(int id) => _record(id, DeliveryStatus.delivered);
  Future<void> markFailed(int id) => _record(id, DeliveryStatus.failed);

  Future<void> _record(int id, DeliveryStatus status) {
    if (!canRecord(id) || deliveryById(id)!.status == status) {
      return Future.value();
    }
    final completion = Completer<void>();
    // Register before any await: duplicate taps must not open parallel saves.
    _writes[id] = completion.future;
    _errors.remove(id);
    _publish();
    unawaited(_save(id, status, completion));
    return completion.future;
  }

  Future<void> _save(
    int id,
    DeliveryStatus status,
    Completer<void> completion,
  ) async {
    try {
      final updated = await _repository.updateStatus(id, status);
      if (_disposed) return;
      _replace(updated);
    } catch (_) {
      if (!_disposed) {
        _errors[id] = 'Could not confirm the update. Reload and try again.';
        // The write may have committed even if its acknowledgment was lost.
        _unresolvedIds.add(id);
      }
    } finally {
      _writes.remove(id);
      _publish();
      completion.complete();
    }
  }

  void _replace(Delivery updated) {
    _deliveries = List.unmodifiable([
      for (final d in _deliveries)
        if (d.id == updated.id) updated else d,
    ]);
  }

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
