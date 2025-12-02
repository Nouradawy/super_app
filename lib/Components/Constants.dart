import 'dart:async';
import 'dart:convert';
import 'package:WhatsUnity/Themes/lightTheme.dart';
import 'package:flutter/foundation.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:WhatsUnity/Layout/Cubit/cubit.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Confg/Enums.dart';
import '../Confg/supabase.dart';
import '../Layout/Cubit/states.dart';
import '../Layout/chatWidget/Details/ChatMember.dart';
import '../Layout/chatWidget/MessageWidget.dart';
import '../Network/CacheHelper.dart';
import '../Services/GoogleDriveService.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

final GoogleDriveService driveService = GoogleDriveService();
GoogleSignInAccount? googleUser;
bool isBrainStorming = false;
Map<String,dynamic> MyCompounds = {'0': "Add New Community"};
List<Map<String,dynamic>> prevSignIn = [];
int? selectedCompoundId;

bool _isRequestingPermissions = false;

Future<void> loadCachedData () async{
  compoundsLogos = await AssetHelper.loadCompoundLogos();
  String? compounds = await CacheHelper.getData(key: "MyCompounds", type: "String");
  if (compounds != null) {
    MyCompounds = json.decode(compounds);
  }
  int? compoundIndex = await CacheHelper.getData(key: "compoundCurrentIndex", type: "int");
  if(compoundIndex != null){
    selectedCompoundId = compoundIndex;
  }
}

Future<void> presetBeforeSignin(context) async {
  final cubit = AppCubit.get(context);
  if (categories.isEmpty) {
    await cubit.loadCompounds();
  }
  if(prevSignIn.isNotEmpty)
    {
      final int existingIndex = prevSignIn.indexWhere(
              (m) => m.containsKey(Userid));
      if(existingIndex != -1) {
        final userData = prevSignIn[existingIndex][Userid];
        if (userData["googleUser"]!= null) {
          if (googleUser == null) {
            final user = await driveService.signIn();
            if (user != null) {
              googleUser = user;
            }
          } else {
            await driveService.signOut();
            googleUser = null;
          }
        }
        selectedCompoundId = userData["compoundIndex"] as int?;
        MyCompounds =(userData['MyCompounds'] as Map?)!.cast<String, dynamic>();

      }
    } else {

    if(selectedCompoundId ==null ){

      final compoundId =await supabase.from('user_apartments').select('compound_id').eq('user_id', Userid).single();
      selectedCompoundId =compoundId['compound_id'];
    }

    debugPrint('Compoundid returned : $selectedCompoundId');
    debugPrint('MyCompounds : ${MyCompounds.length}');
    if(MyCompounds.length ==1){
      final compound = categories.expand((cat) => cat.compounds).firstWhere((compound)=>compound.id == selectedCompoundId);
      debugPrint('Compoundid returned : ${compound.name}');
      MyCompounds = {
        '0': "Add New Community",
        selectedCompoundId.toString(): compound.name.toString()
      };
    }

  }
  // 3\) Load members, posts, etc.
  await cubit.loadCompoundMembers(selectedCompoundId!);
  await cubit.getPostsData(selectedCompoundId);

  userRole = Roles.values[UserData?.userMetadata?["role_id"]-1];
}

