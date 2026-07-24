library social_media_recorder;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// used to show mic and show dragg text when
/// press into record icon
class ShowMicWithText extends StatelessWidget {
  final bool shouldShowText;
  final String? slideToCancelText;
  final SoundRecordNotifier soundRecorderState;
  final TextStyle? slideToCancelTextStyle;
  final Color? backGroundColor;
  final Widget? recordIcon;
  final Color? counterBackGroundColor;
  final double fullRecordPackageHeight;
  final double initRecordPackageWidth;
  final double initialButtonWidth;
  final double initialButtonHight;
  final double finalButtonHight;
  final double finalButtonWidth;
  final Color? micBackgroundColor;
  final bool isDark;
  final Widget Function(List<double> amplitudes)? waveformBuilder;


  // ignore: sort_constructors_first
  ShowMicWithText({
    required this.backGroundColor,
    required this.initRecordPackageWidth,
    required this.fullRecordPackageHeight,
    Key? key,
    required this.shouldShowText,
    required this.soundRecorderState,
    required this.slideToCancelTextStyle,
    required this.slideToCancelText,
    required this.recordIcon,
    required this.counterBackGroundColor,
    required this.initialButtonWidth,
    required this.initialButtonHight,
    required this.finalButtonHight,
    required this.finalButtonWidth,
    this.micBackgroundColor,
    this.isDark =false,
    this.waveformBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ── EXACT ORIGINAL mic button structure — DO NOT MODIFY ──
    return Transform.translate(
      offset: Offset(-10, 5),
      child: Row(
        mainAxisAlignment: !soundRecorderState.buttonPressed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.scale(
                key: soundRecorderState.key,
                scale: soundRecorderState.buttonPressed ? 1.3 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(600),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                    width: soundRecorderState.buttonPressed
                        ? finalButtonWidth
                        : initialButtonWidth,
                    height: soundRecorderState.buttonPressed
                        ? finalButtonHight
                        : initialButtonWidth,
                    child: Container(
                      color: micBackgroundColor ?? Colors.green,
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: recordIcon ??
                            Icon(
                              Icons.mic,
                              size: 25,
                              color: Colors.black

                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // ── Enhanced recording overlay content ──
          if (shouldShowText)
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Waveform — padding adjusted: more at beginning (right/mic), less at end (left/counter)
                    if (waveformBuilder != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 14.0, left: 4.0),
                        child: ValueListenableBuilder<List<double>>(
                          valueListenable: soundRecorderState.waveformNotifier,
                          builder: (context, amplitudes, child) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width * 0.55,
                              height: 32,
                              child: waveformBuilder!(amplitudes),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Slide to cancel hint — animated shimmer text aligned to the right near mic button
                    Padding(
                      padding: const EdgeInsets.only(right: 14.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          DefaultTextStyle(
                            style: const TextStyle(fontSize: 11.0),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                ColorizeAnimatedText(
                                  slideToCancelText ?? "Slide to cancel",
                                  textStyle: slideToCancelTextStyle ??
                                      TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                  colors: isDark
                                      ? [
                                          Colors.grey.shade600,
                                          Colors.grey.shade200,
                                          Colors.white,
                                          Colors.grey.shade200,
                                          Colors.grey.shade600,
                                        ]
                                      : [
                                          Colors.grey.shade500,
                                          Colors.grey.shade900,
                                          Colors.black,
                                          Colors.grey.shade900,
                                          Colors.grey.shade500,
                                        ],
                                ),
                              ],
                              isRepeatingAnimation: true,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
