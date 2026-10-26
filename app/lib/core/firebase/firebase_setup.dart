import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/alerts/data/alerts_service.dart';
import '../../features/reports/data/firestore_report_sender.dart';
import '../../features/reports/data/reports_repository.dart';
import '../../firebase_options.dart';
import '../sync/firestore_remote_source.dart';
import '../sync/remote_source.dart';

/// The Firebase-backed services, or null when Firebase is not configured or
/// cannot start. The app is fully usable offline either way.
class FirebaseServices {
  const FirebaseServices({
    required this.remote,
    required this.reportSender,
    required this.alerts,
  });

  final RemoteSource remote;
  final ReportSender reportSender;
  final AlertsService alerts;

  static Future<FirebaseServices?> start() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on Object catch (e) {
      debugPrint('Firebase not started, running offline: $e');
      return null;
    }
    final firestore = FirebaseFirestore.instance
      // sqflite is the only local store; don't keep a second copy.
      ..settings = const Settings(persistenceEnabled: false);
    final version = await PackageInfo.fromPlatform();
    return FirebaseServices(
      remote: FirestoreRemoteSource(firestore),
      reportSender: FirestoreReportSender(
        firestore: firestore,
        auth: FirebaseAuth.instance,
        appVersion: '${version.version}+${version.buildNumber}',
      ),
      alerts: FcmAlertsService(FirebaseMessaging.instance),
    );
  }
}
