import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Themes/lightTheme.dart';

class Maintenance extends StatelessWidget {
  Maintenance({super.key});

  final TextEditingController issue = TextEditingController();
  final TextEditingController issueTitle = TextEditingController();
  final List<String> maintenanceCategory = ["Plumbing","Electricity","Plastering","Gardening"];
  final List<String> maintenanceIconBackground = ["Plumbing","Electricity","Plastering","Gardening"];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit,AppCubitStates>
      (builder: (context,state){
        return Scaffold(
            appBar: AppBar(
              title:Text(context.loc.maintenance)
            ),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: (){
                  newReport(context,maintenanceCategory,issue);
                },
              label: Text(context.loc.reportProblem,style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w600 , color: HexColor("#121416")),),
              icon: Icon(Icons.add, color: HexColor("#121416")),
              backgroundColor: HexColor("#dce8f3"),


            ),
            body: Column(
              children: [
                Text(context.loc.reportHistory),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount:
                    2,
                    itemBuilder: (context,index)=>ListTile(
                      title:Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Text("Leaky Faucet",style: GoogleFonts.plusJakartaSans(fontSize: 14,fontWeight:FontWeight.w700,letterSpacing: 0.2 , color: HexColor("#121416")),),
                          Chip(
                            label:Text(context.loc.inProcess,style: GoogleFonts.plusJakartaSans(fontSize: 11,fontWeight:FontWeight.w600 ,letterSpacing: 0.2,color: Colors.white)),
                            backgroundColor: HexColor("#76b7f5"),
                            visualDensity: VisualDensity(vertical: -4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.symmetric(horizontal: 0.0,vertical: 0),
                          )
                        ],
                      ),
                      subtitle:Text("${context.loc.report} #MR001 - 7/20/2025",style: GoogleFonts.plusJakartaSans(fontSize: 12,fontWeight:FontWeight.w600 ,letterSpacing: 0.2,color: Colors.grey)),
                      leading:CircleAvatar(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.hourglass_top), // Icon for 'In Progress'
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded , color: Colors.grey, size: 13,),


                    ))
              ],

            ));
    });
  }
}

Future<void> newReport(
  BuildContext context,
  List<String> maintenanceCategory,
  TextEditingController issue,
) async {
  if (maintenanceCategory.isEmpty) {
    throw ArgumentError(context.loc.maintenanceListError);
  }
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStateOfDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.7,
              width: MediaQuery.sizeOf(context).width * 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    mainAxisAlignment:MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      IconButton(
                        onPressed:(){},
                        icon: Icon(Icons.arrow_back),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Text(context.loc.maintenanceReport),


                    ],),
                  SizedBox(height: 20,),
                  DropdownMenu<String>(
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
                    label: Text(context.loc.maintenanceIssueSelect),
                    dropdownMenuEntries:
                        maintenanceCategory.map<DropdownMenuEntry<String>>(
                      (String value) {
                        return DropdownMenuEntry<String>(
                          value: value,
                          label: value,
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
                      controller: issue,
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
                  const SizedBox(height:15,),
                  Text(context.loc.uploadPhotos,style:GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),textAlign:TextAlign.start,),
                  const SizedBox(height:15,),
                  DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                        radius: Radius.circular(8),
                      strokeWidth: 2,
                      color: Colors.grey.shade400,
                      dashPattern: [5],
                    ),
                    child: Container(
                      alignment: AlignmentDirectional.center,
                        height: MediaQuery.sizeOf(context).height*0.2,
                        width: MediaQuery.sizeOf(context).width*0.8,
                        decoration: BoxDecoration(

                          borderRadius: BorderRadius.circular(8),
                        ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(context.loc.emptyPhotos,style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w700),),
                          Text(context.loc.uploadPhotosLabel,style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w400),),
                          MaterialButton(
                            onPressed: (){},
                            color:HexColor("f0f2f5"),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                            child: Text(context.loc.upload  ,style:GoogleFonts.plusJakartaSans(color: Colors.black , fontWeight: FontWeight.w600)),

                          ),


                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  MaterialButton(
                    onPressed: (){},
                    color:Colors.blue,
                    elevation: 0,
                    minWidth: double.infinity,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Text(context.loc.reportSubmission  ,style:context.txt.reportSubmissionButton),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}