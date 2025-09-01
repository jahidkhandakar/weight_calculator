class PackageModel {
  final int id;
  final String name;
  final int credit;
  final String price;
  final String description;

  PackageModel({
    required this.id,
    required this.name,
    required this.credit,
    required this.price,
    required this.description,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      name: json['name'] ?? '',
      credit: json['credit'] ?? 0,
      price: json['price'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
