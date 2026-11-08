/*
Purpose of file: Represents one package assigned to a delivery.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

class Package {
  const Package({
    required this.packageID,
    required this.description,
    required this.deliveryID,
  });

  final int packageID;
  final String description;

  /// The ID of the delivery containing this package.
  final int deliveryID;
}
