import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';

/// A low-contrast animated ambient background for dark pages.
///
/// Movement is intentionally slow and the animation is disabled when the
/// platform's reduced-motion preference is enabled.
class AppAnimatedBackground extends StatefulWidget {
  const AppAnimatedBackground({
    super.key,
    this.baseColor = AppColors.background,
    this.intensity = 1,
  });

  final Color baseColor;
  final double intensity;

  @override
  State<AppAnimatedBackground> createState() => _AppAnimatedBackgroundState();
}

class _AppAnimatedBackgroundState extends State<AppAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = .25;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.intensity.clamp(0.0, 1.5).toDouble();

    return IgnorePointer(
      child: SizedBox.expand(
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(color: widget.baseColor),
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final angle = _controller.value * math.pi * 2;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.ambientBlue,
                              AppColors.background,
                              AppColors.ambientPlum,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -150,
                        right: -125,
                        child: Transform.translate(
                          offset: Offset(
                            math.cos(angle) * 34,
                            math.sin(angle) * 22,
                          ),
                          child: _AmbientOrb(
                            size: 360,
                            color: AppColors.primary.withValues(
                              alpha: .085 * intensity,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 270,
                        left: -190,
                        child: Transform.translate(
                          offset: Offset(
                            math.sin(angle * .85) * 28,
                            math.cos(angle * .85) * 45,
                          ),
                          child: _AmbientOrb(
                            size: 390,
                            color: AppColors.ambientIndigo.withValues(
                              alpha: .045 * intensity,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -180,
                        right: -160,
                        child: Transform.translate(
                          offset: Offset(
                            math.cos(angle * .7) * 38,
                            math.sin(angle * .7) * 26,
                          ),
                          child: _AmbientOrb(
                            size: 430,
                            color: AppColors.ambientPink.withValues(
                              alpha: .04 * intensity,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 1],
          ),
        ),
      ),
    );
  }
}
