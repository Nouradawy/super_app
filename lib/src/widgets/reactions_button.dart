import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Single reaction button with spring entrance, micro-scale press interaction,
/// and active selection indicator.
class ReactionButton extends StatefulWidget {
  /// Creates a reaction button widget.
  const ReactionButton({
    super.key,
    required this.reaction,
    required this.index,
    required this.onTap,
    this.isSelected = false,
    this.size = 19.0,
  });

  final String reaction;
  final int index;
  final Function(String, int) onTap;
  final bool isSelected;
  final double size;

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlus = widget.reaction == '➕';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (widget.index * 30)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale * (_isPressed ? 1.3 : 1.0),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap(widget.reaction, widget.index);
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isSelected
                ? (isDark
                    ? Colors.white.withAlpha(45)
                    : Colors.blue.withAlpha(35))
                : Colors.transparent,
          ),
          child: isPlus
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withAlpha(30)
                          : Colors.black.withAlpha(15),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 15,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                )
              : Text(
                  widget.reaction,
                  style: TextStyle(
                    fontSize: widget.size,
                    height: 1.1,
                  ),
                ),
        ),
      ),
    );
  }
}
