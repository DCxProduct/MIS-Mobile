import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'filter_models.dart';

/// Passes applied queries through existing composed report tabs to their loaders.
class ApiFilterScope extends InheritedWidget {
  const ApiFilterScope({
    super.key,
    required this.queries,
    this.selections = const {},
    required super.child,
  });
  final Map<String, Map<String, String>> queries;
  final Map<String, FilterSelection> selections;
  static FilterSelection selection(BuildContext context, String resource) =>
      context
          .dependOnInheritedWidgetOfExactType<ApiFilterScope>()
          ?.selections[resource] ??
      FilterSelection();
  static Map<String, String> query(BuildContext context, String resource) =>
      context
          .dependOnInheritedWidgetOfExactType<ApiFilterScope>()
          ?.queries[resource] ??
      const {};
  @override
  bool updateShouldNotify(ApiFilterScope oldWidget) =>
      selections != oldWidget.selections ||
      queries.keys
          .toSet()
          .difference(oldWidget.queries.keys.toSet())
          .isNotEmpty ||
      oldWidget.queries.keys
          .toSet()
          .difference(queries.keys.toSet())
          .isNotEmpty ||
      queries.keys.any(
        (key) => !mapEquals(queries[key], oldWidget.queries[key]),
      );
}
