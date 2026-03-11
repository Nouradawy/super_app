
import 'dart:io';

import 'package:WhatsUnity/Layout/chatWidget/MessageWidget.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/admob/v1.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:WhatsUnity/Components/Constants.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:WhatsUnity/Layout/chatWidget/GeneralChat/GeneralChat.dart';
import 'package:WhatsUnity/Themes/lightTheme.dart';

import '../../Confg/supabase.dart';
import '../Cubit/cubit.dart';

class BrainStorming extends StatefulWidget {
  const BrainStorming({super.key, required this.onClose , required this.channelId});
  final VoidCallback onClose;
  final int channelId;

  @override
  State<BrainStorming> createState() => _BrainStormingState();


}

class _BrainStormingState extends State<BrainStorming> with WidgetsBindingObserver{
  final CarouselSliderController controller = CarouselSliderController();
  final TextEditingController title = TextEditingController();

  final optionControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  TextEditingController newComment = TextEditingController();

  List<XFile>? file;

  Map<String, Map<String, bool>> _normalizeVotes(dynamic raw) {
    final Map<String, Map<String, bool>> votes = {};
    if (raw is Map) {
      raw.forEach((k, v) {
        final key = k.toString();
        final Map<String, bool> inner = {};
        if (v is Map) {
          v.forEach((vk, vv) => inner[vk.toString()] = vv == true);
        }
        votes[key] = inner;
      });
    }
    return votes;
  }

  bool _hasUserVoted(dynamic rawVotes, String userId) {
    final votes = _normalizeVotes(rawVotes);
    return votes.values.any((m) => m.containsKey(userId));
  }

  String? _userVotedOptionId(dynamic rawVotes, String userId) {
    final votes = _normalizeVotes(rawVotes);
    for (final entry in votes.entries) {
      if (entry.value.containsKey(userId)) return entry.key;
    }
    return null;
  }

  double _keyboardHeight = 0.0;
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


