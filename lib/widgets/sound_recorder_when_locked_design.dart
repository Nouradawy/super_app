library social_media_recorder;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';
import 'package:social_media_recorder/widgets/show_counter.dart';

// ignore: must_be_immutable
class SoundRecorderWhenLockedDesign extends StatelessWidget {
  final double fullRecordPackageHeight;
  final SoundRecordNotifier soundRecordNotifier;
  final String? cancelText;
  final Function sendRequestFunction;
  final Function(String time)? stopRecording;
  final Widget? recordIconWhenLockedRecord;
  final TextStyle? cancelTextStyle;
  final TextStyle? counterTextStyle;
  final Color recordIconWhenLockBackGroundColor;
  final Color? counterBackGroundColor;
  final Color? cancelTextBackGroundColor;
  final Widget? sendButtonIcon;
  final Widget Function(List<double> amplitudes)? waveformBuilder;
  // ignore: sort_constructors_first
  const SoundRecorderWhenLockedDesign({
    Key? key,
    required this.fullRecordPackageHeight,
    required this.sendButtonIcon,
    required this.soundRecordNotifier,
    required this.cancelText,
    required this.sendRequestFunction,
    this.stopRecording,
    required this.recordIconWhenLockedRecord,
    required this.cancelTextStyle,
    required this.counterTextStyle,
    required this.recordIconWhenLockBackGroundColor,
    required this.counterBackGroundColor,
    required this.cancelTextBackGroundColor,
    this.waveformBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDark 
        ? const Color(0xFF1C1C1E) 
        : Colors.white;
    final Color iconColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: cancelTextBackGroundColor ?? surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ShowCounter(
                  soundRecorderState: soundRecordNotifier,
                  counterTextStyle: counterTextStyle,
                  counterBackGroundColor: counterBackGroundColor,
                  fullRecordPackageHeight: fullRecordPackageHeight,
                ),
                if (waveformBuilder != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ValueListenableBuilder<List<double>>(
                        valueListenable: soundRecordNotifier.waveformNotifier,
                        builder: (context, amplitudes, child) {
                          return SizedBox(
                            height: 40,
                            child: waveformBuilder!(amplitudes),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Delete button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      soundRecordNotifier.resetEdgePadding();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.delete_outline_rounded, 
                        color: Colors.redAccent, 
                        size: 26,
                      ),
                    ),
                  ),
                ),
                // Pause/Resume button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      if (soundRecordNotifier.isPaused) {
                        soundRecordNotifier.resumeRecording();
                      } else {
                        soundRecordNotifier.pauseRecording();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        soundRecordNotifier.isPaused 
                            ? Icons.play_arrow_rounded 
                            : Icons.pause_rounded,
                        color: iconColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Send button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      soundRecordNotifier.isShow = false;
                      soundRecordNotifier.finishRecording();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded, 
                        color: Colors.white, 
                        size: 22,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
