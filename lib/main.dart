/*
Purpose of file: Starts Flutter and connects the app to local SQLite storage.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:flutter/material.dart';

import 'app.dart';
import 'features/deliveries/data/sqlite_delivery_repository.dart';

void main() {
  // Initialize Flutter's plugin messaging before SQLite can open a database.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(BreazeApp(repository: SQLiteDeliveryRepository()));
}
