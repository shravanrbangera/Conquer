import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum CyberButtonVariant { cyan, crimson, emerald, gold, outline }

class CyberButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CyberButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  const CyberButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = CyberButtonVariant.cyan,
    this.isLoading = false,
    this.width,
    this.height = 50.0,
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton> {
  bool _isPressed = false;

  Color get _accentColor {
    switch (widget.variant) {
      case CyberButtonVariant.cyan:
        return AppColors.neonCyan;
      case CyberButtonVariant.crimson:
        return AppColors.neonCrimson;
      case CyberButtonVariant.emerald:
        return AppColors.neonEmerald;
      case CyberButtonVariant.gold:
        return AppColors.neonGold;
      case CyberButtonVariant.outline:
        return AppColors.neonCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOutline = widget.variant == CyberButtonVariant.outline;
    final accent = _accentColor;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isOutline
                ? Colors.transparent
                : accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled ? accent : AppColors.textDim,
              width: 1.5,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: _isPressed ? 0.4 : 0.2),
                      blurRadius: _isPressed ? 20 : 12,
                      spreadRadius: _isPressed ? 2 : 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: accent),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : AppColors.textDim,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
