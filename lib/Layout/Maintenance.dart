import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import '../Confg/Enums.dart';
import '../Model/MaintenanceReport.dart';
import '/Components/Constants.dart';
import '/Layout/Cubit/cubit.dart';
import '/Layout/Cubit/states.dart';
import '/Themes/lightTheme.dart';
import '../Confg/supabase.dart';
import 'chatWidget/MessageWidget.dart';

class Maintenance extends StatelessWidget {


  final TextEditingController issueDescription = TextEditingController();
  final TextEditingController issueTitle = TextEditingController();
  final TextEditingController issueCategory = TextEditingController();
  final MaintenanceReportType maintenanceType;
  Maintenance({super.key,
    required this.maintenanceType ,
});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit,AppCubitStates>
      (builder: (context,state){
        return Scaffold(
            appBar: AppBar(
              title:Text(context.loc.maintenance),
              actions: [
                IconButton(onPressed: ()=>context.read<AppCubit>().getMaintenanceReports(maintenanceType), icon: Icon(Icons.sync))
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: (){
                  newReport(context.loc.maintenanceReport,context,issueDescription , issueTitle , issueCategory ,maintenanceType );
                },
              label: Text(context.loc.reportProblem,style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w600 , color: HexColor("#121416")),),
              icon: Icon(Icons.add, color: HexColor("#121416")),
              backgroundColor: HexColor("#dce8f3"),


            ),
            body: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  Text(context.loc.reportHistory),
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: maintenanceReportsData.length,
                      itemBuilder: (context,index) {
                      final attachmentUrl = maintenanceReportsAttachmentsData.firstWhere((attach)=>attach.reportId ==maintenanceReportsData[index].id  ,
                          orElse:() =>
                              MaintenanceReportsAttachments
                                (reportId: maintenanceReportsData[index].id,
                                  sourceUrl: null,
                                  createdAt: null
                              )
                      );
                  
                        return ListTile(
                        onTap: () {
                  
                          context.read<AppCubit>().expandReport(index);
                        },
                        title:Row(
                  
                          spacing: 10,
                          children: [
                            Text(maintenanceReportsData[index].title,style: GoogleFonts.plusJakartaSans(fontSize: 14,fontWeight:FontWeight.w700,letterSpacing: 0.2 , color: HexColor("#121416")),),
                            Chip(
                              label:Text(maintenanceReportsData[index].states ,style: GoogleFonts.plusJakartaSans(fontSize: 11,fontWeight:FontWeight.w600 ,letterSpacing: 0.2,color: Colors.white)),
                              backgroundColor: HexColor("#76b7f5"),
                              visualDensity: VisualDensity(vertical: -4),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.symmetric(horizontal: 0.0,vertical: 0),
                            )
                          ],
                        ),
                        subtitle:AnimatedCrossFade(
                          firstChild:Text("${context.loc.report} #${maintenanceReportsData[index].reportCode} - ${formatTimeStampToDate(maintenanceReportsData[index].createdAt!)}-${formatTimestampToAmPm(maintenanceReportsData[index].createdAt!)}",style: GoogleFonts.plusJakartaSans(fontSize: 12,fontWeight:FontWeight.w600 ,letterSpacing: 0.2,color: Colors.grey)),
                          crossFadeState: (context.watch<AppCubit>().isExpanded && context.watch<AppCubit>().reportIndex == index) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 500),
                          firstCurve: Curves.easeInOut,
                          secondCurve: Curves.easeInOut,
                          sizeCurve: Curves.easeInOut,
                          secondChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${context.loc.report} #${maintenanceReportsData[index].reportCode} - ${formatTimeStampToDate(maintenanceReportsData[index].createdAt!)}-${formatTimestampToAmPm(maintenanceReportsData[index].createdAt!)}",style: GoogleFonts.plusJakartaSans(fontSize: 12,fontWeight:FontWeight.w600 ,letterSpacing: 0.2,color: Colors.grey)),
                  
                                const SizedBox(height: 8),
                                Text(maintenanceReportsData[index].description,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12,fontWeight:FontWeight.w600 ,letterSpacing: 0.2,color: Colors.grey)),
                                const SizedBox(height: 8),
                                if(attachmentUrl.sourceUrl != null)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: attachmentUrl.sourceUrl!.map((item) => SizedBox(
                                      width:80,
                                      height:80,
                                      child: DriveImageMessage(userName:"${context.loc.report} #${maintenanceReportsData[index].reportCode} - ${formatTimeStampToDate(maintenanceReportsData[index].createdAt!)}-${formatTimestampToAmPm(maintenanceReportsData[index].createdAt!)}" ,
                                          isMaintenance:true,fileId: extractDriveFileId(item["uri"])!, driveService: driveService)),).toList(),
                                )
                  
                  
                  
                            ],
                          ),
                        ),
                        leading:CircleAvatar(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.hourglass_top), // Icon for 'In Progress'
                        ),
                        trailing: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) => RotationTransition(turns: animation, child: child),
                          child: Icon(
                            context.watch<AppCubit>().isExpanded ? Icons.keyboard_arrow_down_outlined : Icons.arrow_forward_ios_rounded,
                            key: ValueKey<bool>(context.watch<AppCubit>().isExpanded),
                            color: Colors.grey,
                            size: 13,
                          ),
                        ),
                  
                  
                      );
                      }),
                ],
              
              ),
            ));
    });
  }
}

