import 'package:flutter/material.dart';
import 'app.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await PreferencesService.init();
  runApp(AgriSenseApp(prefs: prefs));
}
