import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.directions_boat_filled,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.welcomeTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(l10n.welcomeBody, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Notice(l10n.welcomeSampleNotice, tone: NoticeTone.warning),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('welcomeStart'),
              onPressed: () async {
                await ref.read(settingsRepositoryProvider).setOnboardingDone();
                if (context.mounted) context.go('/plan');
              },
              child: Text(l10n.welcomeStart),
            ),
          ],
        ),
      ),
    );
  }
}
