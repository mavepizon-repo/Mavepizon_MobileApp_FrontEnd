import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/storage_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Preload preferences so the theme (and auth) can be read synchronously at
  // startup — this ensures a saved dark theme is applied on the first frame
  // instead of resetting to light.
  await StorageHelper.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(
    const ProviderScope(
      child: MavepizonApp(),
    ),
  );
}
