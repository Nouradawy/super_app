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
import 'package:super_app/Layout/chatWidget/GeneralChat/GeneralChat.dart';
import 'package:super_app/Layout/Maintenance.dart';
import 'package:super_app/Layout/chatWidget/AudioWaveformPainter.dart';
import 'package:super_app/Layout/wellcomingPage.dart';
import 'package:super_app/Network/CacheHelper.dart';
import 'package:super_app/Themes/lightTheme.dart';
import 'package:super_app/Services/PresenceManager.dart';

import '../Components/Constants.dart';
import '../Components/Social.dart';
import 'Profile.dart';

class HomePage extends StatelessWidget {
  final TextEditingController Search = TextEditingController();


   HomePage({super.key});

  @override
  Widget build(BuildContext context) {

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
      }
    ];
    return PresenceManager(
      child: BlocBuilder<AppCubit,AppCubitStates>(
        buildWhen: (prev,current){
          return current is BottomNavIndexChangeStates || current is AppInitialState;
        },
        builder: (context,state) {

          return Scaffold(
              backgroundColor:Colors.white,
              appBar: AppBar(
                backgroundColor:Colors.white,
                title:DropdownMenu(
                  initialSelection: selectedCompoundId?.toString(),
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
                      context.read<AppCubit>().selectCompound(atWelcome: false);
                      debugPrint(selectedKey);
                      await CacheHelper.saveData(key: "compoundCurrentIndex", value: selectedCompoundId);
                    }
                    },
                ),
                leading: Image.asset('assets/JannaLogo.png' , width: 90,
              ),
                actions:[IconButton(onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Profile()),
                  );
                }, icon: Icon(Icons.notifications)),
                  IconButton(onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JoinCommunity()),
                    );
                  }, icon: Icon(Icons.join_full))
                ],

              ),

              body: Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: [
                  NestedScrollView(
                    headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled){
                      return [
                        SliverAppBar(
                          backgroundColor: Colors.white,
                          expandedHeight: MediaQuery.of(context).size.width*0.40,
                          flexibleSpace: FlexibleSpaceBar(
                            background:Column(
                              children: [
                                //Searchbar
                                const SizedBox(
                                  height:30,
                                ),

                                //<-----------------ListView for Services---------------->
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
                                        width: MediaQuery.sizeOf(context).width*0.28,
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

                              ],
                            ),
                          ),
                        )];
                    }, body: DefaultTabController( // 1. Provide the controller here
                    length: 2,
                    child: TabChangeHandler( // 2. Use the listener widget we just created
                      child: BlocConsumer<AppCubit, AppCubitStates>(
                        listener: (context,state){
                          if(state is AppInitialState || state is CompoundIdChange || state is NewPostState)
                            {
                              context.read<AppCubit>().getPostsData(selectedCompoundId!);
                            }

                        },
                        buildWhen: (previousState, currentState) {
                          // Only rebuild if the state is AppInitialState and the compound ID has changed.
                          if ((previousState is AppInitialState && currentState is GetPostsDataStates) || currentState is CompoundIdChanged || currentState is GetPostsDataStates || currentState is NewPostState) {
                            return true;
                          }
                          // For any other state changes, don't rebuild this part of the tree.
                          return false;
                        },
                        builder: (context, state) {

                          if (selectedCompoundId == null) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          // 3. Pass the key to Social, which is now a clean StatelessWidget
                          return Social(key: ValueKey(selectedCompoundId));
                        },
                      ),
                    ),
                  ),

                  ),
                  BlocBuilder<AppCubit,AppCubitStates>(
                    buildWhen: (prev , current)=>current is TabBarIndexStates || current  is ShowHideMicStates  || current is BottomNavIndexChangeStates,
                      builder: (context,state){
                        if(AppCubit.get(context).tabBarIndex==1 && AppCubit.get(context).isChatInputEmpty && isBrainStorming ==false) {
                          return Positioned(
                            bottom: 0,
                            right: 0,
                            child: SafeArea(
                              child: SocialMediaRecorder(
                                onButtonPress: () {
                                  AppCubit.get(context).recordedAmplitudes.clear();
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
                                  debugPrint("attempting to save");
                                  final parts = duration.split(':');
                                  final minutes = int.tryParse(parts[0]) ?? 0;
                                  final seconds = int.tryParse(parts[1]) ?? 0;
                                  final parsedDuration = Duration(minutes: minutes, seconds: seconds);

                                  final amplitudesToUpload = AppCubit.get(context).recordedAmplitudes;
                                  AppCubit.get(context).uploadVoiceNote(soundFile, parsedDuration ,amplitudesToUpload ,selectedCompoundId!);

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
                                  AppCubit.get(context).recordedAmplitudes = amplitudes;
                                  return CustomPaint(
                                    painter: AudioWaveformPainter(
                                      amplitudes: amplitudes,
                                      waveColor: Colors.black,

                                    ),
                                  );
                                },

                                // You can add more customizations here
                                // lockButton: const Icon(Icons.lock, color: Colors.white),
                                // slideToCancelText: "Slide to Cancel",
                                // etc.
                              ),
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
      ),
    );
  }
}


class TabChangeHandler extends StatefulWidget {
  final Widget child;
  const TabChangeHandler({super.key, required this.child});

  @override
  State<TabChangeHandler> createState() => _TabChangeHandlerState();
}

class _TabChangeHandlerState extends State<TabChangeHandler> {
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the controller provided by the parent
    _tabController = DefaultTabController.of(context);
    // Remove any previous listener before adding a new one
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    // Clean up the listener when the widget is destroyed
    _tabController?.removeListener(_handleTabSelection);
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController != null) {
      // To prevent duplicate calls, only emit if the index has actually changed
      if (AppCubit.get(context).tabBarIndex != _tabController!.index) {
        AppCubit.get(context).tabBarIndexSwitcher(_tabController!.index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything itself, it just passes through its child.
    return widget.child;
  }
}

