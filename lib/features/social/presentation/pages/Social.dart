import 'dart:io';

import 'package:WhatsUnity/core/theme/lightTheme.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';

import 'package:WhatsUnity/features/social/presentation/bloc/social_cubit.dart';
import 'package:WhatsUnity/features/social/presentation/bloc/social_state.dart';
import 'package:WhatsUnity/features/social/domain/entities/post.dart';
import '../../../chat/presentation/widgets/chatWidget/Details/ChatMember.dart';
import '../../../chat/presentation/widgets/chatWidget/GeneralChat/GeneralChat.dart';
import '../../../../core/config/Enums.dart';
import '../../../../core/config/supabase.dart';
import '../../../../core/constants/Constants.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class Social extends StatefulWidget {
  Social({super.key});

  @override
  State<Social> createState() => _SocialState();
}

class _SocialState extends State<Social> {
  final TextEditingController postHead = TextEditingController();
  final List<String> moreMenu = ["Delete"];
  /// Avoids missing the first fetch when [selectedCompoundId] is not ready on the first frame after cold start.
  int? _postsFetchedForCompoundId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserRole = authState.role;
        final currentMember = authState.currentUser;
        final members = authState.chatMembers;
        final memberById = {for (final m in members) m.id.trim(): m};
        final selectedCompoundId = authState.selectedCompoundId;

