class CowInfo {
  final double weight;
  final String breed;

  CowInfo({required this.weight, required this.breed});

  factory CowInfo.fromJson(Map<String, dynamic> json) {
    return CowInfo(
      weight: (json['weight'] as num).toDouble(),
      breed: json['breed'] ?? 'Unknown',
    );
  }
}
