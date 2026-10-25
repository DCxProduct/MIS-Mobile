import 'package:flutter/material.dart';
import '../../private_sector/dashboard/dashboard_screen.dart';

/// Uses the same live API, filters and charts as Private Sector.
class LineMinistryDashboardScreen extends StatelessWidget {
  const LineMinistryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const DashboardPage(initialScopeTab: 1);
}
