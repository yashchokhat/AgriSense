import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/sensor_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _farmNameController;

  final List<String> _crops = ['general', 'wheat', 'tomato', 'maize', 'cotton', 'rice'];
  final List<String> _soils = ['sand', 'loam', 'clay'];

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _urlController = TextEditingController(text: settings.apiBaseUrl);
    _farmNameController = TextEditingController(text: settings.farmName);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _farmNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final sensorProv = Provider.of<SensorProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Backend API Connection Card
          _sectionHeader('API SERVER CONNECTION'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Flask REST API Base URL',
                      hintText: 'http://10.0.2.2:5001/api/v1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save_rounded, color: AppColors.primary),
                        tooltip: 'Save URL',
                        onPressed: () {
                          settings.updateApiBaseUrl(_urlController.text.trim());
                          sensorProv.fetchDashboard();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('API Base URL updated')),
                          );
                        },
                      ),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),

                  // Quick Presets
                  const Text('Quick Presets:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Android (10.0.2.2)', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _urlController.text = 'http://10.0.2.2:5001/api/v1';
                          settings.updateApiBaseUrl(_urlController.text);
                        },
                      ),
                      ActionChip(
                        label: const Text('Localhost (127.0.0.1)', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _urlController.text = 'http://127.0.0.1:5001/api/v1';
                          settings.updateApiBaseUrl(_urlController.text);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Connection Test Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: settings.isTestingConnection
                          ? null
                          : () => settings.testConnection(),
                      icon: settings.isTestingConnection
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sensors_rounded, size: 18),
                      label: Text(
                        settings.isTestingConnection ? 'Testing...' : 'Test Backend Connection',
                      ),
                    ),
                  ),

                  // Connection result indicator
                  if (settings.connectionMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (settings.connectionSuccess == true
                                ? AppColors.online
                                : AppColors.critical)
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            settings.connectionSuccess == true
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            size: 16,
                            color: settings.connectionSuccess == true
                                ? AppColors.online
                                : AppColors.critical,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              settings.connectionMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: settings.connectionSuccess == true
                                    ? AppColors.online
                                    : AppColors.critical,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Agricultural Profile
          _sectionHeader('CROP & SOIL PROFILE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _farmNameController,
                    decoration: InputDecoration(
                      labelText: 'Farm Identity',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onSubmitted: (val) => settings.updateFarmName(val.trim()),
                  ),
                  const SizedBox(height: 16),

                  // Crop Selection
                  DropdownButtonFormField<String>(
                    initialValue: settings.cropType,
                    decoration: InputDecoration(
                      labelText: 'Cultivated Crop',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _crops.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settings.updateCropType(val);
                        sensorProv.runImmediateInference();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Soil Selection
                  DropdownButtonFormField<String>(
                    initialValue: settings.soilType,
                    decoration: InputDecoration(
                      labelText: 'Soil Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _soils.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settings.updateSoilType(val);
                        sensorProv.runImmediateInference();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Telemetry Refresh Rate
          _sectionHeader('TELEMETRY REFRESH RATE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Polling: ${settings.pollingInterval} seconds',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Slider(
                    value: settings.pollingInterval.toDouble(),
                    min: 2,
                    max: 15,
                    divisions: 13,
                    label: '${settings.pollingInterval}s',
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      settings.updatePollingInterval(val.toInt());
                      sensorProv.startPolling();
                    },
                  ),
                  Text(
                    'Higher intervals conserve phone battery and reduce Firebase bandwidth.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. About AgriSense
          _sectionHeader('ABOUT AGRISENSE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AgriSense v1.0.0',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Smart IoT Agriculture Monitoring & ML Irrigation Intelligence.\nBuilt with Flutter, Python Flask, Firebase Realtime Database, and scikit-learn.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const Divider(height: 20),
                  const Text(
                    'Hardware: ESP32 + DHT11 (GPIO27) + Soil ADC (GPIO35) + DO (GPIO34)',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
