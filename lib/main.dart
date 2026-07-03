import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('progress');
  await Hive.openBox<dynamic>('settings');
  // Mobile Ads SDK init happens on the splash screen, after the
  // UMP consent flow (AdsService.gatherConsentAndInit).
  runApp(const ProviderScope(child: RiddlesWordsApp()));
}
