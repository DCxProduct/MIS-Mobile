import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_settings.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/pdf_attachment_preview.dart';
import '../../features/shared/notifications/data/notification_destination.dart';
import '../../features/shared/notifications/data/notifications_repository.dart';
import '../../features/shared/notifications/data/system_notification.dart';
import '../../translations/app_localizations.dart';
import 'notification_destination_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationsRepository? _repository;
  final _items = <SystemNotification>[];
  final _readIds = <int>{};
  NotificationPage? _page;
  bool _loading = true;
  int? _openingId;
  String? _error;
  bool _retryMore = false;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = AppSettings.of(context).notifications;
    if (_repository != repo) {
      _repository = repo;
      _load();
    }
  }

  Future<void> _load({bool more = false}) async {
    final request = ++_request;
    _retryMore = more;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository!.getPage(page: more ? _page!.page + 1 : 1);
      if (!mounted || request != _request) return;
      setState(() {
        if (!more) {
          _items.clear();
          _readIds.clear();
        }
        final ids = _items.map((item) => item.id).toSet();
        _items.addAll(page.items.where((item) => ids.add(item.id)));
        _page = page;
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : AppLocalizations.of(context).text('notificationsLoadError');

  Future<void> _open(SystemNotification item) async {
    if (_openingId != null) return;
    setState(() => _openingId = item.id);
    try {
      final repo = _repository!;
      final settings = AppSettings.of(context);
      final userId = settings.currentUser?.id;
      final module = settings.moduleType;
      bool isCurrent() =>
          mounted &&
          _repository == repo &&
          settings.currentUser?.id == userId &&
          settings.moduleType == module;
      final detail = await repo.getNotification(item.id);
      if (!isCurrent()) return;
      if (detail.isRead) setState(() => _readIds.add(detail.id));
      try {
        final preferences = await repo.getPreferences();
        if (!isCurrent()) return;
        if (preferences.markReadOnDetail && !detail.isRead) {
          await repo.markRead(detail.id);
          if (isCurrent()) setState(() => _readIds.add(detail.id));
        }
      } catch (error) {
        // Read-state updates are independent of opening an accessible detail.
        // An unavailable preference never enables automatic marking by default.
        if (mounted && isCurrent()) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_message(error))));
        }
      }
      if (!mounted || !isCurrent()) return;
      final destination = NotificationDestination.resolve(detail, module);
      if (destination != null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            settings: RouteSettings(name: destination.route),
            builder: (_) =>
                NotificationDestinationScreen(destination: destination),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _repository!.markAllRead();
      if (mounted) {
        setState(() => _readIds.addAll(_items.map((item) => item.id)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final module = AppSettings.of(context).moduleType;
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.text('notifications'),
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.text('refresh'),
                    onPressed: _loading ? null : () => _load(),
                    icon: const Icon(Icons.refresh),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (_) => _markAllRead(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'read-all',
                        child: Text(l10n.text('markAllNotificationsRead')),
                      ),
                    ],
                  ),
                ],
              ),
              ListenableBuilder(
                listenable: _repository!,
                builder: (_, _) {
                  final count = _repository!.unreadCount;
                  return count == null
                      ? const SizedBox.shrink()
                      : Text(
                          l10n
                              .text('unreadNotifications')
                              .replaceAll('{count}', '$count'),
                          style: TextStyle(
                            color: AppColors.accent(context),
                            fontSize: 13,
                          ),
                        );
                },
              ),
              const SizedBox(height: 22),
              for (final item in _items) ...[
                _NotificationCard(
                  item: item,
                  isRead: item.isRead || _readIds.contains(item.id),
                  opening: _openingId == item.id,
                  hasDestination:
                      NotificationDestination.resolve(item, module) != null,
                  onTap: _openingId != null ? null : () => _open(item),
                ),
                const SizedBox(height: 20),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null) ...[
                Text(_error!, textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => _load(more: _retryMore),
                  child: Text(l10n.text('retry')),
                ),
              ] else if (!_loading && _items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.text('noNotifications'),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!_loading && _error == null && (_page?.hasMore ?? false))
                TextButton(
                  onPressed: () => _load(more: true),
                  child: Text(l10n.text('loadMoreNotifications')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.isRead,
    required this.opening,
    required this.hasDestination,
    required this.onTap,
  });
  final SystemNotification item;
  final bool isRead, opening, hasDestination;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = item.createdAt?.toLocal();
    final dateText = date == null
        ? ''
        : '${date.day}/${date.month}/${date.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.border(context),
              child: item.avatar == null
                  ? const Icon(Icons.person_outline, size: 22)
                  : ClipOval(
                      child: Image.network(
                        pdfAttachmentUrl(item.avatar!),
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.person_outline, size: 22),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.senderName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateText,
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 5),
                child: Container(
                  key: ValueKey('notification-unread-${item.id}'),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent(context),
                  ),
                ),
              ),
            Text(
              _timeAgo(context, date),
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 44, top: 8),
          child: Column(
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border(context)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.message,
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (hasDestination) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: TextButton(
                    key: ValueKey('notification-detail-${item.id}'),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkPrimaryContainer
                          : const Color(0xFFEDF8FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: onTap,
                    child: opening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l10n.text('viewDetail'),
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _timeAgo(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    final l10n = AppLocalizations.of(context);
    if (difference.inMinutes < 1) return l10n.text('notificationJustNow');
    final (count, key) = difference.inDays > 0
        ? (difference.inDays, 'notificationDaysAgo')
        : difference.inHours > 0
        ? (difference.inHours, 'notificationHoursAgo')
        : (difference.inMinutes, 'notificationMinutesAgo');
    return l10n.text(key).replaceAll('{count}', '$count');
  }
}
