import 'package:flutter/material.dart';

import '../../shared/dashboard/widgets/category_totals_chart.dart';
import '../../shared/dashboard/widgets/pswg_live_dashboard.dart';

class CdcSecretariatCategoriesTab extends StatelessWidget {
  const CdcSecretariatCategoriesTab({super.key});

  @override
  Widget build(BuildContext context) => CategoryTotalsChart(
    categories: PswgDataScope.maybeOf(context)?.categories ?? const [],
  );
}
