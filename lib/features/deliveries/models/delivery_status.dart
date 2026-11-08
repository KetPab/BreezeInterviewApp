/*
Purpose of file: Defines delivery statuses and their display and storage values.
Last edited by: Ketsile Dikobe
Last edit date: 08 November 2026
*/

enum DeliveryStatus {
  pending,
  delivered,
  failed;

  // Explicit strings keep stored statuses stable if enum values are reordered.
  String get storedValue => switch (this) {
    pending => 'pending',
    delivered => 'delivered',
    failed => 'failed',
  };

  String get label => switch (this) {
    pending => 'Pending',
    delivered => 'Delivered',
    failed => 'Failed',
  };

  bool get isOutcome => this != pending;

  static DeliveryStatus fromStorage(String value) => switch (value) {
    'pending' => pending,
    'delivered' => delivered,
    'failed' => failed,
    _ => throw FormatException('Unknown delivery status: $value'),
  };
}
