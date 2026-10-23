import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/app_settings.dart';

/// Uses the available dictionary endpoint to refresh labels while an
/// authenticated user of a supported module is viewing the app, including on resume.
class TranslationSync extends StatefulWidget {
  const TranslationSync({
    super.key,
    required this.controller,
    required this.child,
  });

  static const refreshInterval = Duration(seconds: 5);
  final AppSettingsController controller;
  final Widget child;

  @override
  State<TranslationSync> createState() => _TranslationSyncState();
}

class _TranslationSyncState extends State<TranslationSync>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;

  bool get _shouldSync =>
      _foreground &&
      widget.controller.currentUser != null &&
      widget.controller.translationModule != null;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
    widget.controller.addListener(_updatePolling);
    _updatePolling();
  }

  @override
  void didUpdateWidget(TranslationSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updatePolling);
      _stopPolling();
      widget.controller.addListener(_updatePolling);
      _updatePolling();
    }
  }

  void _refresh() {
    if (_shouldSync) {
      unawaited(widget.controller.loadTranslations(refresh: true));
    }
  }

  void _updatePolling() {
    if (!_shouldSync) {
      _stopPolling();
    } else if (_timer == null) {
      _timer = Timer.periodic(
        TranslationSync.refreshInterval,
        (_) => _refresh(),
      );
      _refresh();
    }
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updatePolling();
  }

  @override
  void dispose() {
    _stopPolling();
    widget.controller.removeListener(_updatePolling);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
