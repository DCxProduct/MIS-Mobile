import '../../../../core/widgets/filters/filter_models.dart';
import '../../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/material.dart';
import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/pswg_dashboard.dart';
import '../data/dashboard_repository.dart';

class PswgDataScope extends InheritedWidget {
  const PswgDataScope({
    super.key,
    required this.data,
    required super.child,
    this.loading = false,
    this.failed = false,
    this.onRetry,
  });

  final PswgDashboard data;
  final bool loading;
  final bool failed;
  final VoidCallback? onRetry;

  static PswgDataScope? stateOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PswgDataScope>();

  static PswgDashboard? maybeOf(BuildContext context) => stateOf(context)?.data;

  @override
  bool updateShouldNotify(PswgDataScope oldWidget) =>
      data != oldWidget.data ||
      loading != oldWidget.loading ||
      failed != oldWidget.failed ||
      onRetry != oldWidget.onRetry;
}

/// Loads data around the existing dashboard without supplying a new layout.
class PswgDataLoader extends StatefulWidget {
  const PswgDataLoader({
    super.key,
    required this.builder,
    this.scope = DashboardScope.pswg,
    this.progressReportId,
    this.selection,
  });

  final DashboardScope scope;
  final int? progressReportId;
  final FilterSelection? selection;

  final WidgetBuilder builder;

  @override
  State<PswgDataLoader> createState() => _PswgDataLoaderState();
}

class _PswgDataLoaderState extends State<PswgDataLoader> {
  Future<PswgDashboard>? _request;
  Object? _requestKey;
  final _snapshots = <Object, PswgDashboard>{};
  final _latestRequests = <Object, Future<PswgDashboard>>{};
  int? _effectiveReportId;
  String? _year;
  FilterSelection get _selection =>
      widget.selection ?? ApiFilterScope.selection(context, 'dashboard');

  Future<PswgDashboard> _load() {
    final key = _requestKey!;
    final request = AppSettings.of(context).dashboard.getLiveDashboard(
      scope: widget.scope,
      progressReportId: _effectiveReportId,
      year: _year,
    );
    _latestRequests[key] = request;
    return request.then((data) {
      if (mounted && identical(_latestRequests[key], request)) {
        _snapshots[key] = data;
      }
      return data;
    });
  }

  void _reload() {
    setState(() {
      _request = _load();
    });
  }

  void _updateRequest() {
    final settings = AppSettings.of(context);
    final reportId =
        widget.progressReportId ??
        int.tryParse(
          ApiFilterScope.query(context, 'dashboard')['progressReportId'] ?? '',
        );
    final year = _selection['local.year'].firstOrNull;
    // Only reuse data for the same user, module, scope and report selection.
    final key = (
      repository: settings.dashboard,
      user: settings.currentUser,
      module: settings.moduleType,
      scope: widget.scope,
      reportId: reportId,
      year: year,
    );
    if (key != _requestKey) {
      _requestKey = key;
      _year = year;
      _effectiveReportId = reportId;
      _request = _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateRequest();
  }

  @override
  void didUpdateWidget(covariant PswgDataLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateRequest();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PswgDashboard>(
    future: _request,
    builder: (context, snapshot) {
      final loading = snapshot.connectionState != ConnectionState.done;
      final data = _snapshots[_requestKey];
      return PswgDataScope(
        data: data?.filtered(_selection) ?? PswgDashboard.unavailable(),
        loading: loading,
        failed: !loading && snapshot.hasError,
        onRetry: _reload,
        child: TranslationPageScope(
          page: widget.scope == DashboardScope.plenary
              ? 'dashboard_plenary'
              : 'dashboard_working_group',
          child: Builder(builder: widget.builder),
        ),
      );
    },
  );
}
