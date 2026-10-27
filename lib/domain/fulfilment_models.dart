/// Local delivery information; editing a plan never changes stock or delivered quantities.
class DeliveryPlan {
  const DeliveryPlan({
    required this.orderId,
    required this.carrier,
    required this.trackingNumber,
    required this.notes,
    required this.updatedAt,
    this.expectedDate,
    this.revision = 1,
  });
  final String orderId, carrier, trackingNumber, notes;
  final DateTime updatedAt;
  final DateTime? expectedDate;
  final int revision;
  bool lateAt(DateTime now) =>
      expectedDate != null &&
      DateTime(
        expectedDate!.year,
        expectedDate!.month,
        expectedDate!.day,
      ).isBefore(DateTime(now.year, now.month, now.day));
  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'carrier': carrier,
    'trackingNumber': trackingNumber,
    'notes': notes,
    'expectedDate': expectedDate?.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'revision': revision,
  };
  factory DeliveryPlan.fromJson(Map<String, dynamic> j) => DeliveryPlan(
    orderId: j['orderId'] as String,
    carrier: j['carrier'] as String,
    trackingNumber: j['trackingNumber'] as String,
    notes: j['notes'] as String,
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    expectedDate: j['expectedDate'] == null
        ? null
        : DateTime.parse(j['expectedDate'] as String),
    revision: j['revision'] as int,
  );
}
