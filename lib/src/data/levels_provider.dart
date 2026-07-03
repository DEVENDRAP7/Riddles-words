import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/level.dart';

final levelsProvider = FutureProvider<List<Level>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/levels.json');
  final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  final levels = list.map(Level.fromJson).toList()
    ..sort((a, b) => a.level.compareTo(b.level));
  return levels;
});
