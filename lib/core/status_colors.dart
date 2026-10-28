import 'package:flutter/material.dart';

/// Web status palettes. Resolve the raw API status before translating its label.
abstract final class StatusColors {
  static String _key(String status) => status
      .trim()
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .toUpperCase();

  static Color _color(BuildContext context, (int, int) pair) => Color(
    Theme.of(context).brightness == Brightness.dark ? pair.$2 : pair.$1,
  );

  static Color workflow(BuildContext context, String status) =>
      _color(context, switch (_key(status)) {
        'SOLVED' => (0xFF3EAD46, 0xFF4ADE80),
        'IN_PROGRESS' ||
        'UPDATING' ||
        'PREPARING' ||
        'UNDER_REVIEW' ||
        'CDC_UNDER_REVIEW' ||
        'RE_REVIEWING' ||
        'CDC_RE_REVIEWING' ||
        'NEEDS_UPDATE' => (0xFFF79009, 0xFFFBBF24),
        'NOT_ADDRESSED' ||
        'NOT_ADDRESS' ||
        'REJECTED' ||
        'RETURNED' => (0xFFF04438, 0xFFF87171),
        'SAVED' || 'PSWG_REVIEWED' => (0xFF6941C6, 0xFFC4B5FD),
        'SENT' ||
        'SUBMIT' ||
        'SUBMITTED' ||
        'REQUESTED' ||
        'RESUBMITTED' => (0xFF1A64A8, 0xFF60A5FA),
        'NEW_SUBMISSION' ||
        'NEW_SUBMITTED' ||
        'SHARED' ||
        'SHARED_WITH_PSWG' => (0xFF175CD3, 0xFF60A5FA),
        'REVIEWED' ||
        'COMPLETE' ||
        'COMPLETED' ||
        'APPROVED' => (0xFF027A48, 0xFF4ADE80),
        'MID_PROGRESS' => (0xFFB54708, 0xFFFBBF24),
        'EARLY_PROGRESS' => (0xFFA16207, 0xFFFDE68A),
        // Includes DRAFT, DRAFTED, SAVE_DRAFT and unknown statuses.
        _ => (0xFF717680, 0xFFD1D5DB),
      });

  static Color meetingRequest(BuildContext context, String status) =>
      _color(context, switch (_key(status)) {
        'DRAFT' || 'DRAFTED' => (0xFFF04438, 0xFFF87171),
        'UNDER_REVIEW' => (0xFFF79009, 0xFFFBBF24),
        'SUBMITTED' => (0xFF12B76A, 0xFF4ADE80),
        'COMPLETED' => (0xFF1A64A8, 0xFF60A5FA),
        _ => (0xFF667085, 0xFFD1D5DB),
      });

  static Color meetingSummary(BuildContext context, String status) {
    // Web distinguishes the display status Reviewed from the API status REVIEWED.
    if (status.trim() == 'Reviewed') {
      return _color(context, (0xFF32D583, 0xFF4ADE80));
    }
    return _color(context, switch (_key(status)) {
      'SUBMITTED' => (0xFF079455, 0xFF4ADE80),
      'CONFIRMED' => (0xFF107569, 0xFF2DD4BF),
      'SHARED' => (0xFF175CD3, 0xFF60A5FA),
      'RETURNED' => (0xFFB93815, 0xFFFB923C),
      'REVIEWED' => (0xFFFEC84B, 0xFFFBBF24),
      'COMPLETED' => (0xFF32D583, 0xFF4ADE80),
      'PSWG_REVIEWED' => (0xFF6941C6, 0xFFC4B5FD),
      'NEEDS_UPDATE' ||
      'UPDATING' ||
      'UNDER_REVIEW' => (0xFFF79009, 0xFFFBBF24),
      _ => (0xFF717680, 0xFFD1D5DB),
    });
  }

  static Color rgcDecisionChip(BuildContext context, String status) =>
      switch (_key(status)) {
        'SOLVED' => _color(context, (0xFF16A34A, 0xFF86EFAC)),
        'IN_PROGRESS' => _color(context, (0xFFF59E0B, 0xFFFCD34D)),
        'NOT_ADDRESSED' ||
        'NOT_ADDRESS' => _color(context, (0xFFDC2626, 0xFFFCA5A5)),
        _ => workflow(context, status),
      };

  static Color userDot(BuildContext context, {required bool active}) => _color(
    context,
    active ? (0xFF17B26A, 0xFF4ADE80) : (0xFFF04438, 0xFFF87171),
  );

  static Color plenaryChip(BuildContext context, String status) =>
      switch (_key(status)) {
        'SENT' || 'SOLVED' => const Color(0xFF22A865),
        'DRAFT' || 'DRAFTED' || 'SAVE_DRAFT' => const Color(0xFFE69B24),
        _ => workflow(context, status),
      };
}