        if (selectedCompoundId != null && selectedCompoundId != _postsFetchedForCompoundId) {
          _postsFetchedForCompoundId = selectedCompoundId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<SocialCubit>().getPosts(selectedCompoundId);
          });
        }

        return Column(
          children: [
            TabBar(labelColor: Colors.black, unselectedLabelColor: Colors.grey, tabs: [Tab(text: context.loc.socialTab), Tab(text: context.loc.chatTab)]),
            Expanded(
              child: TabBarView(
                physics: const LessSensitivePageScrollPhysics(),
                children: [
                  BlocBuilder<SocialCubit, SocialState>(
                    builder: (context, state) {
                      final socialCubit = context.read<SocialCubit>();
                      final posts = socialCubit.posts;

                      return RefreshIndicator(
                        onRefresh: () => socialCubit.getPosts(selectedCompoundId!),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: false,
                                itemCount: posts.length + 1,
                                itemBuilder: (context, index) {
                                  if (state is SocialLoading && posts.isEmpty) {
                                    const Expanded(child: Center(child: CircularProgressIndicator()));
                                  }
                                  if (index == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.grey.shade200,
                                            backgroundImage:
                                                currentMember?.avatarUrl != null
                                                    ? NetworkImage(currentMember!.avatarUrl.toString())
                                                    : const AssetImage("assets/defaultUser.webp") as ImageProvider,
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: MediaQuery.sizeOf(context).width * 0.75,
                                            child: MaterialButton(
                                              elevation: 0,
                                              color: context.txt.statusButtonColor,
                                              onPressed: () {
                                                newPost(context, postHead, currentMember, selectedCompoundId);
                                              },
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                              child: Text(context.loc.statusButton),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final postIndex = index - 1;
                                  final post = posts[postIndex];
                                  final authorId = post.authorId;
                                  final postUser = memberById[authorId.trim()] ??
                                      ChatMember(
                                        id: authorId,
                                        displayName: 'Unknown',
                                        building: 'null',
                                        apartment: 'null',
                                        userState: UserState.banned,
                                        phoneNumber: '',
                                        ownerType: null,
                                      );
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            width: MediaQuery.sizeOf(context).width * 0.95,
                                            margin: const EdgeInsets.only(top: 20),
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                                              color: context.txt.socialBackgroundColor,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 10, top: 10, bottom: 5),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor: Colors.grey.shade200,
                                                        backgroundImage:
                                                            postUser.avatarUrl != null
                                                                ? NetworkImage(postUser.avatarUrl.toString())
                                                                : const AssetImage("assets/defaultUser.webp") as ImageProvider,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(postUser.displayName, style: context.txt.socialUserName),
                                                          if (post.createdAt != null) Text(formatPostTime(post.createdAt!), style: context.txt.socialPostSince),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Align(
                                                    alignment: AlignmentDirectional.topStart,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                                      child: Text(post.postHead, style: context.txt.socialPostHead),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 15,
                                            top: 28,
                                            child: PopupMenuButton<String>(
                                              tooltip: '',
                                              onSelected: (selectedValue) async {
                                                await supabase.from("Posts").delete().eq('author_id', post.authorId).eq('id', post.id);
                                                if (mounted) {
                                                  context.read<SocialCubit>().getPosts(selectedCompoundId!);
                                                }
                                              },
                                              itemBuilder: (ctx) => moreMenu.map((f) => PopupMenuItem<String>(value: f, child: Text(f))).toList(),
                                              child: const Icon(Icons.more_horiz),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: MediaQuery.sizeOf(context).width * 0.95,
                                        child: PostCarousel(
                                          userName: postUser.displayName,
                                          source: post.sourceUrl,
                                          onPageChanged: (i) => context.read<SocialCubit>().changeCarouselIndex(i),
                                        ),
                                      ),
                                      Container(
                                        width: MediaQuery.sizeOf(context).width * 0.95,
                                        decoration: BoxDecoration(
                                          color: context.txt.socialBackgroundColor,
                                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                                        ),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width * 0.04, vertical: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [Text("${post.comments.length} ${context.loc.comment}", style: context.txt.commentsCount)],
                                              ),
                                            ),
                                            const Divider(indent: 0.04, endIndent: 0.04, height: 1.1, color: Colors.black12),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  MaterialButton(
                                                    onPressed: () {},
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.thumb_up_alt_outlined, color: context.txt.socialIconColor, size: 20),
                                                        const SizedBox(width: 5),
                                                        Text(context.loc.like),
                                                      ],
                                                    ),
                                                  ),
                                                  MaterialButton(
                                                    onPressed: () {
                                                      commentPopUp(context, post, postUser, members, currentMember, selectedCompoundId);
                                                    },
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.chat_outlined, color: context.txt.socialIconColor, size: 20),
                                                        const SizedBox(width: 5),
                                                        Text(context.loc.comment),
                                                      ],
                                                    ),
                                                  ),
                                                  MaterialButton(
                                                    onPressed: () {},
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.share_rounded, color: context.txt.socialIconColor, size: 20),
                                                        const SizedBox(width: 5),
                                                        Text(context.loc.share),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  GeneralChat(compoundId: selectedCompoundId!, channelName: 'COMPOUND_GENERAL'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> newPost(BuildContext rootContext, TextEditingController postHead, ChatMember? currentMember, int? selectedCompoundId) async {
    return showDialog(
      context: rootContext,
      builder: (BuildContext context) {
        return CreatePostDialog(postHead: postHead, currentMember: currentMember, selectedCompoundId: selectedCompoundId);
      },
    );
  }

  Future<void> commentPopUp(BuildContext context, Post post, ChatMember postUser, List<ChatMember> members, ChatMember? currentMember, int? selectedCompoundId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return CommentPopupDialog(post: post, postUser: postUser, members: members, currentMember: currentMember, selectedCompoundId: selectedCompoundId);
      },
    );
  }
}

class LessSensitivePageScrollPhysics extends PageScrollPhysics {
  const LessSensitivePageScrollPhysics({super.parent});

  @override
  LessSensitivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LessSensitivePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics metrics, double velocity) {
    if ((velocity.abs() < tolerance.velocity) || (velocity > 0.0 && metrics.pixels >= metrics.maxScrollExtent) || (velocity < 0.0 && metrics.pixels <= metrics.minScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    final double target = _getTargetPixels(metrics, velocity);
    if (target != metrics.pixels) {
      return ScrollSpringSimulation(spring, metrics.pixels, target, velocity, tolerance: tolerance);
    }
    return null;
  }

  double _getTargetPixels(ScrollMetrics metrics, double velocity) {
    double page = metrics.pixels / metrics.viewportDimension;
    if (velocity < -tolerance.velocity) {
      page -= 0.6;
    } else if (velocity > tolerance.velocity) {
      page += 0.6;
    }
    return page.round() * metrics.viewportDimension;
  }
}

class CreatePostDialog extends StatefulWidget {
  final TextEditingController postHead;
  final ChatMember? currentMember;
  final int? selectedCompoundId;
  const CreatePostDialog({super.key, required this.postHead, this.currentMember, this.selectedCompoundId});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> with WidgetsBindingObserver {
  List<XFile>? file;
  bool getCalls = false;
  bool postingInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      insetPadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: Colors.white,
      content: SizedBox(
        width: screenWidth * 0.98,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Text(context.loc.postCreate)),
              const Divider(thickness: 0.5),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        widget.currentMember?.avatarUrl != null
                            ? NetworkImage(widget.currentMember!.avatarUrl.toString())
                            : const AssetImage("assets/defaultUser.webp") as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Text(widget.currentMember?.displayName ?? "Guest", style: context.txt.socialUserName),
                ],
              ),
              const SizedBox(height: 10),
              PostTextForm(context, controller: widget.postHead, keyboardType: TextInputType.text, hintText: context.loc.statusButton),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8.0, mainAxisSpacing: 8.0),
                      itemCount: file?.length ?? 0,
                      itemBuilder: (context, index) {
                        return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(file![index].path), fit: BoxFit.cover));
                      },
                    ),
                    file != null
                        ? IconButton(
                          onPressed: () {
                            setState(() {
                              file = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                        )
                        : DottedBorder(
                          options: const RoundedRectDottedBorderOptions(radius: Radius.circular(8), strokeWidth: 2, color: Colors.grey, dashPattern: [5]),
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            height: MediaQuery.sizeOf(context).height * 0.2,
                            width: MediaQuery.sizeOf(context).width * 0.8,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(context.loc.emptyPhotos, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                Text(context.loc.uploadPhotosPosts, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400)),
                                MaterialButton(
                                  onPressed: () async {
                                    List<XFile>? result = await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1440);
                                    if (result.isEmpty) return;
                                    setState(() {
                                      file = result;
                                    });
                                  },
                                  color: HexColor("f0f2f5"),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
                                  child: Text(context.loc.upload, style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              if (getCalls == true)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Name"), Text("Position")]),
                    MaterialButton(
                      padding: const EdgeInsets.only(right: 21, left: 15),
                      onPressed: () {},
                      elevation: 0,
                      color: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                      child: const Row(children: [Icon(Icons.phone), SizedBox(width: 5), Text("Call now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.50,
                      child: Text("Add to your post", style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.w400)),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          getCalls = true;
                        });
                      },
                      icon: const Icon(Icons.phone),
                      splashRadius: 10,
                    ),
                  ],
                ),
              ),
              MaterialButton(
                onPressed:
                    postingInProgress
                        ? null
                        : () async {
                          setState(() {
                            postingInProgress = true;
                          });

                          await context.read<SocialCubit>().createPost(
                            postHead: widget.postHead.text,
                            getCalls: getCalls,
                            compoundId: widget.selectedCompoundId!,
                            authorId: widget.currentMember!.id,
                            files: file,
                          );

                          if (mounted) {
                            setState(() {
                              postingInProgress = false;
                            });
                            Navigator.pop(context);
                          }
                        },
                color: Colors.blue,
                disabledColor: Colors.blue.withAlpha(200),
                elevation: 0,
                minWidth: double.infinity,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    if (postingInProgress)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommentPopupDialog extends StatefulWidget {
  final Post post;
  final ChatMember postUser;
  final List<ChatMember> members;
  final ChatMember? currentMember;
  final int? selectedCompoundId;

  const CommentPopupDialog({super.key, required this.post, required this.postUser, required this.members, this.currentMember, this.selectedCompoundId});

  @override
  State<CommentPopupDialog> createState() => _CommentPopupDialogState();
}

class _CommentPopupDialogState extends State<CommentPopupDialog> with WidgetsBindingObserver {
  late TextEditingController newComment;
  final ValueNotifier<bool> isSending = ValueNotifier(false);


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    newComment = TextEditingController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    newComment.dispose();
    isSending.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.fromLTRB(24, 24, 24, 3),
      contentPadding: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      backgroundColor: Colors.white,
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  color: context.txt.socialBackgroundColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10, bottom: 5),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                widget.postUser.avatarUrl != null
                                    ? NetworkImage(widget.postUser.avatarUrl.toString())
                                    : const AssetImage("assets/defaultUser.webp") as ImageProvider,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.postUser.displayName, style: context.txt.socialUserName),
                              if (widget.post.createdAt != null) Text(formatPostTime(widget.post.createdAt!), style: context.txt.socialPostSince),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(widget.post.postHead, style: context.txt.socialPostHead)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.95,
                child: PostCarousel(userName: widget.postUser.displayName, source: widget.post.sourceUrl, onPageChanged: (i) => context.read<SocialCubit>().changeCarouselIndex(i)),
              ),
              Container(
                width: MediaQuery.sizeOf(context).width * 0.95,
                decoration: BoxDecoration(
                  color: context.txt.socialBackgroundColor,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width * 0.04, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [Text("${widget.post.comments.length} ${context.loc.comment}", style: context.txt.commentsCount)],
                      ),
                    ),
                    const Divider(indent: 0.04, endIndent: 0.04, height: 1.1, color: Colors.black12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MaterialButton(
                            onPressed: () {},
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [Icon(Icons.thumb_up_alt_outlined, color: context.txt.socialIconColor, size: 20), const SizedBox(width: 5), Text(context.loc.like)],
                            ),
                          ),
                          MaterialButton(
                            onPressed: () {},
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [Icon(Icons.chat_outlined, color: context.txt.socialIconColor, size: 20), const SizedBox(width: 5), Text(context.loc.comment)],
                            ),
                          ),
                          MaterialButton(
                            onPressed: () {},
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [Icon(Icons.share_rounded, color: context.txt.socialIconColor, size: 20), const SizedBox(width: 5), Text(context.loc.share)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Use context.read<SocialCubit>() for comment logic
              commentsSectionSocial(
                context: context,
                post: widget.post,
                newComment: newComment,
                isSending: isSending,
                members: widget.members,
                currentMember: widget.currentMember,
                selectedCompoundId: widget.selectedCompoundId,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget commentsSectionSocial({
    required BuildContext context,
    required Post post,
    required TextEditingController newComment,
    required ValueNotifier<bool> isSending,
    required List<ChatMember> members,
    required ChatMember? currentMember,
    required int? selectedCompoundId,
  }) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: post.comments.length,
          itemBuilder: (context, index) {
            final comment = post.comments[index];
            final commentAuthorId = comment['author_id']?.toString();
            final commentUser = members.firstWhere(
              (member) => member.id.trim() == commentAuthorId,
              orElse:
                  () => ChatMember(
                    id: commentAuthorId ?? 'unknown',
                    displayName: 'Unknown',
                    building: 'null',
                    apartment: 'null',
                    userState: UserState.banned,
                    phoneNumber: '',
                    ownerType: null,
                  ),
            );
            return ListTile(
              leading: CircleAvatar(
                radius: 12,
                backgroundImage: commentUser.avatarUrl != null ? NetworkImage(commentUser.avatarUrl.toString()) : const AssetImage("assets/defaultUser.webp") as ImageProvider,
              ),
              title: Text(commentUser.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: Text(comment['comment'] ?? '', style: const TextStyle(fontSize: 12)),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: newComment, decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none))),
              ValueListenableBuilder<bool>(
                valueListenable: isSending,
                builder: (context, sending, child) {
                  return IconButton(
                    icon: sending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                    onPressed:
                        sending
                            ? null
                            : () async {
                              if (newComment.text.trim().isEmpty) return;
                              isSending.value = true;
                              await context.read<SocialCubit>().addComment(
                                compoundId: selectedCompoundId!,
                                postId: post.id,
                                commentText: newComment.text,
                                authorId: currentMember!.id,
                                currentComments: post.comments,
                              );
                              newComment.clear();
                              isSending.value = false;
                              if (mounted) {
                                setState(() {});
                              }
                            },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
