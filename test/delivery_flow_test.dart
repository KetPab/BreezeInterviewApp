/*
Purpose of file: Tests queue navigation, status actions, errors, and large text.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'dart:async';

import 'package:breaze_backup/app.dart';
import 'package:breaze_backup/features/deliveries/data/mock_deliveries.dart';
import 'package:breaze_backup/features/deliveries/models/delivery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_delivery_repository.dart';

Future<void> openDelivery(WidgetTester tester, int id) async {
  final row = find.byKey(ValueKey('delivery-$id'));
  await tester.scrollUntilVisible(row, 200);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> tapAction(WidgetTester tester, String key) async {
  final button = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(button, 200);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('details show multiple matching packages and the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(BreazeApp(repository: FakeDeliveryRepository()));
    await tester.pumpAndSettle();
    await openDelivery(tester, 103);
    final delivery = mockDeliveries.firstWhere((d) => d.id == 103);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('delivery-packages')),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.text('Packages (3)'), findsOneWidget);
    for (final package in delivery.packages) {
      await tester.scrollUntilVisible(find.text(package.description), 100);
      await tester.pumpAndSettle();
      expect(find.text('Package #${package.packageID}'), findsOneWidget);
      expect(find.text(package.description), findsOneWidget);
    }
    expect(find.text('Coffee maker'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      BreazeApp(
        repository: FakeDeliveryRepository(
          initial: [
            Delivery(
              id: 201,
              customerName: 'Customer',
              address: 'Address',
              deliveryNotes: '',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openDelivery(tester, 201);
    await tester.scrollUntilVisible(find.text('No packages assigned.'), 100);
    await tester.pumpAndSettle();
    expect(find.text('Packages (0)'), findsOneWidget);
    expect(find.text('No packages assigned.'), findsOneWidget);
  });

  testWidgets('all five queue entries open their matching delivery details', (
    tester,
  ) async {
    await tester.pumpWidget(BreazeApp(repository: FakeDeliveryRepository()));
    await tester.pumpAndSettle();
    for (final delivery in mockDeliveries) {
      await openDelivery(tester, delivery.id);
      expect(find.text('Delivery #${delivery.id}'), findsOneWidget);
      expect(find.text(delivery.customerName), findsOneWidget);
      expect(find.text(delivery.address), findsOneWidget);
      expect(
        find.text(
          delivery.deliveryNotes.isEmpty
              ? 'No delivery notes'
              : delivery.deliveryNotes,
        ),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'Delivered and Failed update details and the matching queue row',
    (tester) async {
      await tester.pumpWidget(BreazeApp(repository: FakeDeliveryRepository()));
      await tester.pumpAndSettle();
      await openDelivery(tester, 101);
      await tapAction(tester, 'mark-delivered');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Delivered'), -200);
      await tester.pumpAndSettle();
      expect(find.text('Delivered'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('mark-delivered')))
            .onPressed,
        isNull,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('delivery-101')),
          matching: find.text('Delivered'),
        ),
        findsOneWidget,
      );
      await openDelivery(tester, 101);
      await tapAction(tester, 'mark-failed');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Failed'), -200);
      await tester.pumpAndSettle();
      expect(find.text('Failed'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('delivery-101')),
          matching: find.text('Failed'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('saving disables actions and finishes after leaving details', (
    tester,
  ) async {
    final repository = FakeDeliveryRepository()..saveGate = Completer<void>();
    await tester.pumpWidget(BreazeApp(repository: repository));
    await tester.pumpAndSettle();
    await openDelivery(tester, 101);
    await tapAction(tester, 'mark-delivered');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('mark-delivered')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('mark-failed')))
          .onPressed,
      isNull,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    repository.saveGate!.complete();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delivered'), -200);
    await tester.pumpAndSettle();
    expect(find.text('Delivered'), findsOneWidget);
  });

  testWidgets('loading, load failure, retry and empty queue are distinct', (
    tester,
  ) async {
    final repository = FakeDeliveryRepository(initial: [])
      ..loadGate = Completer<void>()
      ..failLoad = true;
    await tester.pumpWidget(BreazeApp(repository: repository));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.loadGate!.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load deliveries. Please try again.'),
      findsOneWidget,
    );
    repository.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No deliveries available'), findsOneWidget);
  });

  testWidgets('save error offers recovery without falsely showing success', (
    tester,
  ) async {
    final repository = FakeDeliveryRepository()..failSave = true;
    await tester.pumpWidget(BreazeApp(repository: repository));
    await tester.pumpAndSettle();
    await openDelivery(tester, 101);
    await tapAction(tester, 'mark-failed');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pending'), -200);
    await tester.pumpAndSettle();
    expect(find.text('Pending'), findsOneWidget);
    expect(
      find.text('Could not confirm the update. Reload and try again.'),
      findsOneWidget,
    );
    repository.failSave = false;
    await tester.tap(find.text('Reload deliveries'));
    await tester.pumpAndSettle();
    await tapAction(tester, 'mark-failed');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Failed'), -200);
    await tester.pumpAndSettle();
    expect(find.text('Failed'), findsOneWidget);
  });

  testWidgets('actions remain reachable at 320 dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(BreazeApp(repository: FakeDeliveryRepository()));
    await tester.pumpAndSettle();
    await openDelivery(tester, 104);
    await tapAction(tester, 'mark-delivered');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Delivered'), -200);
    await tester.pumpAndSettle();
    expect(find.text('Delivered'), findsOneWidget);
  });
}
