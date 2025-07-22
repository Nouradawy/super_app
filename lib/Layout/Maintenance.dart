import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';

class Maintenance extends StatelessWidget {
  Maintenance({super.key});

  TextEditingController issue = TextEditingController();
  TextEditingController issueTitle = TextEditingController();
  List<String> maintenanceCategory = ["Plumbing","Electricity","Plastering","Gardening"];
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit,AppCubitStates>
      (builder: (context,state){
        return Scaffold(
            appBar: AppBar(
              title:Text("Maintenance")
            ),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: (){
                  newReport(context,maintenanceCategory,issue);
                },
              label: Text("Report a Problem",style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w600 , color: HexColor("#121416")),),
              icon: Icon(Icons.add, color: HexColor("#121416")),
              backgroundColor: HexColor("#dce8f3"),


            ),
            body: Column(
              children: [
                Text("Report History"),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount:
                    2,
                    itemBuilder: (context,index)=>ListTile(
                      title:Text("Date:7/20/2025",style: GoogleFonts.plusJakartaSans(fontSize: 12,fontWeight:FontWeight.w700,letterSpacing: 0.2 , color: HexColor("#121416")),),
                      subtitle:Text("issue: leaky faucet",style: GoogleFonts.plusJakartaSans(fontSize: 12,fontWeight:FontWeight.w500 ,letterSpacing: 0.2,color: HexColor("#6a7681"))),
                      leading:Container(
                        width:40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            shape:BoxShape.circle
                          ),
                          child: Icon(Icons.announcement , color: HexColor("#2C2F42"),)),
                      trailing: Text("InProgress"),

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
    throw ArgumentError('Maintenance category list cannot be empty');
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
                      Text("Maintenance Report"),


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
                    label: const Text("Select Issue type"),
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
                        labelText: 'Describe the issue in detail',
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
                  SizedBox(height:15,),
                  Text("Upload Photos",style:GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),textAlign:TextAlign.start,),
                  SizedBox(height:15,),
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
                          Text("No photos uploaded",style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w700),),
                          Text("Tap to upload photos of the issue",style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w400),),
                          MaterialButton(
                            onPressed: (){},
                            child: Text("Upload"  ,style:GoogleFonts.plusJakartaSans(color: Colors.black , fontWeight: FontWeight.w600)),
                            color:HexColor("f0f2f5"),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),

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
                    child: Text("Submit Report"  ,style:GoogleFonts.plusJakartaSans(color: Colors.white , fontWeight: FontWeight.w600)),
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