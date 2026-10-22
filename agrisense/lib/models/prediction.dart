class Prediction {
  final bool available;
  final String recommendationType;
  final bool? irrigationNeeded;
  final String urgency;
  final double? confidence;
  final bool isMlBased;
  final String? modelVersion;
  final String title;
  final String message;
  final List<String> explanation;
  final Map<String, dynamic> featuresUsed;
  final DateTime? timestamp;

  Prediction({
    this.available = false,
    this.recommendationType = 'none',
    this.irrigationNeeded,
    this.urgency = 'LOW',
    this.confidence,
    this.isMlBased = false,
    this.modelVersion,
    this.title = 'No Recommendation',
    this.message = 'Awaiting sensor evaluation.',
    this.explanation = const [],
    this.featuresUsed = const {},
    this.timestamp,
  });

  factory Prediction.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Prediction();

    DateTime? ts;
    if (json['timestamp'] != null) {
      try {
        ts = DateTime.parse(json['timestamp'].toString());
      } catch (_) {}
    }

    final rawExpl = json['explanation'] as List<dynamic>?;
    final explList = rawExpl?.map((e) => e.toString()).toList() ?? <String>[];

    return Prediction(
      available: json['available'] == true,
      recommendationType: json['recommendation_type']?.toString() ?? 'none',
      irrigationNeeded: json['irrigation_needed'] as bool?,
      urgency: json['urgency']?.toString() ?? 'LOW',
      confidence: (json['confidence'] as num?)?.toDouble(),
      isMlBased: json['is_ml_based'] == true,
      modelVersion: json['model_version']?.toString(),
      title: json['title']?.toString() ?? 'Recommendation',
      message: json['message']?.toString() ?? '',
      explanation: explList,
      featuresUsed: (json['features_used'] as Map<String, dynamic>?) ?? {},
      timestamp: ts,
    );
  }
}
