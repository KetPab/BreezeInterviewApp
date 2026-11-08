/*
Purpose of file: Configures the app theme and shared delivery controller.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/deliveries/data/delivery_repository.dart';
import 'features/deliveries/screens/delivery_queue_screen.dart';
import 'features/deliveries/state/delivery_controller.dart';

class BreazeApp extends StatelessWidget {
  const BreazeApp({required this.repository, super.key});

  final DeliveryRepository repository;

  // Keep the controller above both routes so Back does not cancel a save.
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => DeliveryController(repository)..loadDeliveries(),
    child: MaterialApp(
      title: 'Breaze Backup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        scaffoldBackgroundColor: const Color(0xFFF5F8F7),
        appBarTheme: const AppBarTheme(centerTitle: false),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      ),
      home: const DeliveryQueueScreen(),
    ),
  );
}
