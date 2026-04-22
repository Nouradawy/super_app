import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/src/controllers/reactions_controller.dart';
import 'package:flutter_chat_reactions/src/models/chat_reactions_config.dart';
import 'package:flutter_chat_reactions/src/models/menu_item.dart';
import 'package:flutter_chat_reactions/src/widgets/message_bubble.dart';
import 'package:flutter_chat_reactions/src/widgets/rections_row.dart';
import 'package:WhatsUnity/core/config/Enums.dart';
import 'package:WhatsUnity/features/chat/presentation/bloc/message_receipts_cubit.dart';
import 'package:WhatsUnity/features/chat/presentation/bloc/message_receipts_state.dart';
import 'package:WhatsUnity/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:WhatsUnity/features/auth/presentation/bloc/auth_state.dart';
import 'package:WhatsUnity/features/chat/presentation/widgets/chatWidget/Details/ChatMember.dart';
import 'package:WhatsUnity/core/config/supabase.dart';
import 'package:WhatsUnity/core/theme/lightTheme.dart';
import 'package:WhatsUnity/features/admin/presentation/bloc/report_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';


/// A dialog widget that displays reactions and context menu options for a message.
///
/// This widget creates a modal dialog with three main sections:
/// - A row of reaction emojis that can be tapped
/// - The original message (displayed using a Hero animation)
/// - A context menu with customizable options
class ReactionsDialogWidget extends StatefulWidget {
  /// Unique identifier for the message (used for data lookups).
  final String messageId;

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
  /// Render Report dialog component.
  bool _isReport = false;

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
              YourContextMenuWidget(messageId:widget.messageId),
              if (widget.config.showContextMenu) ...[
                const SizedBox(height: 10),
                _isReport == false?
                ContextMenuWidget(
                  menuItems: widget.config.menuItems,
                  alignment: widget.alignment,
                  onMenuItemTap: (item, _) => _handleMenuItemTap(context, item),
                ) : Material(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: BlocProvider.value(
                      value: ReportCubit.get(context),
                      child:Container(
                        padding:EdgeInsets.symmetric(horizontal: 15),
                        width: MediaQuery.sizeOf(context).width*0.85,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15),
                            DropdownMenu<ReportAUserType>(
                              width: MediaQuery.sizeOf(context).width * 0.7,
                              inputDecorationTheme: InputDecorationTheme(
                                fillColor: HexColor("#f0f2f5"),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: HexColor("#111518"),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                constraints: const BoxConstraints(maxHeight: 50),
                              ),
                              menuStyle:  MenuStyle(
                                backgroundColor:WidgetStateProperty.all(Colors.white),
                                fixedSize: WidgetStateProperty.all<Size>(
                                  Size(MediaQuery.sizeOf(context).width * 0.65, double.infinity),
                                ),
                              ),
                              onSelected: (value){
                                setState(() {
                                  ReportCubit.get(context).issueType.text = value?.name ?? 'other';
                                });

                              },
                              label: Text(context.loc.maintenanceIssueSelect),
                              dropdownMenuEntries:
                              ReportAUserType.values.map<DropdownMenuEntry<ReportAUserType>>(
                                    (ReportAUserType category) {
                                  return DropdownMenuEntry<ReportAUserType>(
                                    value: category,
                                    label: category.name.toUpperCase(),
                                  );
                                },
                              ).toList(),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              height: MediaQuery.sizeOf(context).height * 0.15,
                              width: MediaQuery.sizeOf(context).width * 0.8,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: HexColor("#f0f2f5"),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                keyboardType: TextInputType.multiline,
                                controller: ReportCubit.get(context).reportDescription,
                                minLines: 5,
                                maxLines: 10,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  labelText: context.loc.issueDescription,
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    color: HexColor("#60768a"),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: MaterialButton(
                                onPressed: (){
                                  ReportCubit.get(context).fileReportToUser();
                                  Navigator.of(context).pop();
                                },
                                child: Text("File Report"),
                              ),
                            ),

                          ],
                        ),
                      ),
                    )
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
    if (item.label == 'Report') {
      setState(() => _isReport = true);
      widget.onMenuItemTap(item);
      return;
    }
    if (item.label == 'Info') {
      showModalBottomSheet(
        context: context,
        builder: (c) => _showSeenUsersSheet(context, widget.messageId),
      );
      return;
    }
    Navigator.of(context).pop();
    widget.onMenuItemTap(item);
  }


}

