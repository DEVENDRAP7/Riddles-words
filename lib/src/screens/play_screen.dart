import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/levels_provider.dart';
import '../models/level.dart';
import '../services/ads_service.dart';
import '../state/progress_provider.dart';
import '../theme.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key, required this.levelNumber});

  final int levelNumber;

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen>
    with SingleTickerProviderStateMixin {
  final _answerController = TextEditingController();
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  BannerAd? _banner;
  bool _adBusy = false;

  @override
  void initState() {
    super.initState();
    _banner = ref.read(adsServiceProvider).createBanner(
      onFailed: (_, _) {
        if (mounted) setState(() => _banner = null);
      },
    );
    ref.read(adsServiceProvider).preloadInterstitial();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _shakeController.dispose();
    _banner?.dispose();
    super.dispose();
  }

  void _check(Level level) {
    FocusScope.of(context).unfocus();
    if (level.matches(_answerController.text)) {
      ref.read(progressProvider.notifier).markSolved(level.level);
      ref.read(adsServiceProvider).onLevelSolved();
      _showSolvedDialog(level);
    } else {
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Not quite — try again!'),
            duration: Duration(seconds: 1)),
      );
    }
  }

  void _showSolvedDialog(Level level) {
    final isLast = level.level >= 100;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events_rounded,
            color: AppColors.gold, size: 48),
        title: Text(isLast ? 'ALL 100 SOLVED!' : 'Correct!'),
        content: Text(level.solution, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Home'),
          ),
          if (!isLast)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.pushReplacement('/play/${level.level + 1}');
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  Future<void> _watchHintAd(Level level) async {
    if (_adBusy) return;
    setState(() => _adBusy = true);
    final earned = await ref.read(adsServiceProvider).showRewarded();
    if (!mounted) return;
    setState(() => _adBusy = false);
    if (earned) {
      ref.read(progressProvider.notifier).addHintAd(level.level);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not available — try again in a moment.')),
      );
    }
  }

  Future<void> _watchSolutionAd(Level level) async {
    if (_adBusy) return;
    setState(() => _adBusy = true);
    final earned = await ref.read(adsServiceProvider).showRewarded();
    if (!mounted) return;
    setState(() => _adBusy = false);
    if (earned) {
      ref.read(progressProvider.notifier).unlockSolution(level.level);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not available — try again in a moment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(levelsProvider);
    final progress = ref.watch(progressProvider);

    return levelsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (levels) {
        final level = levels[widget.levelNumber - 1];
        final hintUnlocked = progress.hintUnlocked.contains(level.level);
        final solutionUnlocked = progress.solutionUnlocked.contains(level.level);
        final adsWatched = progress.hintAdsWatched(level.level);

        return Scaffold(
          appBar: AppBar(title: Text('LEVEL ${level.level}')),
          bottomNavigationBar: _banner == null
              ? null
              : SafeArea(
                  child: SizedBox(
                    height: _banner!.size.height.toDouble(),
                    width: _banner!.size.width.toDouble(),
                    child: AdWidget(ad: _banner!),
                  ),
                ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Chip(
                      label: Text(level.type.toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, letterSpacing: 1)),
                      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                      side: BorderSide.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        level.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700, height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final t = _shakeController.value;
                      final offset =
                          t == 0 ? 0.0 : (1 - t) * 12 * (t * 40 % 2 == 0 ? 1 : -1);
                      return Transform.translate(
                          offset: Offset(offset, 0), child: child);
                    },
                    child: TextField(
                      controller: _answerController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4),
                      decoration:
                          const InputDecoration(hintText: 'TYPE YOUR ANSWER'),
                      onSubmitted: (_) => _check(level),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: () => _check(level), child: const Text('CHECK')),
                  const SizedBox(height: 28),
                  _HintCard(
                    title: 'HINT',
                    icon: Icons.lightbulb_rounded,
                    unlocked: hintUnlocked,
                    unlockedText: level.hint,
                    lockedChild: FilledButton.tonalIcon(
                      onPressed: _adBusy ? null : () => _watchHintAd(level),
                      icon: const Icon(Icons.play_circle_rounded),
                      label: Text(
                          'WATCH AD  ($adsWatched/${Progress.adsPerHint})'),
                    ),
                    lockedCaption:
                        'Watch ${Progress.adsPerHint} ads to unlock the hint.',
                  ),
                  const SizedBox(height: 12),
                  if (hintUnlocked)
                    _HintCard(
                      title: 'SOLUTION',
                      icon: Icons.vpn_key_rounded,
                      unlocked: solutionUnlocked,
                      unlockedText:
                          '${level.answer}\n\n${level.solution}\n\nType it above to solve the level!',
                      lockedChild: FilledButton.tonalIcon(
                        onPressed: _adBusy ? null : () => _watchSolutionAd(level),
                        icon: const Icon(Icons.play_circle_rounded),
                        label: const Text('WATCH 1 AD FOR SOLUTION'),
                      ),
                      lockedCaption:
                          'Still stuck? One more ad reveals the answer.',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.title,
    required this.icon,
    required this.unlocked,
    required this.unlockedText,
    required this.lockedChild,
    required this.lockedCaption,
  });

  final String title;
  final IconData icon;
  final bool unlocked;
  final String unlockedText;
  final Widget lockedChild;
  final String lockedCaption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 12),
            if (unlocked)
              Text(unlockedText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.4))
            else ...[
              lockedChild,
              const SizedBox(height: 8),
              Text(lockedCaption,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6))),
            ],
          ],
        ),
      ),
    );
  }
}
