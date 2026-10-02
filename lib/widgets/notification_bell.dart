import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_settings.dart';
import '../features/shared/notifications/data/notifications_repository.dart';
import '../screens/notification/notification_screen.dart';
import '../translations/app_localizations.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  NotificationsRepository? _repository;
  int? _userId;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettings.of(context);
    final repo = settings.notifications;
    final signedIn =
        settings.currentUser != null && !settings.auth.isStaticSession;
    if (_repository != repo ||
        _userId != settings.currentUser?.id ||
        _signedIn != signedIn) {
      _repository = repo;
      _userId = settings.currentUser?.id;
      _signedIn = signedIn;
      if (signedIn) _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      await _repository?.refreshBadge();
    } catch (_) {
      // The feed shows errors and offers retry; keep the header usable offline.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _signedIn) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repository!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) => IconButton(
        tooltip: AppLocalizations.of(context).text('notifications'),
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          );
          if (mounted && _signedIn) await _refresh();
        },
        icon: Badge(
          isLabelVisible:
              _signedIn &&
              repo.preferences?.unreadBadge == true &&
              (repo.unreadCount ?? 0) > 0,
          label: Text(
            (repo.unreadCount ?? 0) > 99 ? '99+' : '${repo.unreadCount ?? 0}',
          ),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark
                  ? AppColors.darkPrimaryContainer
                  : const Color(0xFFE4F2FF),
            ),
            child: Icon(
              Icons.notifications,
              size: 22,
              color: dark ? AppColors.darkPrimary : const Color(0xFF5AA7E8),
            ),
          ),
        ),
      ),
    );
  }
}
