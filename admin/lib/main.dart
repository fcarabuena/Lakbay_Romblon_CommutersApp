import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/backend/firestore_backend.dart';
import 'src/state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (e) {
    runApp(_NotConfigured(error: e));
    return;
  }
  runApp(
    ProviderScope(
      overrides: [backendProvider.overrideWithValue(FirestoreAdminBackend())],
      child: const AdminApp(),
    ),
  );
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Firebase is not set up for the admin panel yet.\n'
            'Follow docs/firebase-setup.md, then rebuild.\n\n$error',
          ),
        ),
      ),
    ),
  );
}
