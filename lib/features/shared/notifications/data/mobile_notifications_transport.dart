import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/app_settings.dart';
import '../../../../core/network/api_client.dart';

const mobileFcmEnabled = bool.fromEnvironment(
  'MOBILE_FCM_ENABLED',
  defaultValue: true,
);
const mobileRealtimeEnabled = bool.fromEnvironment(
  'MOBILE_REALTIME_ENABLED',
  defaultValue: true,
);

@pragma('vm:entry-point')
Future<void> mobileMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // OS displays the notification payload. Never show a second local alert here.
}

Future<bool> initializeMobileFirebase() async {
  if (!mobileFcmEnabled ||
      kIsWeb ||
      ![
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform)) {
    return false;
  }
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(mobileMessagingBackgroundHandler);
    return true;
  } catch (_) {
    debugPrint(
      'Mobile push unavailable: configure Firebase before enabling it.',
    );
    return false;
  }
}

/// FCM displays alerts; WebSocket only invalidates the feed and badge.
class MobileNotificationsTransport with WidgetsBindingObserver {
  MobileNotificationsTransport({required this.fcmReady});
  final bool fcmReady;
  final _local = FlutterLocalNotificationsPlugin();
  final _seen = <String>{};
  final _subscriptions = <StreamSubscription<dynamic>>[];
  AppSettingsController? _settings;
  void Function(int)? _open;
  io.Socket? _socket;
  Timer? _retry;
  int? _userId;
  int _generation = 0;
  bool _disposed = false;
  bool _foreground = true;
  bool _connecting = false;
  bool _initializing = false;
  Future<void>? _tokenCleanup;
  bool _registering = false;
  String? _registeredToken;
  Map<String, dynamic>? _pendingTap;