  // Fetch avatars once for all unique voter ids in this poll
  @override
  Widget build(BuildContext context) {
    final cubit = AppCubit.get(context);
    return BlocListener<AppCubit,AppCubitStates>(
      listenWhen: (prev,current){
        return (current is TabBarIndexStates || current is BottomNavIndexChangeStates);
      },
      listener: (context,state){
        if(state is TabBarIndexStates  || state is BottomNavIndexChangeStates){
          widget.onClose();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title:Text("Brain Storming"),
          actions:[IconButton(onPressed:widget.onClose, icon: Icon(Icons.analytics_outlined),)],

        ),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: (){
              newReport(context , widget.channelId);
            },
            label: Text("Create New ",style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w600 , color: HexColor("#121416")),),
          icon: Icon(Icons.add, color: HexColor("#121416")),
          backgroundColor: HexColor("#dce8f3"),
        ),
        body:SingleChildScrollView(
          padding: EdgeInsets.only(bottom:_keyboardHeight),
          physics:NeverScrollableScrollPhysics(),
          child: BlocBuilder<AppCubit,AppCubitStates>(
            builder: (context,states) {
              final isSending = ValueNotifier<bool>(false);
              return Column(
                children: [
                  FutureBuilder<Map<String,dynamic>>(
                      future:fetchAvatarsForUserIds(context),
                      builder: (context,snapshot) {
                        final idToAvatar = snapshot.data ?? const  <String  , dynamic>{};

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CarouselSlider(
                            items: cubit.brainStormData.map<Widget>((item){
                              return KeyedSubtree(
                                key:ValueKey('poll-slide-${item['id']}'),
                                child: Column(
                                  children: [
                                    if(item['Image'].length != 0)
                                      item['Image'].map((image)=>
                                          SizedBox(
                                              width: MediaQuery.sizeOf(context).width,
                                              height: 250,
                                              child: DriveImageMessage(
                                                key: ValueKey('poll-image-${item['id']}-${image['uri']}'),
                                                fileId: extractDriveFileId(image['uri'])!, driveService: driveService ,isRounded: false,)))
                                          .toList().first,

                                    Padding(
                                      padding: const EdgeInsets.only(top:18.0),
                                      child: SizedBox(
                                        width:MediaQuery.sizeOf(context).width*0.80,
                                        child: FlutterPolls(
                                          key: ValueKey('poll-widget-${item['id']}'),
                                          pollId: item['id'],
                                          createdBy: item['author_id'],
                                          allowToggleVote: true,
                                          pollProgressbarHeight: 5,
                                          hasVoted: _hasUserVoted(item['Votes'], Userid),
                                          userVotedOptionId:_userVotedOptionId(item['Votes'], Userid),
                                          userToVote: Userid,
                                          onVoted: (PollOption pollOption, int newTotalVotes) async{
                                            try{
                                              await cubit.handleBrainStormVote(pollOption , pollId: item['id']);
                                              return true;
                                            } catch(error){
                                              return false;
                                            }

                                          },
                                          pollTitle: Text(item['Title'].toString()),
                                          pollOptions: (item['Options'] as List).map<PollOption>((o) {
                                            final m = Map<String, dynamic>.from(o as Map);
                                            final votesRaw = m['votes'];
                                            final votes = votesRaw is String
                                                ? int.tryParse(votesRaw) ?? 0
                                                : (votesRaw as num?)?.toInt() ?? 0;
                                            final votesByOption = _normalizeVotes(item['Votes']);
                                            final voterIds = votesByOption[m['id'].toString()]?.keys.map((e) => e.toString()).toList() ?? const <String>[];
                                            final voterUrls = voterIds
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
                                        ),
                                      ),
                                    ),



                                  ],
                                ),
                              );
                            }).toList(),
                            carouselController: controller,
                            options: CarouselOptions(
                              viewportFraction: 1.0,
                              enableInfiniteScroll: false,
                              height: MediaQuery.sizeOf(context).height*0.5,
                              onPageChanged: (index, reason) {
                                cubit.changeCarouselIndex(index);
                              },
                              enlargeCenterPage: false,
                            ),


                          ),
                          if(context.read<AppCubit>().brainStormData.length >1) ...[
                            // left arrow
                            Positioned(
                              left: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black38,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                                  onPressed: ()=>context.read<AppCubit>().changeCarouselPage(isPrev: true , controller: controller),
                                  padding: EdgeInsets.zero,
                                  splashRadius: 18,
                                ),
                              ),
                            ),

                            // right arrow
                            Positioned(
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black38,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                                  onPressed: ()=>context.read<AppCubit>().changeCarouselPage(isNext: true , controller: controller),
                                  padding: EdgeInsets.zero,
                                  splashRadius: 18,
                                ),
                              ),
                            ),

                            // dots
                            Positioned(
                              bottom: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(context.read<AppCubit>().brainStormData.length, (i) {
                                  final active = i == context.read<AppCubit>().currentCarouselIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: active ? 10 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: active ? Colors.indigo : Colors.indigoAccent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                  ),

                  commentsSectionBrainstorm(
                    context: context,
                    cubit: cubit,
                    newComment: newComment,
                    isSending: isSending,
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}

Future<Map<String, String>> fetchAvatarsForUserIds(context) async {
  final cubit = AppCubit.get(context);
  if (cubit.brainStormData.isEmpty ||
      cubit.currentCarouselIndex >= cubit.brainStormData.length) {
    return {};
  }
  final raw = cubit.brainStormData[cubit.currentCarouselIndex]['Votes'];
  final Map<String, Map<String, bool>> votes = {};
  if (raw is Map) {
    raw.forEach((k, v) {
      final key = k.toString();
      final inner = <String, bool>{};
      if (v is Map) {
        v.forEach((vk, vv) => inner[vk.toString()] = vv == true);
      }
      votes[key] = inner;
    });
  }

  final Set<String> userIds =
  votes.values.expand((m) => m.keys.map((e) => e.toString())).toSet();

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
      } else if (id != null && url == null) {
        map[id] = "null";
      }
    }
    return map;
  } catch (_) {
    return {};
  }
}

Future<void> newReport(
    BuildContext context,
    int channelId
    ) async {
  // We delegate to a StatefulWidget to handle Keyboard listeners properly
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return CreateBrainstormDialog(channelId: channelId);
    },
  );
}

class CreateBrainstormDialog extends StatefulWidget {
  final int channelId;
  const CreateBrainstormDialog({super.key, required this.channelId});

  @override
  State<CreateBrainstormDialog> createState() => _CreateBrainstormDialogState();
}

class _CreateBrainstormDialogState extends State<CreateBrainstormDialog> with WidgetsBindingObserver {

  // Local State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController title = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  List<XFile>? file;
  double _keyboardHeight = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    title.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
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
        // Remove fixed height. Let it flexible but constrained
        width: MediaQuery.sizeOf(context).width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // shrink wrap content
              children: [
                Row(
                  mainAxisAlignment:MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                      onPressed:() => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: 8),
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
                        height: MediaQuery.sizeOf(context).height*0.2,
                        width: double.infinity,
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

                                setState(() {
                                  file = result;
                                });
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
                  // Use constraints instead of fixed height
                  constraints: BoxConstraints(minHeight: 100),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: HexColor("#f0f2f5"),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    keyboardType: TextInputType.multiline,
                    controller: title,
                    validator: (value){
                      if (value == null || value.trim().isEmpty) {
                        return "vote body can't be empty";
                      }
                      return null;
                    },
                    minLines: 5,
                    maxLines: 10,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: "vote body",
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
                      validator: (value){
                        if(optionControllers.length ==2){
                          return "votes options can't be less than 2";
                        }
                        else if ((value == null || value.trim().isEmpty) && i != optionControllers.length-1) {
                          return "option can't be empty";
                        }
                        return null;
                      },
                      onChanged: (v){
                        if(optionControllers.last.text.isNotEmpty && optionControllers.length >=2)
                        {
                          setState(() {
                            optionControllers.add(TextEditingController());
                          });
                        }
                        else if(optionControllers.length>2)
                        {
                          // Check backwards to avoid index issues
                          for(int j = optionControllers.length - 1; j >= 0; j--) {
                            if(optionControllers[j].text.isEmpty && optionControllers.length > 2 && j != optionControllers.length - 1) {
                              setState((){
                                optionControllers.removeAt(j).dispose();
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
                            borderRadius: BorderRadius.circular(7)
                        ),
                        labelText: context.loc.issueTitle,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          color: HexColor("#60768a"),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height:15,),

                MaterialButton(
                  onPressed: () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    final voteTitle = title.text.trim();
                    final optionsList = <Map<String, dynamic>>[];
                    for (final controller in optionControllers) {
                      final title = controller.text.trim();
                      if (title.isEmpty) continue;
                      optionsList.add({
                        'id': optionsList.length,
                        'title': title,
                        'votes': 0,
                      });
                    }
                    await context.read<AppCubit>().createNewBrainStorm(voteTitle, file, optionsList , widget.channelId);
                    if(mounted){
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
      ),
    );
  }
}

