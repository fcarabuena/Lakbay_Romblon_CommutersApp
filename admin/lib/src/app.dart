import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_ui/lakbay_ui.dart';

import 'editing/collection_list_screen.dart';
import 'editing/collection_specs.dart';
import 'editing/editor_screen.dart';
import 'screens/audit_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/users_screen.dart';
import 'state/providers.dart';

/// Where the panel opens after signing in; tests open other pages directly.
final initialAdminLocationProvider = Provider<String>((ref) => '/');

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lakbay Romblon admin',
    debugShowCheckedModeBanner: false,
    theme: LakbayTheme.light(),
    themeMode: ThemeMode.light,
    home: const AuthGate(),
  );
}

/// Login, then a check that the account is an admin or editor.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    final staff = ref.watch(staffProvider);
    return switch ((user, staff)) {
      (AsyncData(value: null), _) => const LoginScreen(),
      (AsyncData(), AsyncData(value: null)) => const _NotStaffScreen(),
      (AsyncData(), AsyncData(value: _?)) => const _SignedIn(),
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) =>
        Scaffold(body: Center(child: Text('Something went wrong: $error'))),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref
          .read(backendProvider)
          .signIn(_email.text.trim(), _password.text);
    } on Object {
      setState(() => _message = 'Wrong email or password.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _message = 'Enter your email first.');
      return;
    }
    try {
      await ref.read(backendProvider).sendPasswordReset(_email.text.trim());
    } on Object {
      // Same message either way, so the form does not reveal which emails exist.
    }
    setState(
      () => _message =
          'If that email has an account, a reset link is on its way.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SizedBox(
        width: 380,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Lakbay Romblon admin',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('email'),
                    controller: _email,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    key: const Key('password'),
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => _signIn(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('signIn'),
                    onPressed: _busy ? null : _signIn,
                    child: const Text('Sign in'),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Forgot password?'),
                  ),
                  if (_message != null)
                    Text(_message!, key: const Key('loginMessage')),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _NotStaffScreen extends ConsumerWidget {
  const _NotStaffScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This account is not an admin or editor.',
            key: Key('notStaff'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(backendProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    ),
  );
}

class _SignedIn extends ConsumerStatefulWidget {
  const _SignedIn();

  @override
  ConsumerState<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends ConsumerState<_SignedIn> {
  late final GoRouter _router = buildAdminRouter(
    initialLocation: ref.read(initialAdminLocationProvider),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Router.withConfig(config: _router);
}

/// Navigation entries; the Users entry is shown to admins only.
typedef NavEntry = ({
  String path,
  String label,
  IconData icon,
  bool adminOnly,
  String? group,
});

/// Sidebar groups, in order, with the collections in each.
const _navGroups = [
  (
    'Sea travel',
    ['advisories', 'ports', 'shipping_lines', 'voyages', 'ship_fares'],
  ),
  (
    'Land travel',
    [
      'municipalities',
      'local_rides',
      'bus_operators',
      'bus_terminals',
      'bus_routes',
      'hubs',
    ],
  ),
  ('Help for travelers', ['guides', 'hotlines', 'safety_tips', 'checklists']),
];

/// Navigation entries; the Users entry is shown to admins only.
List<NavEntry> navEntries() => [
  (
    path: '/',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    adminOnly: false,
    group: null,
  ),
  for (final (group, collections) in _navGroups)
    for (final c in collections)
      if (specFor(c) case final spec?)
        (
          path: '/data/$c',
          label: spec.title,
          icon: _iconFor(c),
          adminOnly: false,
          group: group,
        ),
  (
    path: '/reports',
    label: 'Reports',
    icon: Icons.flag_outlined,
    adminOnly: false,
    group: 'Review',
  ),
  (
    path: '/audit',
    label: 'Change log',
    icon: Icons.history,
    adminOnly: false,
    group: 'Review',
  ),
  (
    path: '/users',
    label: 'Users',
    icon: Icons.group_outlined,
    adminOnly: true,
    group: 'Review',
  ),
];

IconData _iconFor(String collection) => switch (collection) {
  'advisories' => Icons.campaign_outlined,
  'ship_fares' || 'voyages' => Icons.directions_boat_outlined,
  'bus_routes' ||
  'bus_operators' ||
  'bus_terminals' => Icons.directions_bus_outlined,
  'local_rides' => Icons.electric_rickshaw,
  'guides' => Icons.photo_library_outlined,
  'hotlines' => Icons.call_outlined,
  'safety_tips' => Icons.health_and_safety_outlined,
  _ => Icons.dataset_outlined,
};

GoRouter buildAdminRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AdminShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        GoRoute(
          path: '/data/:collection',
          builder: (_, s) => CollectionListScreen(
            key: ValueKey(s.pathParameters['collection']),
            collection: s.pathParameters['collection']!,
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, s) {
                final id = s.pathParameters['id']!;
                return EditorScreen(
                  key: ValueKey(
                    '${s.pathParameters['collection']}/$id/${s.uri.queryParameters['report']}',
                  ),
                  collection: s.pathParameters['collection']!,
                  docId: id == 'new' ? null : id,
                  reportId: s.uri.queryParameters['report'],
                );
              },
            ),
          ],
        ),
        GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
        GoRoute(path: '/audit', builder: (_, _) => const AuditScreen()),
        GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
      ],
    ),
  ],
);

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentStaffProvider);
    final entries = [
      for (final e in navEntries())
        if (!e.adminOnly || staff.isAdmin) e,
    ];
    final selected = entries.lastIndexWhere(
      (e) => e.path == '/' ? location == '/' : location.startsWith(e.path),
    );

    // A plain list rather than NavigationDrawer: long labels wrap instead of
    // overflowing, and groups get headings.
    Widget nav(bool expanded) {
      final scheme = Theme.of(context).colorScheme;
      final text = Theme.of(context).textTheme;
      final children = <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Lakbay Romblon admin', style: text.titleMedium),
        ),
      ];
      String? lastGroup;
      for (final (i, e) in entries.indexed) {
        if (e.group != null && e.group != lastGroup) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                e.group!.toUpperCase(),
                style: text.labelSmall?.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        lastGroup = e.group;
        final active = i == selected;
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: ListTile(
              key: Key('nav-${e.path}'),
              dense: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              leading: Icon(
                e.icon,
                color: active ? scheme.primary : TideColors.sidebarText,
              ),
              title: Text(
                e.label,
                style: text.bodyMedium?.copyWith(
                  color: active ? scheme.primary : TideColors.sidebarText,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: active,
              selectedTileColor: scheme.primaryContainer,
              onTap: () {
                if (!expanded) Navigator.of(context).pop();
                context.go(e.path);
              },
            ),
          ),
        );
      }
      return Material(
        color: scheme.surface,
        shape: const Border(right: BorderSide(color: TideColors.hairline)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        return Scaffold(
          appBar: AppBar(
            title: Text(staff.email),
            actions: [
              IconButton(
                tooltip: 'Reload data',
                onPressed: () {
                  ref.read(datasetProvider.notifier).reload();
                  ref.invalidate(reportsProvider);
                  ref.invalidate(auditProvider);
                },
                icon: const Icon(Icons.refresh),
              ),
              TextButton.icon(
                key: const Key('signOut'),
                onPressed: () => ref.read(backendProvider).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
          drawer: wide ? null : Drawer(child: nav(false)),
          body: Row(
            children: [
              if (wide) SizedBox(width: 280, child: nav(true)),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
