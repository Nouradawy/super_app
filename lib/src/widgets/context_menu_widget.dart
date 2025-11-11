import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/src/controllers/reactions_controller.dart';
import 'package:flutter_chat_reactions/src/models/chat_reactions_config.dart';
import 'package:flutter_chat_reactions/src/models/menu_item.dart';
import 'package:flutter_chat_reactions/src/widgets/message_bubble.dart';
import 'package:flutter_chat_reactions/src/widgets/rections_row.dart';
import 'package:super_app/Layout/Cubit/ReportCubit/cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/Themes/lightTheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';

/// A dialog widget that displays reactions and context menu options for a message.
///
/// This widget creates a modal dialog with three main sections:
/// - A row of reaction emojis that can be tapped
/// - The original message (displayed using a Hero animation)
/// - A context menu with customizable options
class ReactionsDialogWidget extends StatefulWidget {
  /// Unique identifier for the hero animation.
  final String messageId;

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
    required this.messageWidget,
    required this.controller,
    required this.config,
    required this.onReactionTap,
    required this.onMenuItemTap,
    this.alignment = Alignment.centerRight,
  });
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
                id: widget.messageId,
                messageWidget: widget.messageWidget,
                alignment: widget.alignment,
              ),
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
                          DropdownMenu<ReportType>(
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
                            ReportType.values.map<DropdownMenuEntry<ReportType>>(
                                  (ReportType category) {
                                return DropdownMenuEntry<ReportType>(
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
                          )
                        ],
                      ),
                    ),
                  )
                )
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
