import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/src/widgets/reactions_button.dart';

class ReactionsRow extends StatelessWidget {
  /// Creates a reactions row widget.
  const ReactionsRow({
    super.key,
    required this.reactions,
    required this.alignment,
    required this.onReactionTap,
    this.selectedReaction,
    this.reactionSize = 19.0,
  });

  final List<String> reactions;
  final Alignment alignment;
  final Function(String, int) onReactionTap;
  final String? selectedReaction;
  final double reactionSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: alignment,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            alignment: alignment,
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withAlpha(242)
                  : Colors.white.withAlpha(248),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(22)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 85 : 20),
                  spreadRadius: 0,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < reactions.length; i++)
                  ReactionButton(
                    reaction: reactions[i],
                    index: i,
                    size: reactionSize,
                    isSelected: selectedReaction == reactions[i],
                    onTap: onReactionTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