Future<void> requestPermission() async {
  if (_isRequestingPermissions) {
    debugPrint('Permission request already in progress, skipping.');
    return;
  }

  _isRequestingPermissions = false;

  final statuses = await [
    Permission.camera,
    Permission.photos,      // iOS
    Permission.storage,     // Android legacy
    Permission.microphone,
    Permission.notification,
  ].request();

  // Handle denied/permanently denied if needed
  for (final entry in statuses.entries) {
    if (entry.value.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}


Widget getCompoundPicture(int compoundId , double size){

  final compound = categories.expand((cat) => cat.compounds).firstWhere((comp)=>comp.id ==compoundId);

  final assetPath = compoundsLogos.firstWhere((file) {
    final fileName = file.split('/').last;          // "23.png"
    final nameWithoutExt = fileName.split('.').first; // "23"
    return nameWithoutExt == compound.id.toString();
  },orElse: () =>'null');


  if(compound.pictureUrl != null) {
    return Image.network(
      compound.pictureUrl.toString(),
      width: size,
      fit: BoxFit.cover,
      errorBuilder: (context, exception, stackTrace) {
        return SizedBox.shrink();
      },
    );
  }
  else if(assetPath != 'null') {
     return Image.asset(assetPath, width: size,
      fit: BoxFit.cover,);
  } else {
    return SizedBox.shrink();
  }
}

class DriveImageMessage extends StatefulWidget {
  final String fileId;
  final GoogleDriveService driveService;
  final types.Message? message;
  final String? userName;
  final bool isRounded;
  final bool isPost;
  final bool isMaintenance;

  const DriveImageMessage({
    super.key,
    required this.fileId,
    required this.driveService,
    this.message,
    this.userName,
    this.isRounded = true ,
    this.isPost =false,
    this.isMaintenance = false,

  });

  @override
  State<DriveImageMessage> createState() => _DriveImageMessageState();
}
class _DriveImageMessageState extends State<DriveImageMessage> {
  // This Future will be created only once.
  late final Future<Uint8List?> _downloadFuture;

  @override
  void initState() {
    super.initState();
    // Call the download method here in initState, so it only runs once.
    _downloadFuture = widget.driveService.downloadFile(widget.fileId);
  }

  @override
  void didUpdateWidget(covariant DriveImageMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileId != widget.fileId) {
      // Only refetch if the file actually changed
      _downloadFuture = widget.driveService.downloadFile(widget.fileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _downloadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Icon(Icons.error, color: Colors.red));
        }
        return GestureDetector(
          onTap:(){
            fullScreenImageViewer( imageData:snapshot.data! , context: context , isMaintenance: widget.isMaintenance, message: widget.message , userName : widget.userName , isPost: widget.isPost);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.isRounded? 12 : 0),
            child: Image.memory(
              snapshot.data ?? Uint8List(0),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

Future fullScreenImageViewer ({required dynamic imageData, required BuildContext context , bool isMaintenance =false,bool isVerf = false , bool isPost = false ,types.Message? message , String? userName}) {
  bool showDetails = true;
  return showDialog(
    barrierColor: HexColor("#dae7f7"),
    barrierDismissible: false,

    builder: (BuildContext context)=> StatefulBuilder(
        builder: (context,setState) {
          return Stack(

            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showDetails = !showDetails;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
              if(showDetails ==true)
                Positioned(
                  top: 0,
                  child: Container(
                    height: 50,
                    width: MediaQuery.sizeOf(context).width,
                    color: Colors.black38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 10,
                      children: [
                        IconButton(
                          onPressed: ()=>Navigator.pop(context),
                          icon: Icon(Icons.arrow_back , color: Colors.white70,),
                        ),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(userName!, style: GoogleFonts.plusJakartaSans(color: Colors.white70 , fontWeight: FontWeight.w700 , fontSize: 15),),
                            if(message !=null)
                              Text("${formatMessageDate(message!.createdAt!)} , ${formatTimestampToAmPm(message.createdAt!)}" , style: GoogleFonts.plusJakartaSans(color: Colors.white70 , fontWeight: FontWeight.w600 , fontSize: 10),),
                            if(isVerf)
                              Text(imageData["name"], style: GoogleFonts.plusJakartaSans(color: Colors.white70 , fontWeight: FontWeight.w600 , fontSize: 10),)
                          ],),


                      ],
                    ),
                  ),
                ),

              if(message != null || isMaintenance)
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(imageData),
                  ),
                ),
              if(isVerf)
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(imageData["path"]),
                  ),
                ),
              if(isPost)
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(imageData),
                  ),
                ),

              if(showDetails ==true)
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
                    height: 50,
                    width: MediaQuery.sizeOf(context).width,
                    color: Colors.black38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      spacing: 10,
                      children: [
                        RawMaterialButton(
                          onPressed: () => Navigator.pop(context),
                          elevation: 0,
                          fillColor: Colors.black38, // circle background color
                          shape: const CircleBorder(),
                          constraints: const BoxConstraints.tightFor(width: 33, height: 33),
                          child: const Icon(Icons.add_reaction_outlined, color: Colors.white70, size: 20),
                        ),
                        MaterialButton(
                          onPressed: (){},
                          color: Colors.black38,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0), // circular corner radius
                          ),
                          elevation: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 6,
                            children: [
                              Icon(Symbols.reply , color: Colors.white70 ,size: 21,),
                              Text("Reply" , style: GoogleFonts.plusJakartaSans(color: Colors.white70 , fontWeight: FontWeight.w700 ),)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
    ), context: context,
  );
}
// File: lib/Components/PostCarousel.dart



