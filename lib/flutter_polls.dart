library flutter_polls;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

// FlutterPolls widget.
// This widget is used to display a poll.
// It can be used in any way and also in a [ListView] or [Column].
class FlutterPolls extends HookWidget {
  const FlutterPolls({
    super.key,
    required this.pollId,
    this.hasVoted = false,
    this.userVotedOptionId,
    required this.onVoted,
    this.loadingWidget,
    required this.pollTitle,
    this.heightBetweenTitleAndOptions = 10,
    required this.pollOptions,
    this.heightBetweenOptions,
    this.votesText = 'Votes',
    this.votesTextStyle,
    this.metaWidget,
    this.createdBy,
    this.userToVote,
    this.pollStartDate,
    this.pollEnded = false,
    this.pollProgressbarHeight = 36,
    this.pollOptionsWidth,
    this.pollOptionsBorderRadius,
    this.pollOptionsFillColor,
    this.pollOptionsSplashColor = Colors.grey,
    this.pollOptionsBorder,
    this.votedPollOptionsBorder = null,
    this.votedPollOptionsRadius,
    this.votedBackgroundColor = const Color(0xffEEF0EB),
    this.votedProgressColor = const Color(0xff84D2F6),
    this.leadingVotedProgessColor = const Color(0xff0496FF),
    this.voteInProgressColor = const Color(0xffEEF0EB),
    this.votedCheckmark,
    this.votedPercentageTextStyle,
    this.votedAnimationDuration = 1000,
    this.allowToggleVote = false,
  }) : _isloading = false;

  /// The id of the poll.
  /// This id is used to identify the poll.
  /// It is also used to check if a user has already voted in this poll.
  final String? pollId;

  /// Checks if a user has already voted in this poll.
  /// If this is set to true, the user can't vote in this poll.
  /// Default value is false.
  /// [userVotedOptionId] must also be provided if this is set to true.
  final bool hasVoted;

  /// Allows toggling/unvoting when the user already voted.
  /// Default: false. Set to true if you want taps to still call `onVoted`
  /// when `hasVoted` is true, enabling your backend handler to toggle/unvote.
  final bool allowToggleVote;

  /// Checks if the [onVoted] execution is completed or not
  /// it is true, if the [onVoted] exection is ongoing and
  /// false, if completed
  final bool _isloading;

  /// If a user has already voted in this poll.
  /// It is ignored if [hasVoted] is set to false or not set at all.
  final String? userVotedOptionId;

  /// An asynchronous callback for HTTP call feature
  /// Called when the user votes for an option.
  /// The index of the option that the user voted for is passed as an argument.
  /// If the user has already voted, this callback is not called.
  /// If the user has not voted, this callback is called.
  /// If the callback returns true, the tapped [PollOption] is considered as voted.
  /// Else Nothing happens,
  final Future<bool> Function(PollOption pollOption, int newTotalVotes) onVoted;

  /// The title of the poll. Can be any widget with a bounded size.
  final Widget pollTitle;

  /// Data format for the poll options.
  /// Must be a list of [PollOptionData] objects.
  /// The list must have at least two elements.
  /// The first element is the option that is selected by default.
  /// The second element is the option that is selected by default.
  /// The rest of the elements are the options that are available.
  /// The list can have any number of elements.
  ///
  /// Poll options are displayed in the order they are in the list.
  /// example:
  ///
  /// pollOptions = [
  ///
  ///  PollOption(id: 1, title: Text('Option 1'), votes: 2),
  ///
  ///  PollOption(id: 2, title: Text('Option 2'), votes: 5),
  ///
  ///  PollOption(id: 3, title: Text('Option 3'), votes: 9),
  ///
  ///  PollOption(id: 4, title: Text('Option 4'), votes: 2),
  ///
  /// ]
  ///
  /// The [id] of each poll option is used to identify the option when the user votes.
  /// The [title] of each poll option is displayed to the user.
  /// [title] can be any widget with a bounded size.
  /// The [votes] of each poll option is the number of votes that the option has received.
  final List<PollOption> pollOptions;

  /// The height between the title and the options.
  /// The default value is 10.
  final double? heightBetweenTitleAndOptions;

  /// The height between the options.
  /// The default value is 0.
  final double? heightBetweenOptions;

