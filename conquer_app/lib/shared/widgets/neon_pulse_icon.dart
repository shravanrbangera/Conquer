import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NeonPulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const NeonPulseIcon({
    super.key,
    required this.icon,
    this.color = AppColors.neonCyan,
    this.size = 28,
  });

  @override
  State<NeonPulseIcon> createState() => _NeonPulseIconState();
}

class _NeonPulseIconState extends State<NeonPulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size * 1.5,
                  height: widget.size * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: _opacityAnimation.value),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.2),
              border: Border.all(color: widget.color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(widget.icon, size: widget.size, color: widget.color),
          ),
        ],
      ),
    );
  }
}
