import 'dart:math';
import 'package:flutter/material.dart';

class LiveEqualizer extends StatefulWidget {
  final Color color;
  final double size;

  const LiveEqualizer({
    super.key,
    this.color = const Color(0xFF10B981),
    this.size = 14.0,
  });

  @override
  State<LiveEqualizer> createState() => _LiveEqualizerState();
}

class _LiveEqualizerState extends State<LiveEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final h1 = 0.3 + 0.7 * sin(t * pi);
        final h2 = 0.2 + 0.8 * sin((t + 0.33) * pi % pi);
        final h3 = 0.4 + 0.6 * sin((t + 0.66) * pi % pi);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(h1),
            const SizedBox(width: 2),
            _buildBar(h2),
            const SizedBox(width: 2),
            _buildBar(h3),
          ],
        );
      },
    );
  }

  Widget _buildBar(double heightFraction) {
    return Container(
      width: 2.5,
      height: (widget.size * heightFraction).clamp(3.0, widget.size),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(1.5),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.5),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
