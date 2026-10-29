import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/agronomy_provider.dart';

class WeatherPlaygroundWidget extends StatelessWidget {
  const WeatherPlaygroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AgronomyProvider>(
      builder: (context, provider, _) {
        final isSim = provider.isSimulationMode;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: isSim ? const Color(0xFF8B5CF6).withAlpha(100) : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Mode Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSim ? const Color(0xFFF3E8FF) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSim ? Icons.tune_rounded : Icons.sensors_rounded,
                        color: isSim ? const Color(0xFF7C3AED) : const Color(0xFF059669),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSim ? 'WEATHER & SENSOR SIMULATOR' : 'LIVE FIELD SENSOR STREAM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isSim ? const Color(0xFF6D28D9) : const Color(0xFF065F46),
                            ),
                          ),
                          Text(
                            isSim
                                ? 'Adjust sliders to see crop predictions change in real time'
                                : 'Telemetry streaming live from ESP32 field sensors',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isSim,
                      activeColor: const Color(0xFF7C3AED),
                      onChanged: (val) => provider.toggleSimulationMode(val),
                    ),
                  ],
                ),
              ),

              // Expanded Slider Controls when Simulator Mode is Active
              if (isSim) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Weather Presets
                      const Text(
                        'Quick Climate Scenarios:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPresetChip(
                              context,
                              provider,
                              label: '❄️ Cool Season (16°C)',
                              key: 'cool_winter',
                            ),
                            const SizedBox(width: 8),
                            _buildPresetChip(
                              context,
                              provider,
                              label: '☀️ Hot & Arid (34°C)',
                              key: 'hot_summer',
                            ),
                            const SizedBox(width: 8),
                            _buildPresetChip(
                              context,
                              provider,
                              label: '🌧️ Monsoon (27°C, 85%)',
                              key: 'monsoon_rain',
                            ),
                            const SizedBox(width: 8),
                            _buildPresetChip(
                              context,
                              provider,
                              label: '🌾 Spring Mild (23°C)',
                              key: 'spring_mild',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 1. Temperature Slider
                      _buildSliderRow(
                        icon: Icons.thermostat_rounded,
                        label: 'Temperature',
                        value: '${provider.simTemp.toStringAsFixed(1)} °C',
                        min: 12.0,
                        max: 42.0,
                        current: provider.simTemp,
                        color: const Color(0xFFD97706),
                        onChanged: (val) => provider.simulateConditions(temp: val),
                      ),
                      const SizedBox(height: 10),

                      // 2. Relative Humidity Slider
                      _buildSliderRow(
                        icon: Icons.air_rounded,
                        label: 'Relative Humidity',
                        value: '${provider.simHumidity.toStringAsFixed(0)} %',
                        min: 20.0,
                        max: 95.0,
                        current: provider.simHumidity,
                        color: const Color(0xFF2563EB),
                        onChanged: (val) => provider.simulateConditions(hum: val),
                      ),
                      const SizedBox(height: 10),

                      // 3. Soil Moisture Slider
                      _buildSliderRow(
                        icon: Icons.water_drop_rounded,
                        label: 'Soil Moisture',
                        value: '${provider.simMoisture.toStringAsFixed(0)} %',
                        min: 15.0,
                        max: 95.0,
                        current: provider.simMoisture,
                        color: const Color(0xFF0D9488),
                        onChanged: (val) => provider.simulateConditions(moisture: val),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(
    BuildContext context,
    AgronomyProvider provider, {
    required String label,
    required String key,
  }) {
    return ActionChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: const Color(0xFFF3E8FF),
      side: BorderSide(color: const Color(0xFF8B5CF6).withAlpha(80)),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6D28D9),
        ),
      ),
      onPressed: () => provider.applyWeatherPreset(key),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required String value,
    required double min,
    required double max,
    required double current,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: color,
            inactiveTrackColor: color.withAlpha(40),
            thumbColor: color,
          ),
          child: Slider(
            value: current.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
