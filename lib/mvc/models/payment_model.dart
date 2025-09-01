class PaymentModel {
  final String transactionId;
  final double amount;
  final String packageName;
  final int credit;
  final String status;

  PaymentModel({
    required this.transactionId,
    required this.amount,
    required this.packageName,
    required this.credit,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      transactionId: json['transaction_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      packageName: json['package_name'] ?? '',
      credit: json['credit'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}
