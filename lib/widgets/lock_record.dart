library social_media_recorder;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// This Class Represents Icon & Text to swipe up to lock recording
class LockRecord extends StatefulWidget {
  /// Object From Provider Notifier
  final SoundRecordNotifier soundRecorderState;

  final Widget? lockIcon;
  const LockRecord({
    this.lockIcon,
    required this.soundRecorderState,
    Key? key,
  }) : super(key: key);
  @override
  _LockRecordState createState() => _LockRecordState();
}

class _LockRecordState extends State<LockRecord> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    /// Only show when button is pressed
    if (!widget.soundRecorderState.buttonPressed) return const SizedBox.shrink();
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    double h = 76 - widget.soundRecorderState.heightPosition;
    if (h < 0) h = 0;
    if (h > 76) h = 76;
    
    return AnimatedPadding(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(widget.soundRecorderState.second % 2 == 0 ? 0 : 2),
      child: Transform.translate(
        offset: const Offset(0, -82),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
          opacity: widget.soundRecorderState.edge >= 50 ? 0 : 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 52,
              height: h,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.08) 
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.35) 
                        : Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.lockIcon ??
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 68,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Chevron up indicator
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            opacity: widget.soundRecorderState.second % 2 != 0 ? 0.4 : 1,
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              size: 18,
                            ),
                          ),
                          // Lock icon
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: widget.soundRecorderState.second % 2 == 0
                                ? Icon(
                                    Icons.lock_outline_rounded,
                                    key: const ValueKey('locked'),
                                    size: 18,
                                    color: isDark ? Colors.grey.shade200 : Colors.black87,
                                  )
                                : Icon(
                                    Icons.lock_open_rounded,
                                    key: const ValueKey('unlocked'),
                                    size: 18,
                                    color: isDark ? Colors.grey.shade200 : Colors.black87,
                                  ),
                          ),
                          const SizedBox(height: 2),
                          // Slide up text
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                "Slide up",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
