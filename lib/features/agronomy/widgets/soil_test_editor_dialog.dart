import 'package:flutter/material.dart';
import '../../../models/agronomy_models.dart';
import '../../../core/theme/app_colors.dart';

class SoilTestEditorDialog extends StatefulWidget {
  final SoilProfile currentProfile;
  final Function(SoilProfile) onSave;

  const SoilTestEditorDialog({
    super.key,
    required this.currentProfile,
    required this.onSave,
  });

  @override
  State<SoilTestEditorDialog> createState() => _SoilTestEditorDialogState();
}

class _SoilTestEditorDialogState extends State<SoilTestEditorDialog> {
  late TextEditingController _nController;
  late TextEditingController _pController;
  late TextEditingController _kController;
  late TextEditingController _phController;
  late TextEditingController _rainController;
  late String _selectedSoil;
  late String _selectedCrop;

  final List<String> _soilTypes = [
    'Loamy',
    'Sandy',
    'Black',
    'Red',
    'Clayey',
  ];

  final List<String> _commonCrops = [
    'Maize',
    'Paddy',
    'Cotton',
    'Wheat',
    'Sugarcane',
    'Millets',
    'Pulses',
    'Barley',
    'Oil seeds',
    'Ground Nuts',
  ];

  @override
  void initState() {
    super.initState();
    _nController = TextEditingController(text: widget.currentProfile.nitrogen.toStringAsFixed(0));
    _pController = TextEditingController(text: widget.currentProfile.phosphorus.toStringAsFixed(0));
    _kController = TextEditingController(text: widget.currentProfile.potassium.toStringAsFixed(0));
    _phController = TextEditingController(text: widget.currentProfile.ph.toStringAsFixed(1));
    _rainController = TextEditingController(text: widget.currentProfile.rainfallMm.toStringAsFixed(0));
    _selectedSoil = _soilTypes.contains(widget.currentProfile.soilType) ? widget.currentProfile.soilType : 'Loamy';
    _selectedCrop = _commonCrops.contains(widget.currentProfile.targetCrop) ? widget.currentProfile.targetCrop : 'Maize';
  }

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _phController.dispose();
    _rainController.dispose();
    super.dispose();
  }

  void _applyQuickPreset(String name, double n, double p, double k, double ph, String soil) {
    setState(() {
      _nController.text = n.toStringAsFixed(0);
      _pController.text = p.toStringAsFixed(0);
      _kController.text = k.toStringAsFixed(0);
      _phController.text = ph.toStringAsFixed(1);
      _selectedSoil = soil;
    });
  }

  void _save() {
    final n = double.tryParse(_nController.text.trim()) ?? 50.0;
    final p = double.tryParse(_pController.text.trim()) ?? 40.0;
    final k = double.tryParse(_kController.text.trim()) ?? 40.0;
    final ph = double.tryParse(_phController.text.trim()) ?? 6.5;
    final rain = double.tryParse(_rainController.text.trim()) ?? 100.0;

    final updated = widget.currentProfile.copyWith(
      nitrogen: n,
      phosphorus: p,
      potassium: k,
      ph: ph,
      rainfallMm: rain,
      soilType: _selectedSoil,
      targetCrop: _selectedCrop,
      isManuallyEntered: true,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soil Test Lab Report',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Enter your soil NPK & pH lab test values',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Presets
              const Text('Quick Soil Presets (Tap to fill):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text('🌾 Normal Loam', style: TextStyle(fontSize: 11)),
                      onPressed: () => _applyQuickPreset('Normal', 50, 40, 40, 6.5, 'Loamy'),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      label: const Text('⚠️ Low Nitrogen', style: TextStyle(fontSize: 11)),
                      onPressed: () => _applyQuickPreset('Low N', 15, 45, 40, 6.6, 'Loamy'),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      label: const Text('🌿 Black Cotton', style: TextStyle(fontSize: 11)),
                      onPressed: () => _applyQuickPreset('Black Cotton', 70, 45, 50, 7.8, 'Black'),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      label: const Text('🧪 Acidic Soil', style: TextStyle(fontSize: 11)),
                      onPressed: () => _applyQuickPreset('Acidic', 40, 30, 35, 5.2, 'Clayey'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // N-P-K Inputs in a 3-column row
              const Text('Macronutrients (NPK) in kg/ha or ppm:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNutrientField(
                      controller: _nController,
                      label: 'Nitrogen (N)',
                      color: Colors.blue.shade700,
                      helper: 'Leaf Growth',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildNutrientField(
                      controller: _pController,
                      label: 'Phosphorus (P)',
                      color: Colors.deepOrange.shade700,
                      helper: 'Root & Bloom',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildNutrientField(
                      controller: _kController,
                      label: 'Potassium (K)',
                      color: Colors.purple.shade700,
                      helper: 'Strength & Yield',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // pH and Rainfall
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Soil pH Level (0 - 14):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _phController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '6.5',
                            prefixIcon: const Icon(Icons.speed_rounded, size: 20, color: AppColors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('6.0 - 7.5 is neutral & ideal',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expected Rainfall (mm):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _rainController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '100',
                            prefixIcon: const Icon(Icons.cloudy_snowing, size: 20, color: Colors.blue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('Average seasonal rainfall',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Soil Type & Crop Selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Land Soil Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedSoil,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _soilTypes
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSoil = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current / Target Crop:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedCrop,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _commonCrops
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCrop = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('Apply & Predict Best Crop', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientField({
    required TextEditingController controller,
    required String label,
    required Color color,
    required String helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(helper, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
