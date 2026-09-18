import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../meeting/meeting_request_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const _notifications = [
    _NotificationItemData(
      sender: 'MAFF',
      date: 'Sep 12 ,2025',
      timeAgo: '5 Min ago',
      message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
      unread: true,
    ),
    _NotificationItemData(
      sender: 'MAFF',
      date: 'Sep 12 ,2025',
      timeAgo: '5 Min ago',
      message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
      unread: true,
    ),
    _NotificationItemData(
      sender: 'MAFF',
      date: 'Sep 12 ,2025',
      timeAgo: '5 Min ago',
      message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
      unread: true,
    ),
    _NotificationItemData(
      sender: 'MAFF',
      date: 'Sep 12 ,2025',
      timeAgo: '5 Min ago',
      message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
      unread: true,
    ),
    _NotificationItemData(
      sender: 'MAFF',
      date: 'Sep 12 ,2025',
      timeAgo: '5 Min ago',
      message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).viewPadding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            topPadding > 0 ? topPadding + 10 : 32,
            16,
            32,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryText(context),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notification',
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: 'You have ',
                children: [
                  TextSpan(
                    text: '4 Notification',
                    style: TextStyle(
                      color: AppColors.accent(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' today.'),
                ],
              ),
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            for (final item in _notifications) ...[
              _NotificationCard(item: item),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final _NotificationItemData item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _MinistryEmblemAvatar(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.sender,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.date,
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.unread) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.accent(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  item.timeAgo,
                  style: TextStyle(
                    color: item.unread
                        ? AppColors.accent(context)
                        : AppColors.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEBEFF3),
            ),
          ),
          child: Text(
            item.message,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 36,
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MeetingRequestDetailScreen(
                    title: 'សំណើប្រជុំពិភាក្សាដោះស្រាយបញ្ហាចំនួន ៣ ដែលបានដាក់ជូនក្រសួងខាងក្រោម ។',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.accent(context).withValues(alpha: 0.18)
                  : const Color(0xFFEAF7FF),
              foregroundColor: AppColors.accent(context),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'View Detail',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MinistryEmblemAvatar extends StatelessWidget {
  const _MinistryEmblemAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF216AAA), Color(0xFF1EA45B)],
        ),
      ),
      child: const Icon(
        Icons.account_balance,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _NotificationItemData {
  const _NotificationItemData({
    required this.sender,
    required this.date,
    required this.timeAgo,
    required this.message,
    required this.unread,
  });

  final String sender;
  final String date;
  final String timeAgo;
  final String message;
  final bool unread;
}