Widget _showSeenUsersSheet(BuildContext context, String messageId) {
  final authState = context.read<AuthCubit>().state;
  final chatMembers = (authState is Authenticated) ? authState.chatMembers : <ChatMember>[];

  return BlocProvider(
    create: (_) => MessageReceiptsCubit(supabase, chatMembers: chatMembers)..fetchSeenUsers(messageId),
    child: BlocBuilder<MessageReceiptsCubit, MessageReceiptsState>(
      builder: (context, state) {
        if (state is MessageReceiptsLoading) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is MessageReceiptsError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Error: ${state.message}')),
          );
        }
        if (state is MessageReceiptsLoaded) {
          final seen = state.seenUsers;
          if (seen.isEmpty) {
            return const SizedBox(
              height: 120,
              child: Center(child: Text('No viewers')),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: seen.length,
            itemBuilder: (c, i) {
              final su = seen[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: su.member.avatarUrl != null
                      ? NetworkImage(su.member.avatarUrl!)
                      : null,
                  child: su.member.avatarUrl == null
                      ? Text(su.member.displayName.isNotEmpty ? su.member.displayName[0] : '?')
                      : null,
                ),
                title: Text(su.member.displayName),
                subtitle: Text(
                  su.seenAt.toLocal().toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    ),
  );
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


class YourContextMenuWidget extends StatefulWidget {
  final String messageId;
  const YourContextMenuWidget({super.key, required this.messageId});

  @override
  State<YourContextMenuWidget> createState() => _YourContextMenuWidgetState();
}

class _YourContextMenuWidgetState extends State<YourContextMenuWidget> {
  Future<List<Map<String, dynamic>>>? _seenFuture; // 2) field

  @override
  void initState() {
    super.initState();
    _seenFuture = _loadSeenUsers(widget.messageId); // 2) init
  }

  @override
  void didUpdateWidget(covariant YourContextMenuWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId) {
      setState(() {
        _seenFuture = _loadSeenUsers(widget.messageId);
      });
    }
  }

  // 3) fetch seen users
  Future<List<Map<String, dynamic>>> _loadSeenUsers(String messageId) async {
    try {
      final receipts = await supabase
          .from('message_receipts')
          .select('user_id, seen_at')
          .eq('message_id', messageId)
          .not('seen_at', 'is', null)
          .order('seen_at', ascending: false);

      if (receipts.isEmpty) return [];

      final userIds = receipts.map<String>((r) => r['user_id'] as String).toList();
      final profiles = await supabase
          .from('profiles')
          .select('id, display_name, avatar_url')
          .inFilter('id', userIds);

      final profileById = {for (final p in profiles) p['id'] as String: p};

      return receipts.map<Map<String, dynamic>>((r) {
        final id = r['user_id'] as String;
        final p = profileById[id] ?? {};
        return {
          'id': id,
          'name': (p['display_name'] ?? 'Unknown') as String,
          'avatarUrl': p['avatar_url'] as String?,
          'seenAt': DateTime.tryParse(r['seen_at']?.toString() ?? ''),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // 4) render section
  Widget _buildSeenBySection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _seenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        final data = snapshot.data ?? [];
        if (data.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Text('Seen by', style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final u = data[i];
                  final avatarUrl = u['avatarUrl'] as String?;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                          (u['name'] as String).isNotEmpty ? (u['name'] as String)[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 12),
                        )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(u['name'] as String, overflow: TextOverflow.ellipsis)),
                      if (u['seenAt'] is DateTime)
                        Text(
                          (u['seenAt'] as DateTime).toLocal().toIso8601String().substring(11, 16),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: _buildSeenBySection(),
    );
  }
}