  /// Votes text. Can be "Votes", "Votos", "Ibo" or whatever language.
  /// If not specified, "Votes" is used.
  final String? votesText;

  /// [votesTextStyle] is the text style of the votes text.
  /// If not specified, the default text style is used.
  /// Styles for [totalVotes] and [votesTextStyle].
  final TextStyle? votesTextStyle;

  /// [metaWidget] is displayed at the bottom of the poll.
  /// It can be any widget with an unbounded size.
  /// If not specified, no meta widget is displayed.
  /// example:
  /// metaWidget = Text('Created by: $createdBy')
  final Widget? metaWidget;

  /// Who started the poll.
  final String? createdBy;

  /// Current user about to vote.
  final String? userToVote;

  /// The date the poll was created.
  final DateTime? pollStartDate;

  /// If poll is closed.
  final bool pollEnded;

  /// Height of a [PollOption].
  /// The height is the same for all options.
  /// Defaults to 36.
  final double? pollProgressbarHeight;

  /// Width of a [PollOption].
  /// The width is the same for all options.
  /// If not specified, the width is set to the width of the poll.
  /// If the poll is not wide enough, the width is set to the width of the poll.
  /// If the poll is too wide, the width is set to the width of the poll.
  final double? pollOptionsWidth;

  /// Border radius of a [PollOption].
  /// The border radius is the same for all options.
  /// Defaults to 0.
  final BorderRadius? pollOptionsBorderRadius;

  /// Border of a [PollOption].
  /// The border is the same for all options.
  /// Defaults to null.
  /// If null, the border is not drawn.
  final BoxBorder? pollOptionsBorder;

  /// Border of a [PollOption] when the user has voted.
  /// The border is the same for all options.
  /// Defaults to null.
  /// If null, the border is not drawn.
  final BoxBorder? votedPollOptionsBorder;

  /// Color of a [PollOption].
  /// The color is the same for all options.
  /// Defaults to [Colors.blue].
  final Color? pollOptionsFillColor;

  /// Splashes a [PollOption] when the user taps it.
  /// Defaults to [Colors.grey].
  final Color? pollOptionsSplashColor;

  /// Radius of the border of a [PollOption] when the user has voted.
  /// Defaults to Radius.circular(8).
  final Radius? votedPollOptionsRadius;

  /// Color of the background of a [PollOption] when the user has voted.
  /// Defaults to [const Color(0xffEEF0EB)].
  final Color? votedBackgroundColor;

  /// Color of the progress bar of a [PollOption] when the user has voted.
  /// Defaults to [const Color(0xff84D2F6)].
  final Color? votedProgressColor;

  /// Color of the leading progress bar of a [PollOption] when the user has voted.
  /// Defaults to [const Color(0xff0496FF)].
  final Color? leadingVotedProgessColor;

  /// Color of the background of a [PollOption] when the user clicks to vote and its still in progress.
  /// Defaults to [const Color(0xffEEF0EB)].
  final Color? voteInProgressColor;

  /// Widget for the checkmark of a [PollOption] when the user has voted.
  /// Defaults to [Icons.check_circle_outline_rounded].
  final Widget? votedCheckmark;

  /// TextStyle of the percentage of a [PollOption] when the user has voted.
  final TextStyle? votedPercentageTextStyle;

  /// Animation duration of the progress bar of the [PollOption]'s when the user has voted.
  /// Defaults to 1000 milliseconds.
  /// If the animation duration is too short, the progress bar will not animate.
  /// If you don't want the progress bar to animate, set this to 0.
  final int votedAnimationDuration;