  Future<void> start(
    AppSettingsController settings,
    void Function(int) open,
  ) async {
    _settings = settings;
    _open = open;
    if (!fcmReady && !mobileRealtimeEnabled) return;
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_onSessionChanged);
    if (fcmReady) {
      _initializing = true;
      try {
        await _local.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_stat_notification'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: (response) {
            try {
              _handleTap(
                jsonDecode(response.payload ?? '') as Map<String, dynamic>,
              );
            } catch (_) {}
          },
        );
        const channel = AndroidNotificationChannel(
          'mis_notifications',
          'MIS notifications',
          description: 'GPSF-MIS notifications',
          importance: Importance.high,
        );
        await _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: false,
              badge: false,
              sound: false,
            );
        _subscriptions.add(
          FirebaseMessaging.onMessage.listen((message) {
            unawaited(_receive(message));
          }),
        );
        _subscriptions.add(
          FirebaseMessaging.onMessageOpenedApp.listen(
            (message) => _handleTap(message.data),
          ),
        );
        _subscriptions.add(
          FirebaseMessaging.instance.onTokenRefresh.listen((_) {
            _registeredToken = null;
            unawaited(_registerToken());
          }),
        );
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        if (initial != null) _handleTap(initial.data);
        final localLaunch = await _local.getNotificationAppLaunchDetails();
        final payload = localLaunch?.notificationResponse?.payload;
        if (localLaunch?.didNotificationLaunchApp == true && payload != null) {
          try {
            _handleTap(jsonDecode(payload) as Map<String, dynamic>);
          } catch (_) {}
        }
      } catch (_) {
        debugPrint(
          'Mobile notification initialization failed; API feed remains available.',
        );
      }
      _initializing = false;
    }
    if (_disposed) {
      dispose();
      return;
    }
    _retry = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_userId != null) {
        unawaited(_connect());
        unawaited(_registerToken());
      }
    });
    _onSessionChanged();
  }

  void _onSessionChanged() {
    if (_disposed || _initializing) return;
    final id = _settings!.currentUser?.id;
    final validId = id != null && id > 0 ? id : null;
    if (validId != _userId) {
      final wasLoggedIn = _userId != null;
      _generation++;
      _userId = validId;
      _registeredToken = null;
      _seen.clear();
      _socket?.dispose();
      _socket = null;
      if (wasLoggedIn && fcmReady) {
        _tokenCleanup = _clearInstallation();
      }
      if (_userId != null) {
        unawaited(_connect());
        unawaited(_registerToken());
      }
    }
    _flushTap();
  }

  Future<void> _registerToken() async {
    if (!fcmReady ||
        _userId == null ||
        _disposed ||
        _initializing ||
        _registering) {
      return;
    }
    _registering = true;
    final generation = _generation;
    try {
      await _tokenCleanup;
      if (generation != _generation || _disposed) return;
      final permission = await FirebaseMessaging.instance.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          'Mobile push: notification permission denied. Enable notifications in Android app settings.',
        );
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null ||
          token == _registeredToken ||
          generation != _generation ||
          _disposed) {
        return;
      }
      await _settings!.auth.apiClient.post(
        'mobile/push-devices',
        background: true,
        body: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
      );
      if (generation == _generation) {
        _registeredToken = token;
        debugPrint('Mobile push: device registration successful.');
      }
    } on ApiException catch (error) {
      debugPrint(
        'Mobile push: device registration failed (HTTP ${error.statusCode}); will retry.',
      );
    } on FirebaseException catch (error) {
      // Log only the SDK error code, never tokens or credential contents.
      debugPrint(
        'Mobile push: Firebase registration failed (${error.code}); will retry.',
      );
    } catch (_) {
      debugPrint('Mobile push: device registration unavailable; will retry.');
    } finally {
      _registering = false;
    }
  }

  Future<void> _clearInstallation() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    try {
      await _local.cancelAll();
    } catch (_) {}
  }

  Future<void> _connect() async {
    if (!mobileRealtimeEnabled ||
        !_foreground ||
        _userId == null ||
        _disposed ||
        _connecting ||
        _socket?.connected == true) {
      return;
    }
    _connecting = true;
    final generation = _generation;
    try {
      _socket?.dispose();
      _socket = null;
      final api = _settings!.auth.apiClient;
      final result = await api.post(
        'mobile/system-notifications/socket-ticket',
        background: true,
        body: {},
      );
      if (generation != _generation || _disposed || !_foreground) return;
      final ticket = result['ticket'];
      if (ticket is! String) return;
      final socket = io.io(
        '${api.serverOrigin}/mobile-notifications',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'ticket': ticket})
            .disableAutoConnect()
            .disableReconnection()
            .enableForceNew()
            .build(),
      );
      _socket = socket;
      socket.on('notifications.changed', (_) {
        if (generation == _generation && !_disposed) _refresh();
      });
      socket.connect();
    } catch (_) {
      /* Retry obtains a fresh short-lived ticket. */
    } finally {
      _connecting = false;
    }
  }

  void _refresh() {
    final repository = _settings!.notifications;
    repository.notifyRealtimeChanged();
    unawaited(
      repository.refreshBadge(background: true).catchError((Object _) {}),
    );
  }

  Future<void> _receive(RemoteMessage message) async {
    final generation = _generation;
    final id = notificationIdForUser(message.data, _userId);
    if (id == null || !_foreground || _disposed) return;
    _refresh();
    try {
      final preferences = await _settings!.notifications.getPreferences(
        background: true,
      );
      if (!preferences.systemEnabled ||
          generation != _generation ||
          _disposed) {
        return;
      }
      final key = '$_userId:$id';
      if (!_seen.add(key)) return;
      if (_seen.length > 500) _seen.remove(_seen.first);
      await _local.show(
        id: id,
        title: 'GPSF-MIS',
        body: 'You have a new notification.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'mis_notifications',
            'MIS notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (_) {
      /* Failed preferences/access checks must not show an alert. */
    }
  }

  void _handleTap(Map<String, dynamic> data) {
    _pendingTap = data;
    _flushTap();
  }

  void _flushTap() {
    if (_disposed || _pendingTap == null || _userId == null) return;
    final id = notificationIdForUser(_pendingTap!, _userId);
    _pendingTap = null;
    if (id != null) _open?.call(id);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(_connect());
      unawaited(_registerToken());
      if (_userId != null) _refresh();
    } else {
      _socket?.dispose();
      _socket = null;
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _retry?.cancel();
    _socket?.dispose();
    _settings?.removeListener(_onSessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
  }
}

int? notificationIdForUser(Map<String, dynamic> data, int? currentUserId) {
  final userId = int.tryParse('${data['userId']}');
  final id = int.tryParse('${data['notificationId']}');
  return currentUserId != null &&
          userId == currentUserId &&
          id != null &&
          id > 0
      ? id
      : null;
}
