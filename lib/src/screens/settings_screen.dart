import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/settings_provider.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.devendrap7.riddles.words';
const _privacyUrl =
    'https://devendrap7.github.io/Riddles-words/privacy-policy.html';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_rounded),
            title: const Text('Dark mode'),
            value: settings.darkMode,
            onChanged: notifier.setDarkMode,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded),
            title: const Text('Sound'),
            value: settings.sound,
            onChanged: notifier.setSound,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.star_rate_rounded),
            title: const Text('Rate this app'),
            onTap: () => launchUrl(Uri.parse(_storeUrl),
                mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Share with friends'),
            onTap: () => SharePlus.instance.share(ShareParams(
                text: 'Can you solve all 100 word riddles? $_storeUrl')),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: const Text('Privacy policy'),
            onTap: () => launchUrl(Uri.parse(_privacyUrl),
                mode: LaunchMode.externalApplication),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Riddles: Words'),
            subtitle: Text('Version 1.0.0 · Part of the Riddles family'),
          ),
        ],
      ),
    );
  }
}
