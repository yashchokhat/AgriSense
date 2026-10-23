import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/agronomy_provider.dart';
import '../widgets/soil_test_editor_dialog.dart';
import '../widgets/live_iot_metrics_bar.dart';
import '../widgets/crop_hero_card.dart';
import '../widgets/environmental_match_chart.dart';
import '../widgets/crop_alternatives_chart.dart';
import '../widgets/fertilizer_action_card.dart';
import '../widgets/soil_test_quick_bar.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Crop & Soil Advisory',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Soil Test (NPK/pH)',
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
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing IoT sensors & soil data...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
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
            color: AppColors.primary,
            onRefresh: () => provider.fetchAdvisory(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live IoT Sensors (Moisture, Temp, Humidity)
                  LiveIoTMetricsBar(
                    environment: env,
                    isLiveIot: isLiveIot,
                  ),
                  const SizedBox(height: 12),

                  // 2. Best Crop for Land (ML Hero Card)
                  if (crop != null) ...[
                    CropHeroCard(crop: crop),
                    const SizedBox(height: 14),

                    // 3. Sensor vs Crop Range Chart (fl_chart)
                    if (crop.factorsAnalysis.isNotEmpty) ...[
                      EnvironmentalMatchChart(factors: crop.factorsAnalysis),
                      const SizedBox(height: 14),
                    ],
                  ],

                  // 4. Recommended Fertilizer Action Card
                  if (fert != null) ...[
                    FertilizerActionCard(fert: fert),
                    const SizedBox(height: 14),
                  ],

                  // 5. Active Soil Test Quick Bar (NPK & pH)
                  SoilTestQuickBar(
                    soil: soil,
                    onEdit: () => _openSoilEditor(context, provider),
                  ),
                  const SizedBox(height: 14),

                  // 6. Alternative Crop Matches Bar Chart
                  if (crop != null && crop.alternatives.isNotEmpty) ...[
                    CropAlternativesChart(alternatives: crop.alternatives),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
