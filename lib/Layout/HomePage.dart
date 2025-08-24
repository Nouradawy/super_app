import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/GeneralChat.dart';
import 'package:super_app/Layout/Maintenance.dart';
import 'package:super_app/Layout/chatWidget/AudioWaveformPainter.dart';

import '../Components/Constants.dart';
import '../Components/Social.dart';
import 'Profile.dart';

class HomePage extends StatelessWidget {
  TextEditingController Search = TextEditingController();
  List<String> compoundSubscription = ["Plumbing","Electricity","Plastering","Gardening"];
  List<Map<String,dynamic>> services= [{
  "icon": "assets/Svg/maintenance.svg",
  "Name": "Maintenance",
    "icon color":Colors.indigo.shade600,
    "icon bg":Colors.indigo.shade100,
    "Background" :Colors.indigo.shade50,
    "text Color":Colors.indigo.shade900
},
    {
      "icon": "assets/Svg/security.svg",
      "Name": "Security",
      "icon color":Colors.purple.shade600,
      "icon bg":Colors.purple.shade100,
      "Background" :Colors.purple.shade50,
      "text Color":Colors.purple.shade900
    },

    {
      "icon": "assets/Svg/cleaning.svg",
      "Name": "Cleaning",
      "icon color":Colors.teal.shade600,
      "icon bg":Colors.teal.shade100,
      "Background" :Colors.teal.shade50,
      "text Color":Colors.teal.shade900
    }
];

   HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor:Colors.white,
        appBar: AppBar(
          backgroundColor:Colors.white,
          title:DropdownMenu<String>(
            width: MediaQuery.sizeOf(context).width * 0.7,
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
                Size(MediaQuery.sizeOf(context).width * 0.65, double.infinity),
              ),
            ),

            dropdownMenuEntries:
            compoundSubscription.map<DropdownMenuEntry<String>>(
                  (String value) {
                return DropdownMenuEntry<String>(
                  value: value,
                  label: value,
                );
              },
            ).toList(),
          ),
          leading: Image.asset('assets/JannaLogo.png' , width: 90,
        ),
          actions:[IconButton(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Profile()),
            );
          }, icon: Icon(Icons.settings))],
        ),
        body: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled){
                return [
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    expandedHeight: MediaQuery.of(context).size.height*0.21,
                    flexibleSpace: FlexibleSpaceBar(
                      background:Column(
                        children: [
                          //Searchbar
                          Container(
                            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width*0.075 , right:MediaQuery.of(context).size.width*0.075 ),
                            child: defaultTextForm(
                                context,
                                controller:Search,
                                keyboardType: TextInputType.text,
                                preIcon: Icons.search_outlined
                            ),
                          ),
                          SizedBox(
                            height:20,
                          ),

                          //<-----------------ListView for Services---------------->
                          Container(
                            margin:EdgeInsets.only(left:MediaQuery.of(context).size.width*0.075),
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount:services.length,
                              itemBuilder: (context,index){
                                final service = services[index];
                                return Container(
                                  width: 120,
                                  margin: EdgeInsets.only(right:10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12), // <-- Rounded corners
                                    color: service["Background"],
                                  ),
                                  child:MaterialButton(
                                    padding: EdgeInsets.zero,
                                    shape:RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12), // <-- Rounded corners
                                    ),
                                    onPressed: (){
                                      if(index == 0)
                                      {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => Maintenance()),
                                        );
                                      }
                                    },
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,

                                        children: [
                                          const SizedBox(height: 15),
                                          Container(
                                            padding: EdgeInsets.all(12),
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

                        ],
                      ),
                    ),
                  )];
              }, body: Social(),

            ),
            BlocBuilder<AppCubit,AppCubitStates>(
                builder: (context,state){
                  if(AppCubit.get(context).tabBarIndex==1 && chatTextController.text.isEmpty) {
                    return Positioned(
                      bottom: 0,
                      right: 0,
                      child: SocialMediaRecorder(
                        onButtonPress: () {
                          AppCubit.get(context).micOnPressed();
                        },
                        onButtonRelease: () {
                          if (AppCubit
                              .get(context)
                              .isRecording) {
                            AppCubit.get(context).micOnPressed();
                          }
                        },
                        // This is called when the user finishes recording
                        sendRequestFunction: (soundFile, duration) async {
                          print("attemptinng to save");
                          final parts = duration.split(':');
                          final minutes = int.tryParse(parts[0]) ?? 0;
                          final seconds = int.tryParse(parts[1]) ?? 0;
                          final parsedDuration = Duration(
                              minutes: minutes, seconds: seconds);
                          final String timestamp = DateTime
                              .now()
                              .millisecondsSinceEpoch
                              .toString();
                          final downloadsDirectory = Directory(
                              '/storage/emulated/0/Download');
                          final localPath = '${downloadsDirectory
                              .path}/test_voice_note$timestamp.m4a';
                          // Save the soundFile to the temporary directory
                          await Future.delayed(
                              const Duration(milliseconds: 1000));
                          await soundFile.copy(localPath);
                          print('Voice note saved locally at: $localPath');
                          // AppCubit.get(context).uploadVoiceNote(soundFile, parsedDuration);

                        },

                        fullRecordPackageHeight: 80,

                        // Customize the appearance to match your app

                        backGroundColor: ChatColors
                            .light()
                            .surfaceContainerHigh
                            .withAlpha(100),
                        initialButtonWidth: 40,
                        initialButtonHight: 40,
                        finalButtonWidth: 60,
                        finalButtonHight: 60,
                        encode: AudioEncoderType.AAC,
                        waveformBuilder: (amplitudes) {
                          return CustomPaint(
                            painter: AudioWaveformPainter(
                              amplitudes: amplitudes,
                              waveColor: Colors.white,

                            ),
                          );
                        },

                        // You can add more customizations here
                        // lockButton: const Icon(Icons.lock, color: Colors.white),
                        // slideToCancelText: "Slide to Cancel",
                        // etc.
                      ),
                    );
                } else {
                    return const SizedBox.shrink();
                  }
                })
          ],
        )
    );
  }
}

