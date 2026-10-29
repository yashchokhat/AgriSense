import 'package:flutter/material.dart';

class CropVisuals {
  /// Returns a primary color theme for a crop or category
  static Color getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'fruit':
        return const Color(0xFFEA580C); // Warm orange / fruit
      case 'cereal & grain':
      case 'cereal':
        return const Color(0xFFD97706); // Amber grain
      case 'pulse & legume':
      case 'pulse':
        return const Color(0xFF16A34A); // Leaf green
      case 'cash crop / commercial':
      case 'cash crop':
        return const Color(0xFF0D9488); // Teal commercial
      case 'vegetable & spice':
      case 'vegetable':
        return const Color(0xFFE11D48); // Rose red
      case 'oilseed':
        return const Color(0xFFCA8A04); // Golden sunflower
      default:
        return const Color(0xFF059669); // Emerald default
    }
  }

  /// Returns light background color for badges
  static Color getCategoryBg(String? category) {
    return getCategoryColor(category).withAlpha(25);
  }

  /// Returns category emoji badge
  static String getCategoryEmoji(String? category) {
    switch (category?.toLowerCase()) {
      case 'fruit':
        return '🍎';
      case 'cereal & grain':
      case 'cereal':
        return '🌾';
      case 'pulse & legume':
      case 'pulse':
        return '🌱';
      case 'cash crop / commercial':
      case 'cash crop':
        return '🪴';
      case 'vegetable & spice':
      case 'vegetable':
        return '🥕';
      case 'oilseed':
        return '🌻';
      default:
        return '🌿';
    }
  }

  /// Returns icon for specific crops
  static IconData getCropIcon(String cropName) {
    final name = cropName.toLowerCase();

    // Cereals
    if (name.contains('rice') || name.contains('paddy')) return Icons.grass_rounded;
    if (name.contains('wheat') || name.contains('barley')) return Icons.grain_rounded;
    if (name.contains('maize') || name.contains('corn')) return Icons.agriculture_rounded;

    // Fruits
    if (name.contains('apple') || name.contains('pomegranate') || name.contains('guava')) return Icons.circle_outlined;
    if (name.contains('banana')) return Icons.energy_savings_leaf_rounded;
    if (name.contains('mango') || name.contains('papaya') || name.contains('orange') || name.contains('lemon')) return Icons.wb_sunny_rounded;
    if (name.contains('grapes') || name.contains('blueberry')) return Icons.bubble_chart_rounded;
    if (name.contains('watermelon') || name.contains('muskmelon')) return Icons.pie_chart_rounded;
    if (name.contains('strawberry')) return Icons.favorite_rounded;
    if (name.contains('pineapple') || name.contains('dragonfruit')) return Icons.local_florist_rounded;
    if (name.contains('fig') || name.contains('avocado')) return Icons.spa_rounded;

    // Cash / Commercial
    if (name.contains('cotton')) return Icons.cloud_queue_rounded;
    if (name.contains('tea') || name.contains('coffee')) return Icons.coffee_rounded;
    if (name.contains('sugarcane') || name.contains('jute')) return Icons.forest_rounded;
    if (name.contains('coconut')) return Icons.nature_rounded;

    // Vegetables & Spices
    if (name.contains('potato') || name.contains('onion') || name.contains('garlic')) return Icons.egg_rounded;
    if (name.contains('tomato')) return Icons.lens_rounded;

    // Oilseeds
    if (name.contains('sunflower')) return Icons.filter_vintage_rounded;
    if (name.contains('mustard') || name.contains('groundnut')) return Icons.flare_rounded;

    return Icons.eco_rounded;
  }
}
