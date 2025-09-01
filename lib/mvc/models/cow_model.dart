class CowModel {
  final double weight;
  final String breed;
  final int creditsRemaining;
  final String processedImage;
  final Map<String, dynamic> keypoints;

  CowModel({
    required this.weight,
    required this.breed,
    required this.creditsRemaining,
    required this.processedImage,
    required this.keypoints,
  });

  factory CowModel.fromJson(Map<String, dynamic> json) {
    return CowModel(
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      breed: json['breed'] ?? 'Unknown',
      creditsRemaining: json['credits_remaining'] ?? 0,
      processedImage: json['processed_image'] ?? '',
      keypoints: json['keypoints'] ?? {},
    );
  }
}
