import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/src/controllers/reactions_controller.dart';
import 'package:flutter_chat_reactions/src/models/chat_reactions_config.dart';
import 'package:flutter_chat_reactions/src/models/menu_item.dart';
import 'package:flutter_chat_reactions/src/widgets/message_bubble.dart';
import 'package:flutter_chat_reactions/src/widgets/rections_row.dart';

/// A dialog widget that displays reactions and context menu options for a message.
class ReactionsDialogWidget extends StatefulWidget {
  final String messageId;
  final String? channelId;
  final String? messageCreatedAtIso;
  final String heroTag;
  final Widget messageWidget;
  final ReactionsController controller;
  final ChatReactionsConfig config;
  final Function(String) onReactionTap;
  final Function(MenuItem) onMenuItemTap;
  final Alignment alignment;

  const ReactionsDialogWidget({
    super.key,
    required this.messageId,
    this.channelId,
    this.messageCreatedAtIso,
    String? heroTag,
    required this.messageWidget,
    required this.controller,
    required this.config,
    required this.onReactionTap,
    required this.onMenuItemTap,
    this.alignment = Alignment.centerRight,
  }) : heroTag = heroTag ?? messageId;

  @override
  State<ReactionsDialogWidget> createState() => _ReactionsDialogWidgetState();
}

class _ReactionsDialogWidgetState extends State<ReactionsDialogWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.config.dialogBlurSigma,
          sigmaY: widget.config.dialogBlurSigma,
        ),
        child: Container(
          color: Colors.black.withAlpha(85),
          alignment: Alignment.center,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: widget.config.dialogPadding,
              physics: const BouncingScrollPhysics(),
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping inside the main column
                behavior: HitTestBehavior.translucent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReactionsRow(
                      reactions: widget.config.availableReactions,
                      alignment: widget.alignment,
                      reactionSize: widget.config.reactionSize,
                      selectedReaction:
                          widget.controller.getUserReaction(widget.messageId),
                      onReactionTap: (reaction, _) =>
                          _handleReactionTap(context, reaction),
                    ),
                    const SizedBox(height: 10),
                    MessageBubble(
                      id: widget.heroTag,
                      messageWidget: widget.messageWidget,
                      alignment: widget.alignment,
                    ),
                    if (widget.config.showContextMenu &&
                        widget.config.menuItems.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ContextMenuWidget(
                        menuItems: widget.config.menuItems,
                        alignment: widget.alignment,
                        onMenuItemTap: (item, _) =>
                            _handleMenuItemTap(context, item),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleReactionTap(BuildContext context, String reaction) {
    Navigator.of(context).pop();
    widget.onReactionTap(reaction);
  }

  void _handleMenuItemTap(BuildContext context, MenuItem item) {
    Navigator.of(context).pop();
    widget.onMenuItemTap(item);
  }
}

/// A state-of-the-art cinematic action menu for chat message interactions.
class ContextMenuWidget extends StatelessWidget {
  final List<MenuItem> menuItems;
  final Alignment alignment;
  final double menuWidth;
  final Function(MenuItem, int) onMenuItemTap;

  const ContextMenuWidget({
    super.key,
    required this.menuItems,
    required this.onMenuItemTap,
    this.alignment = Alignment.centerRight,
    this.menuWidth = 0.48,
  });

  Color _resolveActionColor(MenuItem item) {
    if (item.isDestructive) return const Color(0xFFEF4444);
    final label = item.label.toLowerCase().trim();
    if (label.contains('reply')) return const Color(0xFF3B82F6);
    if (label.contains('copy')) return const Color(0xFF06B6D4);
    if (label.contains('delete') || label.contains('report')) {
      return const Color(0xFFEF4444);
    }
    if (label.contains('edit')) return const Color(0xFFF59E0B);
    if (label.contains('forward') || label.contains('share')) {
      return const Color(0xFF10B981);
    }
    if (label.contains('star') || label.contains('pin')) {
      return const Color(0xFFEAB308);
    }
    return const Color(0xFF8B5CF6);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: alignment,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.85, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            alignment: alignment,
            child: child,
          );
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 205, maxWidth: 245),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(24)
                  : Colors.white.withAlpha(200),
              width: 1.2,
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1E293B).withAlpha(235),
                      const Color(0xFF0F172A).withAlpha(245),
                      const Color(0xFF0B111E).withAlpha(250),
                    ]
                  : [
                      Colors.white.withAlpha(250),
                      const Color(0xFFF8FAFC).withAlpha(245),
                      const Color(0xFFEFF6FF).withAlpha(240),
                    ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 90 : 25),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                // Cinematic subtle watermark icon
                Positioned(
                  right: -14,
                  bottom: -14,
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 76,
                    color: isDark
                        ? Colors.white.withAlpha(7)
                        : const Color(0xFF3B82F6).withAlpha(10),
                  ),
                ),

                // Vertical List of Action Rows
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < menuItems.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 0.6,
                          indent: 52,
                          endIndent: 12,
                          color: isDark
                              ? Colors.white.withAlpha(12)
                              : const Color(0xFFE2E8F0).withAlpha(140),
                        ),
                      _CinematicActionTile(
                        item: menuItems[i],
                        index: i,
                        actionColor: _resolveActionColor(menuItems[i]),
                        isDark: isDark,
                        onTap: () => onMenuItemTap(menuItems[i], i),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CinematicActionTile extends StatefulWidget {
  final MenuItem item;
  final int index;
  final Color actionColor;
  final bool isDark;
  final VoidCallback onTap;

  const _CinematicActionTile({
    required this.item,
    required this.index,
    required this.actionColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_CinematicActionTile> createState() => _CinematicActionTileState();
}

class _CinematicActionTileState extends State<_CinematicActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final actionColor = widget.actionColor;
    final isDark = widget.isDark;

    final Color textColor = item.isDestructive
        ? const Color(0xFFEF4444)
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          splashColor: actionColor.withAlpha(isDark ? 28 : 20),
          highlightColor: actionColor.withAlpha(isDark ? 16 : 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
            child: Row(
              children: [
                // Leading Icon Badge with glowing gradient tint
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.5),
                    gradient: LinearGradient(
                      colors: [
                        actionColor.withAlpha(isDark ? 45 : 30),
                        actionColor.withAlpha(isDark ? 20 : 14),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: actionColor.withAlpha(isDark ? 65 : 40),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 16,
                      color: actionColor,
                    ),
                  ),
                ),
                const SizedBox(width: 11),

                // Action Label
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                // Trailing subtle chevron
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.white.withAlpha(40)
                      : Colors.black.withAlpha(30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
