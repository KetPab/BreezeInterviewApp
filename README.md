# Breaze Backup

An offline Flutter delivery companion for the Breaze take-home challenge. **2 screens, 5 fictional deliveries, 9 packages, 3 statuses:** Pending, Delivered and Failed. Android only; all assignment data is bundled locally.

## Run

Tested with Flutter **3.41.1**, Dart **3.11.0**, Java **17**, and an Android **16 / API 36** emulator. Requires an installed Flutter SDK, Android SDK, and a connected Android device or running emulator.

From the project folder:

```bash
flutter pub get
flutter run
```

## Driver flow

The queue shows each customer's name, address and current status. Tap a delivery to see its notes and packages, then choose **Mark Delivered** or **Mark Failed**; returning to the queue shows the updated status. Drivers can correct either completed status, and saved changes survive app restart.

A delivery has a read-only `packages` list. Each `Package` has `packageID`, `description`, and `deliveryID`; the demo has **1–3 packages per delivery**. Status actions apply to the whole delivery, including all its packages.

## Decisions and structure

- **Provider:** one `DeliveryController` above both routes keeps their state consistent. Details receives an ID and looks up the latest delivery.
- **Repository:** screens display data, the controller coordinates actions, and `SQLiteDeliveryRepository` handles persistence. Tests substitute an in-memory repository.
- **SQLite:** two related tables store deliveries and packages. New installations seed the demo once; schema **5** adds packages to existing assignments without resetting their statuses. Foreign keys prevent orphan packages.

`lib/features/deliveries/` contains `models`, `data`, `state`, `screens`, and small reusable `widgets`. `test/` covers models, state and screens; `integration_test/` checks real Android SQLite storage.

## Duplicate taps and crashes

Both actions are disabled during saving; choosing the current status again changes nothing, including its timestamp. SQLite commits before the screen confirms the update: a crash before commit retains the previous status, and a crash after commit restores the saved status on restart. An unconfirmed save requires a successful reload before another attempt.

## Future server synchronization

The repository boundary keeps network logic out of widgets and provides a place to add synchronization. Reliable sync would still need a persistent queue of pending changes, stable request IDs, server acknowledgments and conflict rules. These are not implemented in this local demo.

## A second backup flow

Add a separate feature folder with its own model, controller and repository interface. Reuse shared styling and storage helpers where appropriate, keeping delivery-specific rules inside this feature rather than building a general integration framework now.

## Verify and build

With an Android emulator running as `emulator-5554`:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test/delivery_database_test.dart -d emulator-5554
flutter build apk --debug
```

The final debug build is **1.4.0+5**, requires Android **API 24 or newer**, and is at `build/app/outputs/flutter-apk/app-debug.apk`. Build it after integration tests so the APK uses the app's normal entry point.

Verification on **8 November 2026**: **16 local tests and 3 Android integration tests passed**, formatting passed, and analysis reported **0 issues**. Coverage includes multiple packages, package ownership, status changes, duplicate taps, storage errors, restart persistence, schema upgrades, and **320 dp / 200% text** rendering. Integration tests use a separate test database.

## Limits

Only the latest status is retained. There is no history, package-level status, assignment import, server synchronization or iOS target. Clearing app data or uninstalling removes local records; assignment names, addresses and package descriptions are fictional.
