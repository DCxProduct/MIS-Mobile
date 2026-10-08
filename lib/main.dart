import 'package:flutter/material.dart';

import 'app.dart';
import 'features/shared/notifications/data/mobile_notifications_transport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await initializeMobileFirebase();
  runApp(
    GpsfApp(
      notifications: MobileNotificationsTransport(fcmReady: firebaseReady),
    ),
  );
}