// -----------------------------------------------------------------------------
// NEW DIALOG LOGIC
// -----------------------------------------------------------------------------

Future<void> newReport(
    String dialogTitle,
    BuildContext context,
    TextEditingController issue,
    TextEditingController issueTitle,
    TextEditingController issueCategory,
    MaintenanceReportType maintenanceType,
    ) async {
  // We delegate to a StatefulWidget to handle Keyboard listeners properly
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return CreateMaintenanceReportDialog(
        dialogTitle: dialogTitle,
        issue: issue,
        issueTitle: issueTitle,
        issueCategory: issueCategory,
        maintenanceType: maintenanceType,
      );
    },
  );
}

class CreateMaintenanceReportDialog extends StatefulWidget {
  final String dialogTitle;
  final TextEditingController issue;
  final TextEditingController issueTitle;
  final TextEditingController issueCategory;
  final MaintenanceReportType maintenanceType;

  const CreateMaintenanceReportDialog({
    super.key,
    required this.dialogTitle,
    required this.issue,
    required this.issueTitle,
    required this.issueCategory,
    required this.maintenanceType,
  });

  @override
  State<CreateMaintenanceReportDialog> createState() =>
      _CreateMaintenanceReportDialogState();
}

class _CreateMaintenanceReportDialogState
    extends State<CreateMaintenanceReportDialog> with WidgetsBindingObserver {
  // Local State
  final _formKey = GlobalKey<FormState>();
  bool isSending = false;
  List<XFile>? file;
  late final List<DropdownMenuEntry<String>> categoryEntries;
  double _keyboardHeight = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize category entries based on type
    switch (widget.maintenanceType) {
      case MaintenanceReportType.maintenance:
        categoryEntries = MaintenanceCategory.values
            .map((c) => DropdownMenuEntry<String>(
            value: c.name, label: c.name.toUpperCase()))
            .toList();
        break;
      case MaintenanceReportType.security:
        categoryEntries = SecurityCategory.values
            .map((c) => DropdownMenuEntry<String>(
            value: c.name, label: c.name.toUpperCase()))
            .toList();
        break;
      case MaintenanceReportType.careService:
        categoryEntries = CareServiceCategory.values
            .map((c) => DropdownMenuEntry<String>(
            value: c.name, label: c.name.toUpperCase()))
            .toList();
        break;
      default:
        categoryEntries = [
          DropdownMenuEntry<String>(value: 'other', label: 'OTHER'),
        ];
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Note: We do NOT dispose the controllers passed from the parent widget here.
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final view = View.of(context);
    final physicalBottom = view.viewInsets.bottom;
    final pixelRatio = view.devicePixelRatio;
    final logicalBottom = physicalBottom / pixelRatio;

    if (_keyboardHeight != logicalBottom) {
      setState(() {
        _keyboardHeight = logicalBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Use insetPadding based on keyboard height
      insetPadding: EdgeInsets.fromLTRB(24, 24, 24, _keyboardHeight + 24),
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),

      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.9,

        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: 8),
                    Text(widget.dialogTitle),
                  ],
                ),
                SizedBox(height: 20),
                DropdownMenu<String>(
                  width: MediaQuery.sizeOf(context).width * 0.65,
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
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    fixedSize: WidgetStateProperty.all<Size>(
                      Size(MediaQuery.sizeOf(context).width * 0.65,
                          double.infinity),
                    ),
                  ),
                  onSelected: (value) {
                    setState(() {
                      widget.issueCategory.text = value ?? 'other';
                    });
                    debugPrint(widget.issueCategory.text);
                  },
                  label: Text(context.loc.maintenanceIssueSelect),
                  dropdownMenuEntries: categoryEntries,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  keyboardType: TextInputType.text,
                  controller: widget.issueTitle,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: HexColor("#f0f2f5"),
                    isDense: false,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(7)),
                    labelText: context.loc.issueTitle,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: HexColor("#60768a"),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  constraints: BoxConstraints(minHeight: 120),
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: HexColor("#f0f2f5"),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    keyboardType: TextInputType.multiline,
                    controller: widget.issue,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
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
                Text(
                  context.loc.uploadPhotos,
                  style:
                  GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 15),
                Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: file?.length ?? 0,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(file![index].path),
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                    file != null
                        ? IconButton(
                      onPressed: () {
                        setState(() {
                          file = null;
                        });
                      },
                      icon: Icon(Icons.close),
                    )
                        : DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        radius: Radius.circular(8),
                        strokeWidth: 2,
                        color: Colors.grey.shade400,
                        dashPattern: [5],
                      ),
                      child: Container(
                        alignment: AlignmentDirectional.center,
                        height: MediaQuery.sizeOf(context).height * 0.2,
                        width: MediaQuery.sizeOf(context).width * 0.8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              context.loc.emptyPhotos,
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              context.loc.uploadPhotosLabel,
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w400),
                            ),
                            MaterialButton(
                              onPressed: () async {
                                List<XFile>? result = await ImagePicker()
                                    .pickMultiImage(
                                  imageQuality: 70,
                                  maxWidth: 1440,
                                );

                                if (result.isEmpty) return;

                                setState(() {
                                  file = result;
                                });
                              },
                              color: HexColor("f0f2f5"),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              child: Text(context.loc.upload,
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                MaterialButton(
                  onPressed: isSending
                      ? null
                      : () async {
                    if (!(_formKey.currentState?.validate() ?? false))
                      return;
                    if (widget.issueCategory.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a category')),
                      );
                      return;
                    }

                    setState(() {
                      isSending = true;
                    });

                    await AppCubit.get(context).reportSubmit(
                        widget.issueTitle.text,
                        widget.issue.text,
                        widget.issueCategory.text,
                        file,
                        widget.maintenanceType);

                    if (mounted) {
                      setState(() {
                        isSending = false;
                      });
                      context
                          .read<AppCubit>()
                          .getMaintenanceReports(widget.maintenanceType);
                      Navigator.pop(context);
                    }
                  },
                  color: Colors.blue,
                  disabledColor: Colors.blue.withAlpha(500),
                  elevation: 0,
                  minWidth: double.infinity,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Text(context.loc.reportSubmission,
                          style: context.txt.reportSubmissionButton),
                      if (isSending)
                        SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}