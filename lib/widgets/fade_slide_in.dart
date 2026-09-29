import 'dart:async';

import 'package:flutter/material.dart';

/// Fades a child in while sliding it up slightly. Used for feed / search
/// tiles as they load.
///
/// [animate] is read once, when the tile is first created. Screens pass
/// `false` for tiles they have already animated, so tiles that scroll off and
/// back on screen don't replay the animation (which would look busy and cost
/// frames).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration delay;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.animate = true,
    this.delay = Duration.zero,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curved;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    if (!widget.animate) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}