class PostCarousel extends StatefulWidget {
  final List<dynamic> source;
  final String userName;
  final void Function(int)? onPageChanged;

  const PostCarousel({
    super.key,
    required this.source,
    required this.userName,
    this.onPageChanged,
  });

  @override
  State<PostCarousel> createState() => _PostCarouselState();
}

class _PostCarouselState extends State<PostCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _current = 0;

  void _safeNext() {
    try {
      _controller.nextPage();
    } catch (e) {
      debugPrint('carousel nextPage ignored: $e');
    }
  }

  void _safePrev() {
    try {
      _controller.previousPage();
    } catch (e) {
      debugPrint('carousel previousPage ignored: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.source;
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CarouselSlider(
            items: items.map<Widget>((item) {
              final uri = (item['uri'] ?? '').toString();
              final fileId = extractDriveFileId(uri);
              if (fileId == null) return const SizedBox.shrink();
              return DriveImageMessage(
                key: ValueKey('post_${widget.userName}_${fileId}'),
                fileId: fileId,
                driveService: driveService,
                isRounded: false,
                userName: widget.userName ,
                isPost: true,
              );
            }).toList(),
            carouselController: _controller,
            options: CarouselOptions(
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              height: 280,
              onPageChanged: (index, reason) {
                setState(() => _current = index);
                widget.onPageChanged?.call(index);
              },
              enlargeCenterPage: false,
            ),
          ),

          if(items.length >1) ...[
            // left arrow
            Positioned(
              left: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                  onPressed: _safePrev,
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
                  onPressed: _safeNext,
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
                children: List.generate(items.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white60,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],

        ],
      ),
    );
  }
}




Widget defaultTextForm(
    context,{
      required TextEditingController controller,
      required TextInputType keyboardType,
      String? hintText,
      String? labelText,
      bool IsPassword = false,
      FormFieldValidator<String>?  validation,
      AutovalidateMode? autoValidation,
      IconData? SuffixIcon,
      IconData? preIcon,
      Function(String)? onChanged,


}) {
  final bool isactive = IsPassword;
  isactive ? IsPassword = AppCubit.get(context).isPassword : null;

  return TextFormField(
    onChanged: onChanged,
  controller: controller,
  validator: validation,
  autovalidateMode: autoValidation,
  keyboardType:keyboardType,
  obscureText:IsPassword,
  decoration:InputDecoration(
      enabledBorder:OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300 ,width:1 ),
        borderRadius: BorderRadius.circular(7)// default border color
      ),
    border: OutlineInputBorder(),
    filled:true,
    fillColor: Colors.white,
    isDense: true,
    label: labelText !=null? Text(labelText):null,
    hintText:hintText,
    hintStyle: GoogleFonts.manrope(color: Colors.grey.shade500 ,fontWeight: FontWeight.w500  ,fontSize: 15),
    prefixIcon: preIcon==null?null:Icon(
      preIcon,color: Theme.of(context).primaryColor,
    ),
    suffixIcon:IsPassword?
    isactive ? IconButton(onPressed: () {AppCubit.get(context).Passon();}, icon: Icon(AppCubit.get(context).suffixIcon),) : IconButton(onPressed: () {}, icon: Icon(SuffixIcon),)
        :isactive ? IconButton(onPressed: () {AppCubit.get(context).Passon();}, icon: Icon(AppCubit.get(context).suffixIcon),) : IconButton(onPressed: () {}, icon: Icon(SuffixIcon),),
  ) ,
  );
}

