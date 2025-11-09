
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/admob/v1.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_app/Components/Constants.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/chatWidget/GeneralChat/GeneralChat.dart';
import 'package:super_app/Themes/lightTheme.dart';

import '../../Confg/supabase.dart';
import '../Cubit/cubit.dart';

class BrainStorming extends StatelessWidget {
  BrainStorming({super.key, required this.onClose});
  final VoidCallback onClose;
  final TextEditingController title = TextEditingController();
  final optionControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  List<XFile>? file;

  // Fetch avatars once for all unique voter ids in this poll



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:Text("Brain Storming"),
        actions:[IconButton(onPressed:onClose, icon: Icon(Icons.analytics_outlined),)],

      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: (){
            newReport(context,optionControllers , title , file );
          },
          label: Text("Create New ",style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w600 , color: HexColor("#121416")),),
        icon: Icon(Icons.add, color: HexColor("#121416")),
        backgroundColor: HexColor("#dce8f3"),
      ),
      body:BlocBuilder<AppCubit,AppCubitStates>(
        builder: (context,states) {
          return Column(
            children: [
              TextButton(onPressed: ()=>context.read<AppCubit>().getBrainStormData(),child: Text("get BrainStorm Data"),),
              FutureBuilder<Map<String,String>>(
                  future:fetchAvatarsForUserIds(context),
                  builder: (context,snapshot) {
                    final idToAvatar = snapshot.data ?? const  <String  , String>{};

                  return FlutterPolls(
                    pollId: context.read<AppCubit>().brainStormData.first['id'],
                    createdBy: context.read<AppCubit>().brainStormData.first['author_id'],
                    allowToggleVote: true,
                    pollProgressbarHeight: 5,
                    hasVoted: AppCubit.get(context).previousOptionId !=null,
                    userVotedOptionId:AppCubit.get(context).previousOptionId,
                    userToVote: Userid,
                    onVoted: (PollOption pollOption, int newTotalVotes) async{
                      try{
                        await context.read<AppCubit>().handleBrainStormVote(pollOption);
                        return true;
                      } catch(error){
                        return false;
                      }

                    },
                    pollTitle: Text(context.read<AppCubit>().brainStormData.first['Title'].toString()),
                    pollOptions: context.read<AppCubit>().brainStormData.first['Options'].map<PollOption>((o){
                      final m = Map<String, dynamic>.from(o as Map);
                      final votesRaw = m['votes'];
                      final votes = votesRaw is String
                          ? int.tryParse(votesRaw) ?? 0
                          : (votesRaw as num?)?.toInt() ?? 0;

                      final voterUrls = (AppCubit.get(context).optionVoterIds[m['id'].toString()] ?? [])
                          .map((uid) => idToAvatar[uid])
                          .whereType<String>()
                          .toList();
                      return PollOption(
                        id: m['id'].toString(),
                        title: Text(m['title'].toString()),
                        votes: votes,
                        voterAvatars: voterUrls,
                      );
                    }).toList(),
                  );
                }
              ),
            ],
          );
        }
      ),
    );
  }
}

Future<Map<String, String>> fetchAvatarsForUserIds(context) async {
  final Set<String> userIds =
  AppCubit.get(context).optionVoterIds.values.expand((e) => e).toSet();
  print("My id's : ${userIds}");
  if (userIds.isEmpty) return {};
  try {
    final rows = await supabase
        .from('profiles')
        .select('id, avatar_url')
        .inFilter('id', userIds.toList());

    final Map<String, String> map = {};
    for (final r in (rows as List)) {
      final id = r['id']?.toString();
      final url = r['avatar_url']?.toString();
      if (id != null && url != null && url.isNotEmpty) {
        map[id] = url;
      }else if(id !=null && url ==null){
        map[id] = "https://thumbs.dreamstime.com/b/default-profile-picture-avatar-photo-placeholder-vector-illustration-default-profile-picture-avatar-photo-placeholder-vector-189495158.jpg";
      }
    }
    return map;
  } catch (_) {
    return {};
  }
}

Future<void> newReport(
    BuildContext context,
    List<TextEditingController> optionControllers,
    TextEditingController title,
    List<XFile>? file,

    ) async {
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
              child: SingleChildScrollView(
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
                        Text(context.loc.newBrainStorm),


                      ],),
                    SizedBox(height: 20,),
                    Text(context.loc.uploadPhotos,style:GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),textAlign:TextAlign.start,),
                    const SizedBox(height:15,),

                    Stack(
                      alignment: AlignmentDirectional.topEnd,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                            2, // Number of columns in the grid
                            crossAxisSpacing:
                            8.0, // Spacing between columns
                            mainAxisSpacing: 8.0, // Spacing between rows
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
                          onPressed: () {},
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
                                  onPressed: () async{
                                    List<XFile>? result = await ImagePicker()
                                        .pickMultiImage(
                                      imageQuality: 70,
                                      maxWidth: 1440,
                                    );

                                    if (result.isEmpty) return;

                                    file = result;
                                    setStateOfDialog(() {});
                                  },
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
                      ],
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
                        controller: title,
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

                    ...List.generate(optionControllers.length, (i){
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: TextFormField(
                        keyboardType: TextInputType.text,
                        controller: optionControllers[i],

                        onChanged: (v){
                          if(optionControllers.last.text.isNotEmpty && optionControllers.length >=2)
                            {
                              setStateOfDialog(() {
                                optionControllers.add(TextEditingController());
                              });
                            }
                          else if(optionControllers.length>2)
                          {
                            for(int i = optionControllers.length - 1; i >= 0; i--) {
                              if(optionControllers[i].text.isEmpty && optionControllers.length>2 && i != optionControllers.length-1) {
                                setStateOfDialog((){
                                  optionControllers.removeAt(i).dispose();
                                });
                              }
                            }
                          }

                        },
                        decoration: InputDecoration(
                          filled:true,
                          fillColor: HexColor("#f0f2f5"),
                          isDense: false,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(7)// default border color
                          ),
                          labelText: context.loc.issueTitle,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: HexColor("#60768a"),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          // alignLabelWithHint: true,
                        ),
                      ),
                    );
                    }),
                    const SizedBox(height:15,),

                    MaterialButton(
                      onPressed: () async {
                        final voteTitle = title.text.trim();
                        final optionsList = <Map<String, dynamic>>[];
                        for (final controller in optionControllers) {
                          final title = controller.text.trim();
                          if (title.isEmpty) continue;
                          optionsList.add({
                            'id': optionsList.length, // contiguous index among non-empty options
                            'title': title,
                            'votes': 0,
                          });
                        }
                        await context.read<AppCubit>().createNewBrainStorm(voteTitle, file, optionsList);
                        if(context.mounted){
                          Navigator.pop(context);
                        }

                      },
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
            ),
          );
        },
      );
    },
  );
}

