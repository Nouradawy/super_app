import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:WhatsUnity/Layout/Cubit/cubit.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Confg/supabase.dart';
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


Future<void> loadCachedData () async{

  String? compounds = await CacheHelper.getData(key: "MyCompounds", type: "String");
  if (compounds != null) {
    MyCompounds = json.decode(compounds);
  }
  int? compoundIndex = await CacheHelper.getData(key: "compoundCurrentIndex", type: "int");
  if(compoundIndex != null){
    selectedCompoundId = compoundIndex;
    debugPrint(selectedCompoundId.toString());
  }
  // if(prevSignIn.isEmpty){
  //   String? prevSign = await CacheHelper.getData(key:"prevSignIn", type: "String");
  //   if(prevSign !=null) {
  //     final decoded = json.decode(prevSign) as List<dynamic>;
  //     prevSignIn = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  //   }
  //   debugPrint(prevSignIn.toString());
  //
  // }
}

void presetBeforeSignin (context){
  if(prevSignIn.isNotEmpty)
    {
      final int existingIndex = prevSignIn.indexWhere(
              (m) => m.containsKey(Userid));
      if(existingIndex != -1) {
        prevSignIn[existingIndex][Userid].map((current) {
          googleUser = current["googleUser"];
         selectedCompoundId = current["compoundIndex"] as int?;
      });
      }
    }
}
Future<void> requestPermission() async {
  if(await Permission.microphone.status.isDenied || await Permission.storage.status.isDenied)
  {
    await [
      Permission.microphone,
      Permission.storage
    ].request();
  }
}



class DriveImageMessage extends StatefulWidget {
  final String fileId;
  final GoogleDriveService driveService;
  final types.Message? message;
  final String? userName;
  final bool isRounded;
  final bool isPost;

  const DriveImageMessage({
    super.key,
    required this.fileId,
    required this.driveService,
    this.message,
    this.userName,
    this.isRounded = true ,
    this.isPost =false,

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
            fullScreenImageViewer( imageData:snapshot.data! , context: context , message: widget.message , userName : widget.userName , isPost: widget.isPost);
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
Future fullScreenImageViewer ({required dynamic imageData, required BuildContext context , bool isVerf = false , bool isPost = false ,types.Message? message , String? userName}) {
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

              if(message != null)
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
      IconData? SuffixIcon,
      IconData? preIcon,
      Function(String)? onChanged,


}) {
  final bool isactive = IsPassword;
  isactive ? IsPassword = AppCubit.get(context).isPassword : null;

  return TextFormField(
    onChanged: onChanged,
  controller: controller,
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