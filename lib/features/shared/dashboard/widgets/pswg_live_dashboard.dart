import '../../../../core/widgets/filters/filter_models.dart';
import '../../../../core/widgets/filters/api_filter_scope.dart';
import 'package:flutter/material.dart';
import '../../../../core/app_settings.dart';
import '../../../../translations/app_localizations.dart';
import '../data/pswg_dashboard.dart';
import '../data/dashboard_repository.dart';

class PswgDataScope extends InheritedWidget {
  const PswgDataScope({super.key, required this.data, required super.child});

  final PswgDashboard data;

  static PswgDashboard? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PswgDataScope>()?.data;

  @override
  bool updateShouldNotify(PswgDataScope oldWidget) => data != oldWidget.data;
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
  int? _effectiveReportId;
  String? _year;
  FilterSelection get _selection =>
      widget.selection ?? ApiFilterScope.selection(context, 'dashboard');

  Future<PswgDashboard> _load() =>
      AppSettings.of(context).dashboard.getLiveDashboard(
        scope: widget.scope,
        progressReportId: _effectiveReportId,
        year: _year,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reportId =
        widget.progressReportId ??
        int.tryParse(
          ApiFilterScope.query(context, 'dashboard')['progressReportId'] ?? '',
        );
    final year = _selection['local.year'].firstOrNull;
    if (_request == null || reportId != _effectiveReportId || year != _year) {
      _year = year;
      _effectiveReportId = reportId;
      _request = _load();
    }
  }

  @override
  void didUpdateWidget(covariant PswgDataLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope ||
        oldWidget.progressReportId != widget.progressReportId ||
        oldWidget.selection?['local.year'].firstOrNull !=
            widget.selection?['local.year'].firstOrNull) {
      _year = _selection['local.year'].firstOrNull;
      _effectiveReportId =
          widget.progressReportId ??
          int.tryParse(
            ApiFilterScope.query(context, 'dashboard')['progressReportId'] ??
                '',
          );
      _request = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PswgDashboard>(
    future: _request,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        final l10n = AppLocalizations.of(context);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.text('dashboardLoadError')),
              TextButton(
                onPressed: () => setState(() {
                  _request = _load();
                }),
                child: Text(l10n.text('retry')),
              ),
            ],
          ),
        );
      }
      return PswgDataScope(
        data: snapshot.data!.filtered(_selection),
        child: Builder(builder: widget.builder),
      );
    },
  );
}
