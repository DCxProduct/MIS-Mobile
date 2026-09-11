import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../dashboard/dashboard_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    Timer(const Duration(seconds: 2), _openDashboard);
  }

  void _openDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              Expanded(
                child: Center(child: _AnimatedDots(controller: _controller)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final phase = (controller.value + index * 0.16) % 1;
            final active = phase < 0.5;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: active ? 14 : 12,
              height: active ? 14 : 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.accent(context).withValues(alpha: 0.72)
                    : const Color(0xFFD7D7D7),
              ),
            );
          }),
        );
      },
    );
  }
}
