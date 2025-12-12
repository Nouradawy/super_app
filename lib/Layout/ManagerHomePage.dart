import 'package:WhatsUnity/Layout/Cubit/ManagerCubit/cubit.dart';
import 'package:WhatsUnity/Layout/Cubit/ManagerCubit/states.dart';
import 'package:WhatsUnity/Layout/wellcomingPage.dart';
import 'package:WhatsUnity/Themes/lightTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Components/Constants.dart';
import '../Confg/Enums.dart';
import '../Confg/supabase.dart';
import '../Model/MaintenanceReport.dart';
import '../Network/CacheHelper.dart';
import 'Cubit/AdminDashboard/cubit.dart';
import 'Cubit/cubit.dart';
import 'Maintenance.dart';
import 'Profile.dart';
import 'chatWidget/Details/ChatMember.dart';
import 'chatWidget/MessageWidget.dart';

class ManagerHomepage extends StatelessWidget {
  const ManagerHomepage({super.key});


  @override
  Widget build(BuildContext context) {
    final cubit = ManagerCubit.get(context);
    final List<Map<String,dynamic>> services= [{
      "icon": "assets/Svg/maintenance.svg",
      "Name": context.loc.maintenance,
      "icon color":Colors.indigo.shade600,
      "icon bg":Colors.indigo.shade100,
      "Background" :Colors.indigo.shade50,
      "text Color":Colors.indigo.shade900
    },
      {
        "icon": "assets/Svg/security.svg",
        "Name": context.loc.security,
        "icon color":Colors.purple.shade600,
        "icon bg":Colors.purple.shade100,
        "Background" :Colors.purple.shade50,
        "text Color":Colors.purple.shade900
      },

      {
        "icon": "assets/Svg/cleaning.svg",
        "Name": context.loc.cleaning,
        "icon color":Colors.teal.shade600,
        "icon bg":Colors.teal.shade100,
        "Background" :Colors.teal.shade50,
        "text Color":Colors.teal.shade900
      },
      {
        "icon": "assets/Svg/announcement.svg",
        "Name": context.loc.announcements,
        "icon color":Colors.teal.shade600,
        "icon bg":Colors.teal.shade100,
        "Background" :Colors.teal.shade50,
        "text Color":Colors.teal.shade900
      }
    ];
    TextEditingController notes = TextEditingController();
    return BlocProvider.value(
      value: ManagerCubit.get(context)..resetToInitial(),
      child: BlocConsumer<ManagerCubit,ManagerCubitStates>(
        listener: (context ,state) async {
          if(state is ManagerInitialState){
            final managerCubit = ManagerCubit.get(context);
            managerCubit.currentMaintenanceType = MaintenanceReportType.maintenance;
            await managerCubit.getMaintenanceReports();
            cubit.filterIndex =0;
            managerCubit.filterRequests(type:MaintenanceReportType.maintenance ,statusFilter:ManagerReportsFilter.all);
          }
        },
        builder: (context,state) {
          return Scaffold(
            backgroundColor:Colors.white,
            appBar: AppBar(
              backgroundColor:Colors.white,
              leadingWidth: 120,
              title:enabledMultiCompound?DropdownMenu(
                initialSelection: selectedCompoundId?.toString(),
                width: MediaQuery.sizeOf(context).width * 0.55,
                inputDecorationTheme: InputDecorationTheme(
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
                    Size(MediaQuery.sizeOf(context).width * 0.55, double.infinity),
                  ),
                  elevation: WidgetStateProperty.all(0.5),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5), // adjust radius
                      // optional border
                    ),
                  ),
                ),

                dropdownMenuEntries:
                (MyCompounds.entries.toList().reversed).map(
                      (entry) {
                    String key = entry.key;
                    String value =  entry.value;
                    return DropdownMenuEntry<String>(
                      leadingIcon: key == '0' ?Icon(Icons.add):null,
                      value: key,
                      label: value.toString(),
                    );
                  },
                ).toList(),
                onSelected:(selectedKey) async {
                  if(selectedKey == '0'){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JoinCommunity()),
                    );
                  } else {
                    selectedCompoundId =  int.parse(selectedKey.toString());
                    context.read<AppCubit>().loadCompoundMembers(selectedCompoundId!);
                    context.read<AppCubit>().selectCompound(atWelcome: false );
                    await CacheHelper.saveData(key: "compoundCurrentIndex", value: selectedCompoundId);
                  }
                },
              ):Text(MyCompounds.values.last,style: GoogleFonts.plusJakartaSans(
              color: HexColor("#111518"),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),),
              leading: Container(
                  alignment: AlignmentDirectional.center,
                  padding: EdgeInsets.only(left: 7),
                  child: Text(
                    "WhatsUnity",
                    textScaler: TextScaler.noScaling,
                    style: GoogleFonts.lobster(fontSize: 20 ,fontWeight: FontWeight.w500 , color: Colors.indigo.shade500 ,),
                  )),
              actions:[
              //    IconButton(onPressed: (){
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => Profile()),
              //   );
              // }, icon: Icon(Icons.notifications)),

              ],

            ),
            body: Column(
              children: [
                Container(
                  margin:EdgeInsets.only(left:MediaQuery.of(context).size.width*0.075),
                  height: MediaQuery.sizeOf(context).width*0.28,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount:services.length,
                    itemBuilder: (context,index){
                      final service = services[index];
                      return Container(
                        width: MediaQuery.sizeOf(context).width*0.25,
                        margin: const EdgeInsets.only(right:10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), // <-- Rounded corners
                          color: service["Background"],
                        ),
                        child:MaterialButton(
                          padding: EdgeInsets.zero,
                          shape:RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // <-- Rounded corners
                          ),
                          onPressed: () async {
                            if(index == 3){
                              cubit.loadAnnouncement();
                            }else{
                              cubit.currentMaintenanceType = MaintenanceReportType.values[index];
                              await cubit.getMaintenanceReports();
                              cubit.filterIndex =0;
                              cubit.filterRequests(type: cubit.currentMaintenanceType , statusFilter: ManagerReportsFilter.all);

                            }


                          },
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,

                              children: [
                                const SizedBox(height: 15),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                      shape:BoxShape.circle,
                                      color: service["icon bg"]
                                  ),
                                  child: SvgPicture.asset(

                                      colorFilter:ColorFilter.mode(
                                        service["icon color"],
                                        BlendMode.srcIn,
                                      )
                                      ,
                                      service['icon']),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                    width: 100,
                                    child: Text(service['Name'] ,textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize:13,fontWeight: FontWeight.bold , color: service["text Color"]
                                    ),)),

                              ]
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if(cubit.isAnnouncment ==false)
                Expanded(
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        children: List.generate(ManagerReportsFilter.values.length, (i){
                          return FilterChip(
                              label: Text(ManagerReportsFilter.values[i].name),
                              selected: cubit.filterIndex == i,
                              onSelected: (selected) {
                                cubit.filterIndex = i;
                                cubit.filterRequests(type: cubit.currentMaintenanceType , statusFilter: ManagerReportsFilter.values[i]);

                              });
                        }),
                      ),
                      Expanded(
                        child: ListView.builder(
                            physics: BouncingScrollPhysics(),
                            itemCount: cubit.maintenanceDataFiltered.length,
                            itemBuilder: (context,index) {
                              final attachmentUrl = maintenanceReportsAttachmentsData.firstWhere((attach)=>attach.reportId == cubit.maintenanceDataFiltered[index].id  ,
                                  orElse:() =>
                                      MaintenanceReportsAttachments
                                        (reportId: cubit.maintenanceDataFiltered[index].id,
                                          sourceUrl: null,
                                          createdAt: null
                                      )
                              );
                              final bool isOpen = context.watch<AppCubit>().isExpanded &&
                                  context.watch<AppCubit>().reportIndex == index;
                              final member = ChatMembers.firstWhere((m)=>m.id.trim() == cubit.maintenanceDataFiltered[index].userId.trim());

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AnimatedCrossFade(
                                      crossFadeState: (context.watch<AppCubit>().isExpanded &&
                                          context.watch<AppCubit>().reportIndex == index)
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(milliseconds: 500),
                                      firstCurve: Curves.easeInOut,
                                      secondCurve: Curves.easeInOut,
                                      sizeCurve: Curves.easeInOut,
                                      firstChild: listTileReportHeader(context , index ,isOpen, attachmentUrl),
                                      secondChild: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          listTileReportHeader(context , index ,isOpen, attachmentUrl , isSecond: true , member: member),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [

                                              const SizedBox(height: 8),
                                            ],
                                          ),

                                          Divider(height: 1,color: Colors.grey.shade200,),
                                          const SizedBox(height: 8),

                                          // This row now belongs to the whole tile
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width:MediaQuery.sizeOf(context).width*0.70,
                                                child: defaultTextForm(
                                                  context,
                                                  controller: notes,
                                                  keyboardType: TextInputType.text,
                                                  labelText: "Note",
                                                  hintText: "add a note for this issue",
                                                ),
                                              ),
                                              MaterialButton(
                                                padding: EdgeInsets.zero,
                                                onPressed: () {
                                                  cubit.postReportNote(cubit.maintenanceDataFiltered[index].id!, notes.text);

                                                },
                                                child: const Text("submit"),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxHeight: MediaQuery.sizeOf(context).height*0.3
                                            ),
                                            child: ListView.builder(
                                                physics: BouncingScrollPhysics(),
                                                itemCount: cubit.reportNotes.length,
                                                shrinkWrap:true,
                                                itemBuilder: (context,index){
                                                  // final cubit = ManagerCubit.get(context);
                                                  // cubit.reportNotes[index].action
                                                  return Column(
                                                    children: [
                                                      if(index ==0)SizedBox(
                                                        width:MediaQuery.sizeOf(context).width*0.87,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children:[
                                                            Text("Notes"),
                                                            SizedBox(
                                                              width: MediaQuery.sizeOf(context).width*0.3,
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text("Date"),
                                                                  Text("made by"),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width*0.065),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            SizedBox(
                                                              width:MediaQuery.sizeOf(context).width*0.47,
                                                              child: Text(cubit.reportNotes[index].action ,
                                                                  style: GoogleFonts.plusJakartaSans(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w600,
                                                                    letterSpacing: 0.2,
                                                                    color: Colors.grey,
                                                                  )),
                                                            ),
                                                            SizedBox(
                                                              width: MediaQuery.sizeOf(context).width*0.34,
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Text('${formatTimeStampToDate(cubit.reportNotes[index].createdAt)}-${formatTimestampToAmPm(cubit.reportNotes[index].createdAt)}' ,
                                                                      style: GoogleFonts.plusJakartaSans(
                                                                        fontSize: 12,
                                                                        fontWeight: FontWeight.w600,
                                                                        letterSpacing: 0.2,
                                                                        color: Colors.grey,
                                                                      )),
                                                                  Text("made by" ,
                                                                      style: GoogleFonts.plusJakartaSans(
                                                                        fontSize: 12,
                                                                        fontWeight: FontWeight.w600,
                                                                        letterSpacing: 0.2,
                                                                        color: Colors.grey,
                                                                      )),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                        ],
                                      ),
                                    ),

                              );
                            }),
                      ),
                    ],
                  ),
                ),
                if(cubit.isAnnouncment)
                  Column(
                    children: [
                      const SizedBox(height: 60,),
                      SvgPicture.asset("assets/Svg/announcement.svg",height: 130,),
                      Text("Announcements"),
                      Text("Coming Soon"),
                    ],
                  )
              ],
            ),
          );
        },

      ),
    );
  }
}

