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
  });

  final DashboardScope scope;

  final WidgetBuilder builder;

  @override
  State<PswgDataLoader> createState() => _PswgDataLoaderState();
}

class _PswgDataLoaderState extends State<PswgDataLoader> {
  Future<PswgDashboard>? _request;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= AppSettings.of(
      context,
    ).dashboard.getLiveDashboard(scope: widget.scope);
  }

  @override
  void didUpdateWidget(covariant PswgDataLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) {
      _request = AppSettings.of(
        context,
      ).dashboard.getLiveDashboard(scope: widget.scope);
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
                  _request = AppSettings.of(
                    context,
                  ).dashboard.getLiveDashboard(scope: widget.scope);
                }),
                child: Text(l10n.text('retry')),
              ),
            ],
          ),
        );
      }
      return PswgDataScope(
        data: snapshot.data!,
        child: Builder(builder: widget.builder),
      );
    },
  );
}
