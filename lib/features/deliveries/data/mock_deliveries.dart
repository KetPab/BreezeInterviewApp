/*
Purpose of file: Provides five fictional deliveries and nine packages for a new installation.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

import '../models/delivery.dart';
import '../models/package.dart';

/// Fictional assignments used only when creating a new database.
final mockDeliveries = List<Delivery>.unmodifiable([
  Delivery(
    id: 101,
    packages: const [
      Package(
        packageID: 1001,
        description: 'Box of kitchen utensils',
        deliveryID: 101,
      ),
      Package(
        packageID: 1002,
        description: 'Set of dinner plates',
        deliveryID: 101,
      ),
    ],
    customerName: 'Naledi Mokoena',
    address: '12 Acacia Lane, Rosebank, Johannesburg, 2196',
    deliveryNotes: 'Use the pedestrian gate. Ring the bell on arrival.',
  ),
  Delivery(
    id: 102,
    packages: const [
      Package(
        packageID: 1003,
        description: 'Pair of running shoes',
        deliveryID: 102,
      ),
    ],
    customerName: 'Thabo Dlamini',
    address: '48 Jacaranda Street, Hatfield, Pretoria, 0083',
    deliveryNotes: 'Leave with reception and ask for Thabo.',
  ),
  Delivery(
    id: 103,
    packages: const [
      Package(packageID: 1004, description: 'Books', deliveryID: 103),
      Package(packageID: 1005, description: 'Desk lamp', deliveryID: 103),
      Package(packageID: 1006, description: 'Notebook set', deliveryID: 103),
    ],
    customerName: 'Ayesha Daniels',
    address: '7 Harbour View Road, Green Point, Cape Town, 8005',
    deliveryNotes: '',
  ),
  Delivery(
    id: 104,
    packages: const [
      Package(packageID: 1007, description: 'Bedding set', deliveryID: 104),
      Package(packageID: 1008, description: 'Bath towels', deliveryID: 104),
    ],
    customerName: 'Sipho Khumalo',
    address: 'Unit 14, 26 Coral Crescent, Umhlanga Ridge, Durban, 4319',
    deliveryNotes: 'Security will direct you to unit 14. Do not leave outside.',
  ),
  Delivery(
    id: 105,
    packages: const [
      Package(packageID: 1009, description: 'Coffee maker', deliveryID: 105),
    ],
    customerName: 'Lerato Molefe',
    address: '93 Wild Olive Avenue, Langenhoven Park, Bloemfontein, 9301',
    deliveryNotes: 'The entrance is on the side street.',
  ),
]);
