import 'dart:async';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';

import '../core/app_settings.dart';
import '../core/config/module_config.dart';
import 'app_language.dart';
import 'translation_repository.dart';
import 'translation_sync.dart';

/// Keeps the short shared/account_setting keys out of role dictionaries.
class AccountTranslationData extends InheritedWidget {
  const AccountTranslationData({
    super.key,
    required this.dictionary,
    required super.child,
  });

  final Map<String, String> dictionary;

  static AccountTranslationData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccountTranslationData>();

  @override
  bool updateShouldNotify(AccountTranslationData oldWidget) =>
      !mapEquals(dictionary, oldWidget.dictionary);
}

class AccountTranslationScope extends StatefulWidget {
  const AccountTranslationScope({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<AccountTranslationScope> createState() =>
      _AccountTranslationScopeState();
}

class _AccountTranslationScopeState extends State<AccountTranslationScope>
    with WidgetsBindingObserver {
  Map<String, String> _dictionary = const {};
  (AppSettingsController, AppLanguage, AppModuleType, int?)? _identity;
  ModalRoute<dynamic>? _route;
  Timer? _timer;
  int _generation = 0;
  bool _loading = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    _foreground =
        binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed;
    binding.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettings.of(context);
    _route = ModalRoute.of(context);
    final identity = (
      settings,
      settings.language,
      settings.moduleType,
      settings.currentUser?.id,
    );
    if (identity == _identity) return;
    _identity = identity;
    _generation++;
    _loading = false;
    _dictionary = const {};
    _timer?.cancel();
    if (settings.currentUser != null) {
      _timer = Timer.periodic(
        TranslationSync.refreshInterval,
        (_) => _refresh(),
      );
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final identity = _identity;
    if (!mounted ||
        !_foreground ||
        _route?.isCurrent == false ||
        _loading ||
        identity == null ||
        identity.$4 == null) {
      return;
    }
    final generation = _generation;
    _loading = true;
    try {
      final dictionary = await TranslationRepository(
        identity.$1.auth.apiClient,
      ).dictionary(identity.$2, module: 'shared', page: 'account_setting');
      if (!mounted || generation != _generation) return;
      if (!mapEquals(_dictionary, dictionary)) {
        setState(() => _dictionary = dictionary);
      }
    } on Exception {
      // Keep the last successful labels; the next foreground poll retries.
    } finally {
      if (mounted && generation == _generation) _loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(_refresh());
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AccountTranslationData(
    dictionary: _dictionary,
    child: Builder(builder: widget.builder),
  );
}
