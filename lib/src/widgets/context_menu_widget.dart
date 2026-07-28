import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/src/controllers/reactions_controller.dart';
import 'package:flutter_chat_reactions/src/models/chat_reactions_config.dart';
import 'package:flutter_chat_reactions/src/models/menu_item.dart';
import 'package:flutter_chat_reactions/src/widgets/message_bubble.dart';
import 'package:flutter_chat_reactions/src/widgets/rections_row.dart';


/// A dialog widget that displays reactions and context menu options for a message.
///
/// This widget creates a modal dialog with three main sections:
/// - A row of reaction emojis that can be tapped
/// - The original message (displayed using a Hero animation)
/// - A context menu with customizable options
class ReactionsDialogWidget extends StatefulWidget {
  /// Unique identifier for the message (used for data lookups).
  final String messageId;
  final String? channelId;
  final String? messageCreatedAtIso;

  /// Tag used for the Hero animation — must match the tag in [ChatMessageWrapper].
  /// Defaults to [messageId] for backwards compatibility.
  final String heroTag;

  /// The widget displaying the message content.
  final Widget messageWidget;

  /// Controller to manage reaction state.
  final ReactionsController controller;

  /// Configuration for the reactions dialog.
  final ChatReactionsConfig config;

  /// Callback triggered when a reaction is selected.
  final Function(String) onReactionTap;

  /// Callback triggered when a context menu item is selected.
  final Function(MenuItem) onMenuItemTap;

  /// Alignment of the dialog components.
  final Alignment alignment;

  /// Creates a reactions dialog widget.
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

    return BackdropFilter(
      filter: ImageFilter.blur(
          sigmaX: widget.config.dialogBlurSigma, sigmaY: widget.config.dialogBlurSigma),
      child: Center(
        child: Padding(
          padding: widget.config.dialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReactionsRow(
                reactions: widget.config.availableReactions,
                alignment: widget.alignment,
                onReactionTap: (reaction, _) =>
                    _handleReactionTap(context, reaction),
              ),
              const SizedBox(height: 10),
              MessageBubble(
                id: widget.heroTag,
                messageWidget: widget.messageWidget,
                alignment: widget.alignment,
              ),
              if (widget.config.showContextMenu) ...[
                const SizedBox(height: 10),
                ContextMenuWidget(
                  menuItems: widget.config.menuItems,
                  alignment: widget.alignment,
                  onMenuItemTap: (item, _) => _handleMenuItemTap(context, item),
                ),
              ],
            ],
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
    this.menuWidth = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: MediaQuery.of(context).size.width * menuWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2E2E2E)
              : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: menuItems
              .map(
                (item) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onMenuItemTap(item, menuItems.indexOf(item)),
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: item.isDestructive
                                  ? Colors.red
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            item.icon,
                            color: item.isDestructive
                                ? Colors.red
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}



