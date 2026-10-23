import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/agronomy_provider.dart';
import '../../../models/agronomy_models.dart';
import '../widgets/soil_test_editor_dialog.dart';

class AgronomyScreen extends StatelessWidget {
  const AgronomyScreen({super.key});

  void _openSoilEditor(BuildContext context, AgronomyProvider provider) {
    showDialog(
      context: context,
      builder: (_) => SoilTestEditorDialog(
        currentProfile: provider.soilProfile,
        onSave: (updated) => provider.updateSoilProfile(updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop & Fertilizer Advisory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Enter Soil Test Report',
            onPressed: () => _openSoilEditor(context, context.read<AgronomyProvider>()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Advisory',
            onPressed: () => context.read<AgronomyProvider>().fetchAdvisory(),
          ),
        ],
      ),
      body: Consumer<AgronomyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.advisory == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing soil & IoT weather parameters...',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          final advisory = provider.advisory;
          final soil = provider.soilProfile;
          final crop = advisory?.cropRecommendation;
          final fert = advisory?.fertilizerRecommendation;
          final env = advisory?.environment ?? {};
          final isLiveIot = advisory?.telemetrySource['is_live_iot'] == true;

          return RefreshIndicator(
            onRefresh: () => provider.fetchAdvisory(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live IoT Status Banner
                  _buildIoTSourceBanner(env, isLiveIot),
                  const SizedBox(height: 12),

                  // Soil Test Card (NPK & pH manual input)
                  _buildSoilHealthCard(context, provider, soil),
                  const SizedBox(height: 16),

                  // Best Crop for Land Card (ML Prediction)
                  if (crop != null) _buildBestCropCard(crop),
                  const SizedBox(height: 16),

                  // Fertilizer Recommendation Card (ML Prediction)
                  if (fert != null) _buildFertilizerCard(fert),
                  const SizedBox(height: 16),

                  // Alternatives & Factor Analysis
                  if (crop != null && crop.alternatives.isNotEmpty)
                    _buildAlternativesSection(crop.alternatives),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIoTSourceBanner(Map<String, dynamic> env, bool isLive) {
    final temp = env['temperature_c'] ?? 28.0;
    final hum = env['humidity_percent'] ?? 60.0;
    final moist = env['soil_moisture_estimate_percent'] ?? 40.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLive ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive ? Colors.green.shade300 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.sensors_rounded : Icons.cloud_queue_rounded,
            color: isLive ? Colors.green.shade700 : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isLive ? 'LIVE ESP32 TELEMETRY' : 'REAL-TIME DATA STREAM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLive ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Temp: $temp°C • Hum: $hum% • Soil: $moist%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isLive
                      ? 'Ambient temperature, humidity and soil moisture streamed live from field sensors.'
                      : 'Telemetry synced with cloud Realtime Database.',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilHealthCard(BuildContext context, AgronomyProvider provider, SoilProfile soil) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.terrain_rounded, color: Colors.teal.shade700, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Soil Health & Nutrients',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        soil.isManuallyEntered
                            ? 'Source: Lab Report / Manual Input'
                            : 'Source: Backend Agronomic Baseline',
                        style: TextStyle(
                          fontSize: 11,
                          color: soil.isManuallyEntered ? Colors.teal.shade700 : AppColors.textMuted,
                          fontWeight: soil.isManuallyEntered ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openSoilEditor(context, provider),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Edit NPK/pH', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // N-P-K-pH Metrics Grid
            Row(
              children: [
                _buildNutrientTile('Nitrogen (N)', '${soil.nitrogen.toStringAsFixed(0)} kg/ha', Colors.blue.shade700),
                _buildNutrientTile('Phosphorus (P)', '${soil.phosphorus.toStringAsFixed(0)} kg/ha', Colors.deepOrange.shade700),
                _buildNutrientTile('Potassium (K)', '${soil.potassium.toStringAsFixed(0)} kg/ha', Colors.purple.shade700),
                _buildNutrientTile('Soil pH', soil.ph.toStringAsFixed(1), Colors.teal.shade700),
              ],
            ),
            const SizedBox(height: 8),

            // Soil Type and Rain Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Soil Type: ${soil.soilType}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('Target Crop: ${soil.targetCrop}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('Rain: ${soil.rainfallMm.toStringAsFixed(0)}mm', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientTile(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBestCropCard(CropRecommendation crop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200, width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber.shade900),
                      const SizedBox(width: 4),
                      Text(
                        'BEST CROP FOR YOUR LAND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    '${crop.suitabilityPercent.toStringAsFixed(1)}% Suitability',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Crop Name & Icon
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Icon(Icons.agriculture_rounded, color: Colors.green.shade700, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.displayName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      Text(
                        'Ideal in: ${crop.idealSoil}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Farmer Tip Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.lightGreen.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.lightGreen.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_rounded, color: Colors.green.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      crop.farmerTip,
                      style: TextStyle(fontSize: 12, color: Colors.green.shade900, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Factor Analysis Chips
            const Text('Environmental & Soil Match:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: crop.factorsAnalysis.map((f) {
                final isOk = f.isFavorable;
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  backgroundColor: isOk ? Colors.green.shade50 : Colors.orange.shade50,
                  side: BorderSide(color: isOk ? Colors.green.shade200 : Colors.orange.shade200),
                  avatar: Icon(
                    isOk ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: isOk ? Colors.green.shade700 : Colors.orange.shade700,
                    size: 14,
                  ),
                  label: Text(
                    '${f.parameter}: ${f.current} (${f.status})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isOk ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilizerCard(FertilizerRecommendation fert) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade300, width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 14, color: Colors.deepOrange.shade800),
                      const SizedBox(width: 4),
                      Text(
                        'FERTILIZER ADVISORY (ML)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${fert.confidencePercent.toStringAsFixed(1)}% Match',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fertilizer Name
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Icon(Icons.eco_rounded, color: Colors.orange.shade800, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fert.displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Grade: ${fert.npkGrade}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recommended Dosage
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.scale_rounded, color: Colors.deepOrange, size: 18),
                  const SizedBox(width: 8),
                  const Text('Recommended Dosage: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Text(
                      fert.recommendedDosage,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Application Guide
            Text(
              fert.applicationGuide,
              style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
            ),

            if (fert.caution.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fert.caution,
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativesSection(List<CropAlternative> alternatives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Viable Crop Alternatives:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: alternatives.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final alt = alternatives[index];
              return Container(
                width: 170,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.grass_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alt.displayName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alt.suitabilityPercent.toStringAsFixed(1)}% Match',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        alt.farmerTip,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
