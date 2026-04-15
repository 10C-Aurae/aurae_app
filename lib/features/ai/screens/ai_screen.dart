import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AIScreen extends StatelessWidget {
  const AIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.nav,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('AI Insights', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: AppColors.border),
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                      boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.40), blurRadius: 40, spreadRadius: 6)],
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                    child: const Text('AI Analysis',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tu análisis de aura aparecerá aquí',
                      style: TextStyle(color: AppColors.muted, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}