  /// Loading animation widget for [PollOption] when [onVoted] callback is invoked
  /// Defaults to [CircularProgressIndicator]
  /// Visible until the [onVoted] execution is completed,
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context) {
    final hasPollEnded = useState(pollEnded);
    final userHasVoted = useState(hasVoted);
    final isLoading = useState(_isloading);
    final votedOption = useState<PollOption?>(
      hasVoted == false
          ? null
          : pollOptions.cast<PollOption?>().firstWhere(
            (pollOption) => pollOption?.id == userVotedOptionId,
        orElse: () => null,
      ),
    );

    final int displayedTotalVotes = pollOptions.fold(
      0,
          (acc, option) => acc + option.votes,
    );
    

    // showResults is true when we should display non-interactive results
    // If allowToggleVote == true we still show the interactive UI so taps are allowed.
    final bool showResults = (userHasVoted.value || hasPollEnded.value) && !allowToggleVote;

    return Column(
      key: ValueKey(pollId),
      children: [
        pollTitle,
        SizedBox(height: heightBetweenTitleAndOptions),
        if (pollOptions.length < 2)
          throw ('>>>Flutter Polls: Poll must have at least 2 options.<<<')
        else
          ...pollOptions.map(
            (pollOption) {
              if (hasVoted && userVotedOptionId == null) {
                throw ('>>>Flutter Polls: User has voted but [userVotedOptionId] is null.<<<');
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: pollOption.title),
                        if (pollOption.voterAvatars.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ...List.generate(
                            pollOption.voterAvatars.length.clamp(0, 2),
                                (i) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: pollOption.voterAvatars[i] == "null"? const AssetImage("assets/defaultUser.webp") as ImageProvider :NetworkImage(pollOption.voterAvatars[i]),
                              ),
                            ),
                          ),
                        ],
                        Checkbox(
                          value: votedOption.value?.id == pollOption.id,
                          shape: const CircleBorder(),
                          onChanged: (isLoading.value || (hasPollEnded.value && !allowToggleVote))
                              ? null
                              : (bool? _) async {
                            if (isLoading.value || (hasPollEnded.value && !allowToggleVote)) return;

                            final bool previouslyVoted = userHasVoted.value;
                            final PollOption? previousVotedOption = votedOption.value;
                            final bool isUnvoteAction =
                                previouslyVoted && previousVotedOption?.id == pollOption.id;

                            // Optimistic selection for visual feedback
                            votedOption.value = pollOption;

                            isLoading.value = true;
                            final bool success = await onVoted(
                              pollOption,
                              displayedTotalVotes,
                            );
                            isLoading.value = false;

                            if (success) {
                              if (isUnvoteAction) {
                                if (pollOption.votes > 0) pollOption.votes--;
                                userHasVoted.value = false;
                                votedOption.value = null;
                              } else if (previouslyVoted &&
                                  previousVotedOption != null &&
                                  previousVotedOption.id != pollOption.id) {
                                if (previousVotedOption.votes > 0) previousVotedOption.votes--;
                                pollOption.votes++;
                                userHasVoted.value = true;
                                votedOption.value = pollOption;
                              } else {
                                pollOption.votes++;
                                userHasVoted.value = true;
                              }
                            } else {
                              // Revert on failure
                              votedOption.value = previousVotedOption;
                              userHasVoted.value = previouslyVoted;
                            }
                          },
                          activeColor: leadingVotedProgessColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        ),
                      ],
                    ),
                    Container(
                      key: UniqueKey(),
                      margin: EdgeInsets.only(
                        bottom: heightBetweenOptions ?? 8,
                      ),
                      decoration: votedPollOptionsBorder != null
                          ? BoxDecoration(
                        border: votedPollOptionsBorder,
                        borderRadius: BorderRadius.all(
                          votedPollOptionsRadius ??
                              const Radius.circular(8),
                        ),
                      )
                          : null,
                      child: LinearPercentIndicator(
                        width: pollOptionsWidth,
                        lineHeight: pollProgressbarHeight!,
                        barRadius: votedPollOptionsRadius ??
                            const Radius.circular(8),
                        padding: EdgeInsets.zero,
                        percent: displayedTotalVotes == 0
                            ? 0
                            : (pollOption.votes / displayedTotalVotes)
                            .clamp(0.0, 1.0),
                        animation: true,
                        animationDuration: votedAnimationDuration,
                        backgroundColor: votedBackgroundColor,
                        progressColor: votedOption.value?.id == pollOption.id ? leadingVotedProgessColor : votedProgressColor,
                      ),
                    ),
                  ],);
              }
            },
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${displayedTotalVotes} $votesText',
              style: votesTextStyle ??
                  const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Expanded(
              child: metaWidget ?? Container(),
            ),
          ],
        ),
      ],
    );
  }
}

class PollOption {
  PollOption({
    this.id,
    required this.title,
    required this.votes,
    this.voterAvatars = const [],
  });

  final String? id;
  final Widget title;
  int votes;
  final List<String> voterAvatars;
}