Widget listTileReportHeader(BuildContext context , int index , bool isOpen , MaintenanceReportsAttachments? attachmentUrl ,
    {bool isSecond = false , ChatMember? member}){
  final cubit = ManagerCubit.get(context);
  return ListTile(
    onTap: () {
      if(isSecond ==false) cubit.getReportsNotes(cubit.maintenanceDataFiltered[index].id!);
      context.read<AppCubit>().expandReport(index);
    },
    leading: const CircleAvatar(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      child: Icon(Icons.hourglass_top),
    ),
    title: Row(
      children: [
        Expanded(
          child: Text(
            cubit.maintenanceDataFiltered[index].title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: HexColor("#121416"),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: '',
          onSelected: (selectedValue) async {
            final newEnum = managerReportsFilterString(selectedValue);
            final reportId = cubit.maintenanceDataFiltered[index].id;
            if (reportId != null) {
              debugPrint(selectedValue);
              await cubit.updateReportState(reportId, newEnum ,selectedValue.toString());
            }
          },
          itemBuilder: (ctx) => ManagerReportsFilter.values
              .map((f) => PopupMenuItem<String>(
            value: f.value,
            child: Text(f.value),
          ))
              .toList(),
          child: Chip(
            label: Text(
              cubit.maintenanceDataFiltered[index].states,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: Colors.white,
              ),
            ),
            backgroundColor: HexColor("#76b7f5"),
            visualDensity: const VisualDensity(vertical: -4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
          ),
        ),
      ],
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${context.loc.report} #${cubit.maintenanceDataFiltered[index].reportCode} - ${formatTimeStampToDate(cubit.maintenanceDataFiltered[index].createdAt!)}-${formatTimestampToAmPm(cubit.maintenanceDataFiltered[index].createdAt!)}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.grey,
          ),
        ),

        if(isSecond) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: member?.avatarUrl != null ? NetworkImage(member!.avatarUrl!) : null,
                    child: member?.avatarUrl == null ? Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 5),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 5,
                          children: [
                            Text(member!.displayName,style:context.txt.userNameCard),
                          ],
                        ),
                        Text('Building ${member.building} • Apartment ${member.apartment}' ,style: context.txt.userNameCard.copyWith(fontWeight: FontWeight.w300 , fontSize: 11),)
                      ]),
                  const SizedBox(width: 17),

                ],),
              Row(
                spacing: 7,
                  children: [
                    SizedBox(
                      width: 60,
                      child: MaterialButton(
                        onPressed: ()=> launchUrl(Uri.parse("tel:<${member.phoneNumber.toString()}>")),
                        elevation: 0,
                        color:Colors.greenAccent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),

                        ),

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone , size: 17, color: Colors.white,),
                            Text("CALL" , style:GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: Colors.black87,
                            ),)
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                  width: 60,
                  child: MaterialButton(
                    onPressed: ()=>openWhatsApp(member.phoneNumber.toString() , "Hello" ,defaultCountryCode: "20"),
                    elevation: 0,
                    color:Colors.greenAccent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),

                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.whatsapp,size: 17 , color: Colors.white,),
                        Text("WhatsApp" , style:GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Colors.black87,
                        ),)
                      ],
                    ),
                  ),
                ),
              ]),
            ],
          ),
          Text(
            "${context.loc.report} #${cubit.maintenanceDataFiltered[index].reportCode} - ${formatTimeStampToDate(cubit.maintenanceDataFiltered[index].createdAt!)}-${formatTimestampToAmPm(cubit.maintenanceDataFiltered[index].createdAt!)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8,),
          Text(
            cubit.maintenanceDataFiltered[index].description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (attachmentUrl?.sourceUrl != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: attachmentUrl!.sourceUrl!
                  .map((item) => SizedBox(
                width: 80,
                height: 80,
                child: DriveImageMessage(
                  userName:
                  "${context.loc.report} #${cubit.maintenanceDataFiltered[index].reportCode} - ${formatTimeStampToDate(cubit.maintenanceDataFiltered[index].createdAt!)}-${formatTimestampToAmPm(maintenanceReportsData[index].createdAt!)}",
                  isMaintenance: true,
                  fileId: extractDriveFileId(item["uri"])!,
                  driveService: driveService,
                ),
              ))
                  .toList(),
            ),
        ]

      ],
    ),
    trailing: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) =>
          RotationTransition(turns: animation, child: child),
      child: Icon(
        isOpen
            ? Icons.keyboard_arrow_down_outlined
            : Icons.arrow_forward_ios_rounded,
        key: ValueKey<String>('arrow_${isOpen}_$index'),
        color: Colors.grey,
        size: 13,
      ),
    ),
  );
}