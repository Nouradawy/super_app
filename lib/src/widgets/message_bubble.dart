import 'package:flutter/material.dart';

/// Widget that displays the original message with Hero animation
class MessageBubble extends StatelessWidget {
  /// Creates a message widget.
  const MessageBubble({
    super.key,
    required this.id,
    required this.messageWidget,
    required this.alignment,
  });

  final String id;
  final Widget messageWidget;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Hero(
        tag: id,
        flightShuttleBuilder: (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
            ) {
          // The widget that is flying is the child of the destination Hero.
          final Hero toHero = toHeroContext.widget as Hero;

          // Wrap it in a Material widget to provide a clean canvas,
          // which prevents text rendering and layout issues in an Overlay.
          return ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Prevent user from actually scrolling
              child: Material(
                type: MaterialType.transparency,
                child: toHero.child,
              ),
            ),
          );
        },
        child: messageWidget,

      ),
    );
  }
}
