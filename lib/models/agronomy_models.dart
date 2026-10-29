class SoilProfile {
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double ph;
  final double rainfallMm;
  final String soilType;
  final String targetCrop;
  final bool isManuallyEntered;

  const SoilProfile({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ph,
    required this.rainfallMm,
    required this.soilType,
    required this.targetCrop,
    this.isManuallyEntered = false,
  });

  factory SoilProfile.defaults() {
    return const SoilProfile(
      nitrogen: 50.0,
      phosphorus: 40.0,
      potassium: 40.0,
      ph: 6.5,
      rainfallMm: 100.0,
      soilType: 'Loamy',
      targetCrop: 'Maize',
      isManuallyEntered: false,
    );
  }

  factory SoilProfile.fromJson(Map<String, dynamic> json) {
    return SoilProfile(
      nitrogen: (json['nitrogen'] as num?)?.toDouble() ?? 50.0,
      phosphorus: (json['phosphorus'] as num?)?.toDouble() ?? 40.0,
      potassium: (json['potassium'] as num?)?.toDouble() ?? 40.0,
      ph: (json['ph'] as num?)?.toDouble() ?? 6.5,
      rainfallMm: (json['rainfall_mm'] as num?)?.toDouble() ?? 100.0,
      soilType: json['soil_type'] as String? ?? 'Loamy',
      targetCrop: json['target_crop'] as String? ?? 'Maize',
      isManuallyEntered: json['is_manually_entered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'ph': ph,
      'rainfall_mm': rainfallMm,
      'soil_type': soilType,
      'target_crop': targetCrop,
      'is_manually_entered': isManuallyEntered,
    };
  }

  SoilProfile copyWith({
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? ph,
    double? rainfallMm,
    String? soilType,
    String? targetCrop,
    bool? isManuallyEntered,
  }) {
    return SoilProfile(
      nitrogen: nitrogen ?? this.nitrogen,
      phosphorus: phosphorus ?? this.phosphorus,
      potassium: potassium ?? this.potassium,
      ph: ph ?? this.ph,
      rainfallMm: rainfallMm ?? this.rainfallMm,
      soilType: soilType ?? this.soilType,
      targetCrop: targetCrop ?? this.targetCrop,
      isManuallyEntered: isManuallyEntered ?? this.isManuallyEntered,
    );
  }
}

class FactorAnalysis {
  final String parameter;
  final String current;
  final String idealRange;
  final String status;
  final bool isFavorable;
  final double? currentNum;
  final double? idealMin;
  final double? idealMax;
  final String? unit;

  const FactorAnalysis({
    required this.parameter,
    required this.current,
    required this.idealRange,
    required this.status,
    required this.isFavorable,
    this.currentNum,
    this.idealMin,
    this.idealMax,
    this.unit,
  });

  factory FactorAnalysis.fromJson(Map<String, dynamic> json) {
    return FactorAnalysis(
      parameter: json['parameter'] as String? ?? '',
      current: json['current'] as String? ?? '',
      idealRange: json['ideal_range'] as String? ?? '',
      status: json['status'] as String? ?? 'OPTIMAL',
      isFavorable: json['is_favorable'] as bool? ?? true,
      currentNum: (json['current_num'] as num?)?.toDouble(),
      idealMin: (json['ideal_min'] as num?)?.toDouble(),
      idealMax: (json['ideal_max'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );
  }
}

class CropAlternative {
  final String crop;
  final String displayName;
  final String category;
  final double suitabilityPercent;
  final String farmerTip;

  const CropAlternative({
    required this.crop,
    required this.displayName,
    this.category = 'Crop',
    required this.suitabilityPercent,
    required this.farmerTip,
  });

  factory CropAlternative.fromJson(Map<String, dynamic> json) {
    return CropAlternative(
      crop: json['crop'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      category: json['category'] as String? ?? 'Crop',
      suitabilityPercent: (json['suitability_percent'] as num?)?.toDouble() ?? 0.0,
      farmerTip: json['farmer_tip'] as String? ?? '',
    );
  }
}

class CropRecommendation {
  final bool available;
  final String recommendedCrop;
  final String displayName;
  final String category;
  final double confidence;
  final double suitabilityPercent;
  final String description;
  final String farmerTip;
  final String idealSoil;
  final List<CropAlternative> alternatives;
  final List<FactorAnalysis> factorsAnalysis;

  const CropRecommendation({
    required this.available,
    required this.recommendedCrop,
    required this.displayName,
    this.category = 'Field Crop',
    required this.confidence,
    required this.suitabilityPercent,
    required this.description,
    required this.farmerTip,
    required this.idealSoil,
    required this.alternatives,
    required this.factorsAnalysis,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    final alts = (json['alternatives'] as List<dynamic>?)
            ?.map((e) => CropAlternative.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final factors = (json['factors_analysis'] as List<dynamic>?)
            ?.map((e) => FactorAnalysis.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CropRecommendation(
      available: json['available'] as bool? ?? false,
      recommendedCrop: json['recommended_crop'] as String? ?? 'maize',
      displayName: json['display_name'] as String? ?? 'Maize (Corn)',
      category: json['category'] as String? ?? 'Field Crop',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      suitabilityPercent: (json['suitability_percent'] as num?)?.toDouble() ?? 85.0,
      description: json['description'] as String? ?? '',
      farmerTip: json['farmer_tip'] as String? ?? '',
      idealSoil: json['ideal_soil'] as String? ?? 'Loamy',
      alternatives: alts,
      factorsAnalysis: factors,
    );
  }
}

class FertilizerRecommendation {
  final bool available;
  final String recommendedFertilizer;
  final String displayName;
  final String npkGrade;
  final String primaryNutrient;
  final double confidencePercent;
  final String recommendedDosage;
  final String description;
  final String applicationGuide;
  final String caution;
  final Map<String, dynamic> deficiencyAnalysis;

  const FertilizerRecommendation({
    required this.available,
    required this.recommendedFertilizer,
    required this.displayName,
    required this.npkGrade,
    required this.primaryNutrient,
    required this.confidencePercent,
    required this.recommendedDosage,
    required this.description,
    required this.applicationGuide,
    required this.caution,
    required this.deficiencyAnalysis,
  });

  factory FertilizerRecommendation.fromJson(Map<String, dynamic> json) {
    return FertilizerRecommendation(
      available: json['available'] as bool? ?? false,
      recommendedFertilizer: json['recommended_fertilizer'] as String? ?? 'Urea',
      displayName: json['display_name'] as String? ?? 'Urea (46-0-0)',
      npkGrade: json['npk_grade'] as String? ?? '46% N',
      primaryNutrient: json['primary_nutrient'] as String? ?? 'Nitrogen',
      confidencePercent: (json['confidence_percent'] as num?)?.toDouble() ?? 90.0,
      recommendedDosage: json['recommended_dosage'] as String? ?? '45-50 kg / acre',
      description: json['description'] as String? ?? '',
      applicationGuide: json['application_guide'] as String? ?? '',
      caution: json['caution'] as String? ?? '',
      deficiencyAnalysis: (json['deficiency_analysis'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class AgronomyAdvisory {
  final String timestamp;
  final Map<String, dynamic> telemetrySource;
  final Map<String, dynamic> environment;
  final SoilProfile soilProfile;
  final CropRecommendation cropRecommendation;
  final FertilizerRecommendation fertilizerRecommendation;

  const AgronomyAdvisory({
    required this.timestamp,
    required this.telemetrySource,
    required this.environment,
    required this.soilProfile,
    required this.cropRecommendation,
    required this.fertilizerRecommendation,
  });

  factory AgronomyAdvisory.fromJson(Map<String, dynamic> json) {
    return AgronomyAdvisory(
      timestamp: json['timestamp'] as String? ?? '',
      telemetrySource: (json['telemetry_source'] as Map<String, dynamic>?) ?? {},
      environment: (json['environment'] as Map<String, dynamic>?) ?? {},
      soilProfile: SoilProfile.fromJson((json['soil_profile'] as Map<String, dynamic>?) ?? {}),
      cropRecommendation: CropRecommendation.fromJson((json['crop_recommendation'] as Map<String, dynamic>?) ?? {}),
      fertilizerRecommendation: FertilizerRecommendation.fromJson((json['fertilizer_recommendation'] as Map<String, dynamic>?) ?? {}),
    );
  }
}
