library social_media_recorder;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// Used this class to show counter and mic Icon
class ShowCounter extends StatelessWidget {
  final SoundRecordNotifier soundRecorderState;
  final TextStyle? counterTextStyle;
  final Color? counterBackGroundColor;
  final double fullRecordPackageHeight;
  // ignore: sort_constructors_first
  const ShowCounter({
    required this.soundRecorderState,
    required this.fullRecordPackageHeight,
    Key? key,
    this.counterTextStyle,
    required this.counterBackGroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.25)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing red recording dot
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: soundRecorderState.second % 2 == 0 ? 1 : 0.3,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Timer text
              Text(
                "${soundRecorderState.minute.toString().padLeft(2, '0')}:${soundRecorderState.second.toString().padLeft(2, '0')}",
                style: counterTextStyle ??
                    TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