Widget PostTextForm(
    context,{
      required TextEditingController controller,
      required TextInputType keyboardType,
      String? hintText,
      bool IsPassword = false,
      IconData? SuffixIcon,
      IconData? preIcon,


    }) {
  final bool isactive = IsPassword;
  isactive ? IsPassword = AppCubit.get(context).isPassword : null;

  return TextFormField(
    controller: controller,
    keyboardType:keyboardType,
    obscureText:IsPassword,
    maxLines: null,
    textAlignVertical: TextAlignVertical.top,
    decoration:InputDecoration(
      contentPadding:EdgeInsets.symmetric(horizontal: 10),
      border: InputBorder.none,
      filled:false,
      isDense:true,
      hintText:hintText,
      hintStyle: GoogleFonts.manrope(color: Colors.grey.shade500 ,fontWeight: FontWeight.w400  ,fontSize: 13),
      prefixIcon: preIcon==null?null:Icon(
        preIcon,color: Theme.of(context).primaryColor,
      ),

    ) ,
  );
}

class TopLabelCenterInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;

  const TopLabelCenterInput({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final node = focusNode ?? FocusNode();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).requestFocus(node),
      child: Container(
        // Make a comfortable tap area
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.64,
          minHeight: 56, // larger touch target
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center, // center typing vertically
        child: TextFormField(
          controller: controller,
          focusNode: node,
          keyboardType: TextInputType.text,
          // Center the input text vertically via padding
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            // Pin label to the top, always visible
            floatingLabelBehavior: FloatingLabelBehavior.always,
            // Provide top-hugged label
            labelText: '',
            // Remove default paddings and use contentPadding
            contentPadding: EdgeInsets.symmetric(vertical: 6),
          ).copyWith(
            // Set label dynamically and style small, top-hugged
            labelText: label,
            labelStyle: Theme.of(context).textTheme.bodySmall,
          ),
          // Keep text in the middle visually
          textAlignVertical: TextAlignVertical.center,
        ),
      ),
    );
  }
}

Widget commentsSection (
    {required BuildContext context,required AppCubit cubit, int? index,
      required TextEditingController newComment,required ValueNotifier<
        bool> isSending, StateSetter? setStateOfDialog}){
  return Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: currentUser?.avatarUrl != null? NetworkImage(currentUser!.avatarUrl.toString()):const AssetImage("assets/defaultUser.webp"),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(5)
            ),
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width*0.64
                  ),
                  child: TopLabelCenterInput(
                    controller: newComment,
                    label: '${context.loc.commentAs} ${currentUser?.displayName}',
                  ),),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: SizedBox.square(
                    dimension: 44, // bigger hit area
                    child: IconButton(
                      onPressed: isSending.value
                          ? null
                          : () async {
                        isSending.value = true;
                        setStateOfDialog!(() {

                        });
                        await cubit.postNewComment(
                          selectedCompoundId!,
                          cubit.Posts[index!]['id'],
                          index,
                          newComment,
                        );

                        isSending.value = false;
                        setStateOfDialog(() {
                        });
                      },
                      icon: const Icon(Icons.send_rounded),
                      iconSize: 15, // same icon size
                      padding: EdgeInsets.zero, // keep icon visually tight
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44), // bigger tap
                      splashRadius: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(left:17.0),
        child: ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            padding:EdgeInsets.only(left:5),
            shrinkWrap: true,
            itemCount: (cubit.Posts[index!]['Comments'] as List?  ?? []).length,
            itemBuilder: (context , commentIndex){
              final comments = (cubit.Posts[index]['Comments'] as List);
              final authorId = comments[commentIndex]['author_id']?.toString();

              final commentUser = ChatMembers.firstWhere(
                    (member) => member.id.trim() == authorId,
                orElse: () => ChatMember(
                  id: authorId ?? 'unknown',
                  displayName: 'Unknown',
                  building: 'null',
                  apartment: 'null',
                  userState: UserState.banned,
                  phoneNumber: '',
                  ownerType: null,
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: commentUser.avatarUrl != null  ? NetworkImage(commentUser.avatarUrl.toString()):AssetImage("assets/defaultUser.webp"),
                    ),
                    SizedBox(width: 9,),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 2,horizontal: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(commentUser.displayName),
                          Text((AppCubit.get(context).Posts[index]['Comments'] as List)[commentIndex]['comment'].toString()),
                        ],
                      ),
                    ),
                  ],),
              );

            }
        ),
      ),
    ],
  );
}

