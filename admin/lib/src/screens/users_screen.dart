import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/admin_backend.dart';
import '../state/providers.dart';

/// Admins add, change and remove admins and editors.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentStaffProvider);
    if (!me.isAdmin) {
      return const Center(child: Text('Only admins can manage users.'));
    }
    final staff = ref.watch(staffListProvider);
    final backend = ref.read(backendProvider);

    Future<void> run(Future<void> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
        ref.invalidate(staffListProvider);
      } on Object catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Users', style: Theme.of(context).textTheme.headlineSmall),
        const Text(
          'Admins can do everything, including managing users and deleting change-log '
          'entries. Editors can edit data and review reports.',
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('addUser'),
            onPressed: () async {
              final added = await showDialog<(String, StaffRole, String?)>(
                context: context,
                builder: (_) => const _AddUserDialog(),
              );
              if (added == null) return;
              await run(
                () => backend.addStaff(
                  email: added.$1,
                  role: added.$2,
                  existingUid: added.$3,
                ),
              );
            },
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add user'),
          ),
        ),
        const SizedBox(height: 12),
        switch (staff) {
          AsyncData(value: final list) => Column(
            children: [
              for (final s in list)
                Card(
                  child: ListTile(
                    key: Key('user-${s.uid}'),
                    title: Text(s.email),
                    subtitle: Text(s.uid == me.uid ? '${s.uid} (you)' : s.uid),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<StaffRole>(
                          key: Key('role-${s.uid}'),
                          value: s.role,
                          items: [
                            for (final r in StaffRole.values)
                              DropdownMenuItem(value: r, child: Text(r.name)),
                          ],
                          // Changing your own role could lock everyone out.
                          onChanged: s.uid == me.uid
                              ? null
                              : (r) => run(() => backend.setRole(s.uid, r!)),
                        ),
                        IconButton(
                          key: Key('remove-${s.uid}'),
                          tooltip: 'Remove',
                          onPressed: s.uid == me.uid
                              ? null
                              : () => run(() => backend.removeStaff(s.uid)),
                          icon: const Icon(Icons.person_remove_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          AsyncError(:final error) => Text('Could not load users: $error'),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _email = TextEditingController();
  final _uid = TextEditingController();
  StaffRole _role = StaffRole.editor;

  @override
  void dispose() {
    _email.dispose();
    _uid.dispose();
    super.dispose();
  }

  bool get _valid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add user'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('newUserEmail'),
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<StaffRole>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: [
              for (final r in StaffRole.values)
                DropdownMenuItem(value: r, child: Text(r.name)),
            ],
            onChanged: (r) => setState(() => _role = r!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _uid,
            decoration: const InputDecoration(
              labelText: 'Existing user ID (optional)',
              helperText:
                  'Only if they already have an account. Otherwise one is '
                  'created and they get an email to set their password.',
              helperMaxLines: 3,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('confirmAddUser'),
        onPressed: _valid
            ? () => Navigator.pop(context, (
                _email.text.trim(),
                _role,
                _uid.text.trim().isEmpty ? null : _uid.text.trim(),
              ))
            : null,
        child: const Text('Add'),
      ),
    ],
  );
}
