import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

ImageProvider _resolveAvatarProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl == 'null' || avatarUrl.trim().isEmpty) {
    return const AssetImage('assets/defaultUser.webp');
  }
  final clean = avatarUrl.trim();
  if (clean.startsWith('assets/')) {
    return AssetImage(clean);
  }
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }
  final filePath = clean.startsWith('file://') ? clean.substring(7) : clean;
  try {
    final file = File(filePath);
    if (file.existsSync()) {
      return FileImage(file);
    }
  } catch (_) {}
  return const AssetImage('assets/defaultUser.webp');
}

class VoterDetails {
  final String id;
  final String? name;
  final String? avatarUrl;
  final DateTime? votedAt;

  const VoterDetails({
    required this.id,
    this.name,
    this.avatarUrl,
    this.votedAt,
  });
}

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
    this.expiresAt,
    this.pollProgressbarHeight = 36,
    this.pollOptionsWidth,
    this.pollOptionsBorderRadius,
    this.pollOptionsFillColor,
    this.pollOptionsSplashColor = Colors.grey,
    this.pollOptionsBorder,
    this.votedPollOptionsBorder,
    this.votedPollOptionsRadius,
    this.votedBackgroundColor = const Color(0xffEEF0EB),
    this.votedProgressColor = const Color(0xff84D2F6),
    this.leadingVotedProgessColor = const Color(0xff0496FF),
    this.voteInProgressColor = const Color(0xffEEF0EB),
    this.votedCheckmark,
    this.votedPercentageTextStyle,
    this.votedAnimationDuration = 1000,
    this.voteAnimation = false,
    this.allowToggleVote = false,
    this.showPercentage = true,
    this.isAnonymous = false,
    this.disableVoterDetails = false,
    this.onTotalVotesTap,
  }) : _isloading = false;

  /// The id of the poll.
  final String? pollId;

  /// Checks if a user has already voted in this poll.
  final bool hasVoted;

  final bool voteAnimation;

  /// Allows toggling/unvoting when the user already voted.
  final bool allowToggleVote;

  /// Always render percentage indicator on each option (even before poll end).
  final bool showPercentage;

  final bool isAnonymous;
  final bool disableVoterDetails;

  final bool _isloading;

  /// If a user has already voted in this poll.
  final String? userVotedOptionId;

  /// Callback when the total votes text is tapped.
  final Future<void> Function()? onTotalVotesTap;

  /// Callback when user votes.
  final Future<bool> Function(PollOption pollOption, int newTotalVotes) onVoted;

  /// The title of the poll.
  final Widget pollTitle;

  /// Poll options list.
  final List<PollOption> pollOptions;

  final double? heightBetweenTitleAndOptions;
  final double? heightBetweenOptions;

  final String? votesText;
  final TextStyle? votesTextStyle;
  final Widget? metaWidget;
  final String? createdBy;
  final String? userToVote;
  final DateTime? pollStartDate;
  final DateTime? expiresAt;
  final bool pollEnded;

  final double? pollProgressbarHeight;
  final double? pollOptionsWidth;
  final BorderRadius? pollOptionsBorderRadius;
  final BoxBorder? pollOptionsBorder;
  final BoxBorder? votedPollOptionsBorder;
  final Color? pollOptionsFillColor;
  final Color? pollOptionsSplashColor;
  final Radius? votedPollOptionsRadius;
  final Color? votedBackgroundColor;
  final Color? votedProgressColor;
  final Color? leadingVotedProgessColor;
  final Color? voteInProgressColor;
  final Widget? votedCheckmark;
  final TextStyle? votedPercentageTextStyle;
  final int votedAnimationDuration;
  final Widget? loadingWidget;

  void _showVotersBottomSheet(BuildContext context, PollOption option) {
    final List<VoterDetails> voterList = option.voters.isNotEmpty
        ? option.voters
        : option.voterAvatars
            .map((url) => VoterDetails(id: '', avatarUrl: url))
            .toList();

    if (voterList.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voters Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Option: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            Flexible(
                              child: DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                                child: option.title,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: voterList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final voter = voterList[index];
                    final String name = (voter.name != null && voter.name!.trim().isNotEmpty)
                        ? voter.name!
                        : 'Community Member';
                    final avatarUrl = voter.avatarUrl;

                    final ImageProvider provider = _resolveAvatarProvider(avatarUrl);

                    String formattedDate = '';
                    if (voter.votedAt != null) {
                      final dt = voter.votedAt!.toLocal();
                      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                      final period = dt.hour >= 12 ? 'PM' : 'AM';
                      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final monthStr = monthNames[dt.month - 1];
                      final minStr = dt.minute.toString().padLeft(2, '0');
                      formattedDate = '$monthStr ${dt.day}, ${dt.year} • $hour:$minStr $period';
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2D3A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: provider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (formattedDate.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllVotersBottomSheet(BuildContext context) {
    if (isAnonymous) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voters Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: pollOptions.length,
                  itemBuilder: (context, optIdx) {
                    final option = pollOptions[optIdx];
                    final List<VoterDetails> voterList = option.voters.isNotEmpty
                        ? option.voters
                        : option.voterAvatars
                            .map((url) => VoterDetails(id: '', avatarUrl: url))
                            .toList();

                    if (voterList.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Option: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                              Flexible(
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  child: option.title,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: voterList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final voter = voterList[index];
                              final String name = (voter.name != null && voter.name!.trim().isNotEmpty)
                                  ? voter.name!
                                  : 'Community Member';
                              final avatarUrl = voter.avatarUrl;

                              String formattedDate = '';
                              if (voter.votedAt != null) {
                                final dt = voter.votedAt!.toLocal();
                                final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                                final period = dt.hour >= 12 ? 'PM' : 'AM';
                                final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                final monthStr = monthNames[dt.month - 1];
                                final minStr = dt.minute.toString().padLeft(2, '0');
                                formattedDate = '$monthStr ${dt.day}, ${dt.year} • $hour:$minStr $period';
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2A2D3A) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Builder(builder: (context) {
                                      final bool hasValidUrl = avatarUrl != null &&
                                          avatarUrl != 'null' &&
                                          avatarUrl.isNotEmpty;
                                      return CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage: _resolveAvatarProvider(avatarUrl),
                                      );
                                    }),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          if (formattedDate.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.white54 : Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStackedAvatars(BuildContext context, PollOption option) {
    final List<VoterDetails> voterList = option.voters.isNotEmpty
        ? option.voters
        : option.voterAvatars
            .map((url) => VoterDetails(id: '', avatarUrl: url))
            .toList();

    if (voterList.isEmpty) return const SizedBox.shrink();

    const maxVisible = 3;
    final visibleVoters = voterList.take(maxVisible).toList();
    final remainingCount = voterList.length - visibleVoters.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF1E2028) : Colors.white;

    return InkWell(
      onTap: () => _showVotersBottomSheet(context, option),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              width: (visibleVoters.length * 16.0) + 8,
              child: Stack(
                children: List.generate(visibleVoters.length, (i) {
                  final avatarUrl = visibleVoters[i].avatarUrl;
                  final ImageProvider provider = _resolveAvatarProvider(avatarUrl);

                  return Positioned(
                    left: i * 14.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: provider,
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (remainingCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.indigo.shade900 : Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.indigoAccent : Colors.indigo.shade200,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.indigo.shade200 : Colors.indigo.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

    final pollStateSignature = pollOptions
        .map((option) => '${option.id}:${option.votes}')
        .join(',');

    useEffect(() {
      hasPollEnded.value = pollEnded;
      userHasVoted.value = hasVoted;
      votedOption.value = hasVoted == false
          ? null
          : pollOptions.cast<PollOption?>().firstWhere(
                (pollOption) => pollOption?.id == userVotedOptionId,
                orElse: () => null,
              );
      return null;
    }, [pollEnded, hasVoted, userVotedOptionId, pollStateSignature]);

    final int displayedTotalVotes = pollOptions.fold(
      0,
      (acc, option) => acc + option.votes,
    );

    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt!);
    final bool effectivePollEnded = hasPollEnded.value || isExpired;

    return Column(
      key: ValueKey(pollId),
      crossAxisAlignment: CrossAxisAlignment.start,
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
              }

              final double percentage = displayedTotalVotes == 0
                  ? 0.0
                  : ((pollOption.votes / displayedTotalVotes) * 100);
              final String percentageStr = '${percentage.round()}%';

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: pollOption.title),
                      if (showPercentage) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: votedOption.value?.id == pollOption.id
                                ? leadingVotedProgessColor?.withValues(alpha: 0.15) ?? Colors.blue.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            percentageStr,
                            style: votedPercentageTextStyle ??
                                TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: votedOption.value?.id == pollOption.id
                                      ? leadingVotedProgessColor
                                      : Colors.grey.shade700,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      _buildStackedAvatars(context, pollOption),
                      Checkbox(
                        value: votedOption.value?.id == pollOption.id,
                        shape: const CircleBorder(),
                        onChanged: (isLoading.value || (effectivePollEnded && !allowToggleVote))
                            ? null
                            : (bool? _) async {
                                if (isLoading.value || (effectivePollEnded && !allowToggleVote)) return;

                                final bool previouslyVoted = userHasVoted.value;
                                final PollOption? previousVotedOption = votedOption.value;
                                final bool isUnvoteAction =
                                    previouslyVoted && previousVotedOption?.id == pollOption.id;

                                // Optimistic selection for visual feedback
                                votedOption.value = isUnvoteAction ? null : pollOption;

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
                    margin: EdgeInsets.only(
                      bottom: heightBetweenOptions ?? 8,
                    ),
                    decoration: votedPollOptionsBorder != null
                        ? BoxDecoration(
                            border: votedPollOptionsBorder,
                            borderRadius: BorderRadius.all(
                              votedPollOptionsRadius ?? const Radius.circular(8),
                            ),
                          )
                        : null,
                    child: LinearPercentIndicator(
                      width: pollOptionsWidth,
                      lineHeight: pollProgressbarHeight!,
                      barRadius: votedPollOptionsRadius ?? const Radius.circular(8),
                      padding: EdgeInsets.zero,
                      percent: displayedTotalVotes == 0
                          ? 0
                          : (pollOption.votes / displayedTotalVotes).clamp(0.0, 1.0),
                      animation: voteAnimation,
                      animationDuration: votedAnimationDuration,
                      animateFromLastPercent: true,
                      animateToInitialPercent: false,
                      addAutomaticKeepAlive: true,
                      backgroundColor: votedBackgroundColor,
                      progressColor: votedOption.value?.id == pollOption.id
                          ? leadingVotedProgessColor
                          : votedProgressColor,
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 8),
        Center(
          child: InkWell(
            onTap: disableVoterDetails
                ? null
                : () async {
                    if (onTotalVotesTap != null) {
                      await onTotalVotesTap!();
                    }
                    if (context.mounted) {
                      _showAllVotersBottomSheet(context);
                    }
                  },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (disableVoterDetails ? Colors.grey : (leadingVotedProgessColor ?? const Color(0xff0496FF))).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (disableVoterDetails ? Colors.grey : (leadingVotedProgessColor ?? const Color(0xff0496FF))).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'View Votes',
                style: votesTextStyle ??
                    TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: disableVoterDetails ? Colors.grey : (leadingVotedProgessColor ?? const Color(0xff0496FF)),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeRemaining(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'Closed';
    if (diff.inDays > 0) return 'in ${diff.inDays}d';
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'in ${diff.inMinutes}m';
    return 'in <1m';
  }
}

class PollOption {
  PollOption({
    this.id,
    required this.title,
    required this.votes,
    this.voterAvatars = const [],
    this.voters = const [],
  });

  final String? id;
  final Widget title;
  int votes;
  final List<String> voterAvatars;
  final List<VoterDetails> voters;
}

String _getInitials(String name) {
  if (name.trim().isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length > 1) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  if (name.length > 1) {
    return name.substring(0, 2).toUpperCase();
  }
  return name[0].toUpperCase();
}

Color _colorFromName(String name) {
  if (name.trim().isEmpty) return Colors.grey;
  final int hash = name.hashCode;
  final double hue = (hash % 360).toDouble();
  return HSVColor.fromAHSV(1.0, hue, 0.6, 0.8).toColor();
}