Widget commentsSectionBrainstorm({
  required BuildContext context,
  required AppCubit cubit,
  required TextEditingController newComment,
  required ValueNotifier<bool> isSending,
  StateSetter? setStateOfDialog,
}) {
  final int pollIndex = cubit.currentCarouselIndex;
  final dynamic poll = (cubit.brainStormData.isNotEmpty && pollIndex < cubit.brainStormData.length)
      ? cubit.brainStormData[pollIndex]
      : null;

  final List<dynamic> comments = (poll?['comments'] as List?) ?? [];

  return Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: currentUser?.avatarUrl != null
                ? NetworkImage(currentUser!.avatarUrl.toString())
                : const AssetImage('assets/defaultUser.webp') as ImageProvider,
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.64,
                  ),
                  child: TopLabelCenterInput(
                    controller: newComment,
                    label: '${context.loc.commentAs} ${currentUser?.displayName}',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: SizedBox.square(
                    dimension: 44,
                    child: IconButton(
                      onPressed: isSending.value
                          ? null
                          : () async {
                        isSending.value = true;
                        setStateOfDialog?.call(() {});
                        // Update poll comments locally first
                        final List<dynamic> newComments = List<dynamic>.from(comments);
                        newComments.add({
                          'author_id': Userid,
                          'comment': newComment.text,
                        });

                        // Persist to Supabase
                        final String pollId = poll?['id']?.toString() ?? '';
                        if (pollId.isNotEmpty) {
                          await Supabase.instance.client
                              .from('BrainStorming')
                              .update({'comments': newComments})
                              .eq('id', pollId);
                          // Reflect in local state
                          poll?['comments'] = newComments;
                          cubit.emit(BrainStormVoteUpdated()); // reuse an existing state
                        }

                        newComment.clear();
                        isSending.value = false;
                        setStateOfDialog?.call(() {});
                      },
                      icon: const Icon(Icons.send_rounded),
                      iconSize: 15,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      splashRadius: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(left: 17.0),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 5),
          shrinkWrap: true,
          itemCount: comments.length,
          itemBuilder: (context, commentIndex) {
            final comment = comments[commentIndex] as Map<String, dynamic>;
            final authorId = comment['author_id']?.toString();

            final commentUser = ChatMembers.firstWhere(
                  (member) => member.id.trim() == authorId,
              orElse: () => ChatMember(
                id: authorId ?? 'unknown',
                displayName: 'Unknown',
                building: 'null',
                apartment: 'null',
                userState: UserState.banned,
                phoneNumber: '',
                ownerType: null,
              ),
            );

            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: commentUser.avatarUrl != null
                        ? NetworkImage(commentUser.avatarUrl.toString())
                        : const AssetImage('assets/defaultUser.webp') as ImageProvider,
                  ),
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(commentUser.displayName),
                        Text(comment['comment']?.toString() ?? ''),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

String formatMessageDate(DateTime date) {
  final dt = date.toLocal();

  final now = DateTime.now();
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final month = monthNames[dt.month - 1];
  final day = dt.day;
  final yearPart = dt.year == now.year ? '' : ', ${dt.year}';

  return '$month $day$yearPart';
}

String formatTimestampToAmPm(DateTime dt) {
  final local = dt.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final ampm = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $ampm';
}

String formatTimeStampToDate(DateTime dt){
  return '${dt.day}/${dt.month}';
}

String formatPostTime(DateTime createdAt) {
  final now = DateTime.now();
  final diff = now.difference(createdAt);

  if (diff.inMinutes < 1) {
    return 'Just now';
  } else if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1 min ago' : '$m mins ago';
  } else if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  } else if (diff.inDays < 7) {
    final d = diff.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  } else if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    return w == 1 ? '1 week ago' : '$w weeks ago';
  }

  // after a week (or you can change to after 30 days) render a normal date
  return formatMessageDate(createdAt); // or your own date formatter
}

class AssetHelper {
  static Future<List<String>> loadCompoundLogos() async {
    // Load the asset manifest
    final manifestContent =
    await rootBundle.loadString('AssetManifest.json');

    // Decode JSON
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    // Filter keys that start with your folder path
    const folder = 'assets/compoundsLogo/';
    final logos = manifestMap.keys
        .where((String key) => key.startsWith(folder))
        .toList();

    return logos; // List\<String\> of full asset paths
  }
}