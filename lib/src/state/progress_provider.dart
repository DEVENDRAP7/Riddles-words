import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Per-user game progress, persisted locally in Hive (no cloud sync).
class Progress {
  const Progress({
    required this.solved,
    required this.hintAds,
    required this.hintUnlocked,
    required this.solutionUnlocked,
  });

  final Set<int> solved;

  /// Rewarded ads watched toward the hint of a level (need 3).
  final Map<int, int> hintAds;
  final Set<int> hintUnlocked;
  final Set<int> solutionUnlocked;

  static const int adsPerHint = 3;

  bool isSolved(int level) => solved.contains(level);

  /// Level 1 always unlocked; otherwise previous level must be solved.
  bool isUnlocked(int level) => level == 1 || solved.contains(level - 1);

  int get highestUnlocked {
    var highest = 1;
    while (solved.contains(highest) && highest < 100) {
      highest++;
    }
    return highest;
  }

  int hintAdsWatched(int level) => hintAds[level] ?? 0;
}

class ProgressNotifier extends Notifier<Progress> {
  Box<dynamic> get _box => Hive.box<dynamic>('progress');

  @override
  Progress build() => Progress(
        solved: ((_box.get('solved', defaultValue: <dynamic>[]) as List).cast<int>()).toSet(),
        hintAds: ((_box.get('hintAds', defaultValue: <dynamic, dynamic>{}) as Map)
            .map((k, v) => MapEntry(int.parse(k.toString()), v as int))),
        hintUnlocked:
            ((_box.get('hintUnlocked', defaultValue: <dynamic>[]) as List).cast<int>()).toSet(),
        solutionUnlocked:
            ((_box.get('solutionUnlocked', defaultValue: <dynamic>[]) as List).cast<int>())
                .toSet(),
      );

  void _persist() {
    _box.put('solved', state.solved.toList());
    _box.put('hintAds', state.hintAds.map((k, v) => MapEntry(k.toString(), v)));
    _box.put('hintUnlocked', state.hintUnlocked.toList());
    _box.put('solutionUnlocked', state.solutionUnlocked.toList());
  }

  void markSolved(int level) {
    state = Progress(
      solved: {...state.solved, level},
      hintAds: state.hintAds,
      hintUnlocked: state.hintUnlocked,
      solutionUnlocked: state.solutionUnlocked,
    );
    _persist();
  }

  /// Records one rewarded ad watched toward the hint. Returns ads watched so far.
  int addHintAd(int level) {
    final watched = (state.hintAds[level] ?? 0) + 1;
    final hints = {...state.hintUnlocked};
    if (watched >= Progress.adsPerHint) hints.add(level);
    state = Progress(
      solved: state.solved,
      hintAds: {...state.hintAds, level: watched},
      hintUnlocked: hints,
      solutionUnlocked: state.solutionUnlocked,
    );
    _persist();
    return watched;
  }

  void unlockSolution(int level) {
    state = Progress(
      solved: state.solved,
      hintAds: state.hintAds,
      hintUnlocked: state.hintUnlocked,
      solutionUnlocked: {...state.solutionUnlocked, level},
    );
    _persist();
  }
}

final progressProvider =
    NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);
