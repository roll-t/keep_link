import 'dart:async';

import 'package:flutter/material.dart';

/// A small, reusable fade/slide transition for content entering a page.
class AppEntranceAnimation extends StatefulWidget {
  const AppEntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 560),
    this.beginOffset = const Offset(0, .06),
    this.beginScale = .985,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;
  final Curve curve;

  @override
  State<AppEntranceAnimation> createState() => _AppEntranceAnimationState();
}

class _AppEntranceAnimationState extends State<AppEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }

    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    final offset = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(animation);
    final scale = Tween<double>(
      begin: widget.beginScale,
      end: 1,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: offset,
        child: ScaleTransition(scale: scale, child: widget.child),
      ),
    );
  }
}
