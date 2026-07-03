import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/levels_provider.dart';
import '../state/progress_provider.dart';
import '../state/settings_provider.dart';
import '../theme.dart';

const _developerPageUrl =
    'https://play.google.com/store/apps/developer?id=DEVENDRAP7';

const _siblingApps = [
  ('Riddles: Brain', Icons.psychology_rounded, Color(0xFF7B1FA2)),
  ('Riddles: Maths', Icons.calculate_rounded, Color(0xFF1565C0)),
  ('Riddles: Fun', Icons.celebration_rounded, Color(0xFFE64A19)),
  ('Riddles: Pics', Icons.image_rounded, Color(0xFFC2185B)),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRatePopup());
  }

  void _maybeShowRatePopup() {
    final notifier = ref.read(settingsProvider.notifier);
    final visits = notifier.bumpHomeVisits();
    if (visits % 3 != 0 || notifier.ratePopupDismissedForever) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enjoying Riddles: Words?'),
        content: const Text('A 5-star rating helps us make more riddles!'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).dismissRateForever();
              Navigator.pop(context);
            },
            child: const Text('No thanks'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Later')),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).dismissRateForever();
              Navigator.pop(context);
              launchUrl(
                Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.devendrap7.riddles.words'),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('Rate now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(levelsProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RIDDLES · WORDS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: levelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load levels: $e')),
        data: (levels) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _ProgressHeader(
                    solved: progress.solved.length, total: levels.length),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: levels.length,
                  (context, i) {
                    final n = levels[i].level;
                    final solved = progress.isSolved(n);
                    final unlocked = progress.isUnlocked(n);
                    return _LevelTile(
                      number: n,
                      solved: solved,
                      unlocked: unlocked,
                      onTap: unlocked ? () => context.push('/play/$n') : null,
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('More Riddles →',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _siblingApps.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final (name, icon, color) = _siblingApps[i];
                          return _MoreRiddlesCard(
                              name: name, icon: icon, color: color);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.solved, required this.total});

  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.accent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$solved / $total solved',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : solved / total,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.solved,
    required this.unlocked,
    this.onTap,
  });

  final int number;
  final bool solved;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Widget child;
    if (solved) {
      bg = AppColors.accent;
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$number',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const Icon(Icons.check_rounded, color: AppColors.gold, size: 16),
        ],
      );
    } else if (unlocked) {
      bg = scheme.surfaceContainerHighest;
      child = Center(
        child: Text('$number',
            style: TextStyle(
                color: scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
      );
    } else {
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
      child = Icon(Icons.lock_rounded,
          size: 18, color: scheme.onSurface.withValues(alpha: 0.3));
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _MoreRiddlesCard extends StatelessWidget {
  const _MoreRiddlesCard(
      {required this.name, required this.icon, required this.color});

  final String name;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => launchUrl(Uri.parse(_developerPageUrl),
          mode: LaunchMode.externalApplication),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
