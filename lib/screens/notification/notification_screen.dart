import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const _sections = [
    _NotificationSection(
      title: 'Today',
      items: [
        _NotificationItem(
          sender: 'MAFF',
          date: 'Sep 12, 2025',
          timeAgo: '5 Min ago',
          message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
          isRead: false,
        ),
        _NotificationItem(
          sender: 'MAFF',
          date: 'Sep 12, 2025',
          timeAgo: '5 Min ago',
          message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
          isRead: false,
        ),
        _NotificationItem(
          sender: 'MAFF',
          date: 'Sep 12, 2025',
          timeAgo: '5 Min ago',
          message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
          isRead: true,
        ),
      ],
    ),
    _NotificationSection(
      title: 'Yesterday',
      items: [
        _NotificationItem(
          sender: 'MAFF',
          date: 'Sep 12, 2025',
          timeAgo: '5 Min ago',
          message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
          isRead: true,
        ),
        _NotificationItem(
          sender: 'MAFF',
          date: 'Sep 12, 2025',
          timeAgo: '5 Min ago',
          message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
          isRead: true,
        ),
      ],
    ),
    _NotificationSection(
      title: 'This Weekend',
      items: [
        _NotificationItem(
          sender: 'MAFF',
          date: 'Sep 12, 2025',
          timeAgo: '5 Min ago',
          message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
          isRead: true,
        ),
        _NotificationItem(
          sender: 'MAFF',
          date: 'Sep 12, 2025',
          timeAgo: '5 Min ago',
          message: 'Request of WG meeting on 25 September 2025 at 3PM-4PM',
          isRead: true,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = AppColors.pageBackground(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.onSurface,
            size: 17,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: colors.onSurface, size: 21),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border(context)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            for (final section in _sections) ...[
              _SectionHeader(title: section.title),
              for (final item in section.items) _NotificationTile(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = AppColors.isDark(context);
    final rowColor = !item.isRead
        ? (isDark ? AppColors.darkCard : const Color(0xFFF7F8FF))
        : Colors.transparent;

    return Container(
      color: rowColor,
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 1), child: _MaffAvatar()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: item.sender,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' requested a WG meeting on '),
                      const TextSpan(
                        text: '25 September 2025',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' at '),
                      const TextSpan(
                        text: '3PM-4PM',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.isRead
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                    fontSize: 13,
                    height: 1.22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '${item.date}  ·  ${item.timeAgo}',
                      style: TextStyle(
                        color: AppColors.secondaryText(context),
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!item.isRead) ...[
                      const SizedBox(width: 7),
                      const _UnreadDot(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 7),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.darkBackground
            : const Color(0xFFFAFAFB),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.secondaryText(context),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MaffAvatar extends StatelessWidget {
  const _MaffAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEEF7F2),
        border: Border.all(color: const Color(0xFFD8EDE1)),
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF18A55A),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'M',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.accent(context),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NotificationSection {
  const _NotificationSection({required this.title, required this.items});

  final String title;
  final List<_NotificationItem> items;
}

class _NotificationItem {
  const _NotificationItem({
    required this.sender,
    required this.date,
    required this.timeAgo,
    required this.message,
    required this.isRead,
  });

  final String sender;
  final String date;
  final String timeAgo;
  final String message;
  final bool isRead;
}
