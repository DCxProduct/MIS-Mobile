import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/app_logo.dart';
import '../onboarding/get_started_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _openGetStarted);
  }

  void _openGetStarted() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) =>
            FadeTransition(opacity: animation, child: const GetStartedScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: AppLogo(width: 190))),
    );
  }
}
