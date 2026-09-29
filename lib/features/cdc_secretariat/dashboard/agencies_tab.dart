import 'package:flutter/material.dart';

import '../../private_sector/dashboard/tabs/agencies_tab.dart' as pswg;

/// CDC GPSF keeps its own tab type while sharing the responsive API-backed UI.
class CdcSecretariatAgenciesTab extends StatelessWidget {
  const CdcSecretariatAgenciesTab({super.key});

  @override
  Widget build(BuildContext context) => const pswg.AgenciesTab();
}
