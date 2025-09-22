class PaymentHistoryModel {
  final int id;
  final String uuid;
  final String packageName;
  final String amount;
  final String status;
  final DateTime createdAt;

  PaymentHistoryModel({
    required this.id,
    required this.uuid,
    required this.packageName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: json['id'] as int,
      uuid: json['uuid'] ?? '',
      packageName: json['package_name'] ?? '',
      amount: json['amount'] ?? '0.00',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
