import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/ui/formatters.dart';
import '../features/advisories/application/advisory_providers.dart';
import '../features/advisories/presentation/advisory_screens.dart';
import '../features/advisories/presentation/advisory_widgets.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/buses/presentation/buses_screens.dart';
import '../features/first_timer/presentation/first_timer_screen.dart';
import '../features/guides/presentation/guide_screens.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/planner/presentation/plan_detail_screen.dart';
import '../features/planner/presentation/planner_screen.dart';
import '../features/planner/presentation/results_screen.dart';
import '../features/reports/presentation/report_screens.dart';
import '../features/safety/presentation/safety_screen.dart';
import '../features/settings/presentation/more_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/ships/presentation/ships_screens.dart';
import '../features/trips/presentation/trips_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final onboarded = ref.watch(onboardingDoneAtStartProvider);
  return buildRouter(initialLocation: onboarded ? '/plan' : '/welcome');
});

GoRouter buildRouter({String initialLocation = '/plan'}) {
  String? id(GoRouterState state) => state.uri.queryParameters['id'];

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/advisories',
        builder: (_, _) => const AdvisoryListScreen(),
        routes: [
          GoRoute(
            path: ':advisoryId',
            builder: (_, state) => AdvisoryDetailScreen(
              advisoryId: state.pathParameters['advisoryId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/report',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return ReportScreen(
            collection: q['collection'] ?? '',
            targetId: q['id'] ?? '',
            label: q['label'] ?? '',
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (_, _) => const PlannerScreen(),
                routes: [
                  GoRoute(
                    path: 'results',
                    builder: (_, _) => const ResultsScreen(),
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (_, state) =>
                        PlanDetailScreen(planId: id(state) ?? ''),
                  ),
                  GoRoute(
                    path: 'first-timer',
                    builder: (_, state) =>
                        FirstTimerScreen(planId: id(state) ?? ''),
                  ),
                  GoRoute(
                    path: 'budget',
                    builder: (_, state) => BudgetScreen(planId: id(state)),
                  ),
                  GoRoute(
                    path: 'trips',
                    builder: (_, _) => const TripsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedules',
                builder: (_, _) => const SchedulesScreen(),
                routes: [
                  GoRoute(
                    path: 'voyage/:voyageId',
                    builder: (_, state) => VoyageDetailScreen(
                      voyageId: state.pathParameters['voyageId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'bus/:routeId',
                    builder: (_, state) => BusRouteDetailScreen(
                      routeId: state.pathParameters['routeId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guide',
                builder: (_, _) => const GuideListScreen(),
                routes: [
                  GoRoute(
                    path: ':placeId',
                    builder: (_, state) => GuideDetailScreen(
                      placeId: state.pathParameters['placeId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/safety', builder: (_, _) => const SafetyScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'trips',
                    builder: (_, _) => const TripsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (_, _) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (_, _) => const MyReportsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bottom navigation, the sample-data banner on every tab, and the advisory
/// banner on the Plan, Schedules and Guide tabs.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final placeholder = ref.watch(travelDataProvider).meta.isPlaceholderData;
    final scheme = Theme.of(context).colorScheme;
    final showAdvisory =
        shell.currentIndex <= 2 &&
        ref.watch(activeAdvisoriesProvider).isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          if (placeholder)
            Material(
              color: scheme.tertiaryContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: scheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.placeholderDataBanner,
                          key: const Key('placeholderBanner'),
                          style: TextStyle(
                            color: scheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (showAdvisory)
            placeholder
                ? const AdvisoryBanner()
                : const SafeArea(bottom: false, child: AdvisoryBanner()),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: placeholder || showAdvisory,
              child: shell,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: l10n.navPlan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.schedule_outlined),
            selectedIcon: const Icon(Icons.schedule),
            label: l10n.navSchedules,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.navGuide,
          ),
          NavigationDestination(
            icon: const Icon(Icons.health_and_safety_outlined),
            selectedIcon: const Icon(Icons.health_and_safety),
            label: l10n.navSafety,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}
