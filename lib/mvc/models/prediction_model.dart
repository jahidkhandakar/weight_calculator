class PredictionModel {
  final double weight;
  final double confidence;

  PredictionModel({required this.weight, required this.confidence});

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      weight: double.tryParse(json['weight'].toString()) ?? 0.0,
      confidence: double.tryParse(json['confidence'].toString()) ?? 0.0,
    );
  }
}
