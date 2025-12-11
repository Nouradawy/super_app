
import 'dart:io';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:WhatsUnity/Layout/chatWidget/Details/ChatMember.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/androidenterprise/v1.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:WhatsUnity/Layout/Cubit/cubit.dart';
import 'package:WhatsUnity/Layout/chatWidget/GeneralChat/GeneralChat.dart';
import 'package:WhatsUnity/Themes/lightTheme.dart';
import 'package:WhatsUnity/Services/GoogleDriveService.dart';
import '../Confg/Enums.dart';
import '../Confg/supabase.dart';
import '../Layout/chatWidget/MessageWidget.dart';
import '../Services/DriveImageWidget.dart';
import 'Constants.dart';

class Social extends StatelessWidget {

  TextEditingController postHead = TextEditingController();
  List<XFile>? file;

  Social({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = AppCubit.get(context);
    return Column(
      children: [
        TabBar(
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: [Tab(text: context.loc.socialTab), Tab(text: context.loc.chatTab)],
        ),
        Expanded(
          child: TabBarView(
            physics:LessSensitivePageScrollPhysics() ,
            children: [
              RefreshIndicator(
                onRefresh: () => AppCubit.get(context).getPostsData(selectedCompoundId!),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: currentUser?.avatarUrl != null? NetworkImage(currentUser!.avatarUrl.toString()):AssetImage("assets/defaultUser.webp"),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width:
                          MediaQuery.sizeOf(context).width *
                              0.75,
                          child: MaterialButton(
                            elevation: 0,
                            color: context.txt.statusButtonColor,
                            onPressed: () {
                              newPost(context, postHead);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // circular border
                              // optional border line
                            ),
                            child: Text(context.loc.statusButton),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: false,
                        itemCount: cubit.Posts.length,
                        itemBuilder: (context, index) {
                          final authorId = cubit.Posts[index]["author_id"]?.toString();
                          final postUser = ChatMembers.firstWhere(
                                (member)=>member.id.trim() == authorId,
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
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: MediaQuery.sizeOf(context).width * 0.95,
                                    margin: EdgeInsets.only(top: 20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                      color: context.txt.socialBackgroundColor,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 10,
                                        top: 10,
                                        bottom: 5,
                                      ),
                                      child: Column(
                                        children: [
                                          ///TODO:Fetch data from sublease
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Colors.grey.shade200,
                                                backgroundImage: postUser.avatarUrl != null ? NetworkImage(postUser.avatarUrl.toString()):AssetImage("assets/defaultUser.webp"),
                                              ),

                                              SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      postUser.displayName,
                                                      style:context.txt.socialUserName
                                                  ),
                                                  Text(
                                                      formatPostTime(DateTime.tryParse(cubit.Posts[index]['created_at'])!),
                                                      style:context.txt.socialPostSince
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Align(
                                            alignment: AlignmentDirectional.topStart,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                              child: Text(
                                                  cubit.Posts[index]["post_head"],
                                                  style: context.txt.socialPostHead
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                      right:15,
                                      top:28,
                                      child: Icon(Icons.more_horiz)),
                                ],
                              ),
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width*0.95,
                                child: BlocBuilder<AppCubit, AppCubitStates>(
                                  builder: (context, states) {
                                    final source = (cubit.Posts[index]['source_url'] as List<dynamic>?) ?? [];
                                    return PostCarousel(
                                      userName: postUser.displayName,
                                      source: source,
                                      onPageChanged: (i) => cubit.onChangedCarousel(i),
                                    );
                                  },
                                ),
                              ),

                              // DriveImagesGridWidget( driveUrls: AppCubit.get(context).Posts[index]['source_url']
                              //     .map((item) => item['uri'] as String)
                              //     .toList()
                              //     .cast<String>(),
                              //     driveService: GoogleDriveService()),

                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.95,
                                decoration: BoxDecoration(
                                  color: context.txt.socialBackgroundColor,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),

                                child: Column(
                                  children: [
                                    //<---------------------Comments and Likes Indicators -------------------->
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                        MediaQuery.sizeOf(context).width * 0.04,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.end,
                                        children: [
                                          Text(
                                              "${(cubit.Posts[index]['Comments']  as List?  ?? [] ).length} ${context.loc.comment}",
                                              style: context.txt.commentsCount
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(
                                      indent: MediaQuery.sizeOf(context).width * 0.04,
                                      endIndent: MediaQuery.sizeOf(context).width * 0.04,
                                      height: 1.1,
                                      color: Colors.black12,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0,),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          MaterialButton(
                                            onPressed: () {},
                                            child: Row(
                                              spacing: 5,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.thumb_up_alt_outlined,
                                                  color: context.txt.socialIconColor,
                                                  size: 20,
                                                ),
                                                Text(context.loc.like),
                                              ],
                                            ),
                                          ),
                                          MaterialButton(
                                            onPressed: () {
                                              commentPopUp(context ,postHead, index ,postUser);
                                            },
                                            child: Row(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                              spacing: 5,
                                              children: [
                                                Icon(
                                                  Icons.chat_outlined,
                                                  color: context.txt.socialIconColor,
                                                  size: 20,
                                                ),
                                                Text(context.loc.comment),
                                              ],
                                            ),
                                          ),
                                          MaterialButton(
                                            onPressed: () {},
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              spacing: 5,
                                              children: [
                                                Icon(
                                                  Icons.share_rounded,
                                                  color: context.txt.socialIconColor,
                                                  size: 20,
                                                ),
                                                Text(context.loc.share),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              GeneralChat(compoundId: selectedCompoundId!, channelName: 'COMPOUND_GENERAL'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> newPost(
      BuildContext context,
      TextEditingController postHead,
  ) async {
    bool postingInProgress = false;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        bool getCalls = false;
        return StatefulBuilder(
          builder: (context, setStateOfDialog) {
            return AlertDialog(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: Colors.white,
              content: SizedBox(
                width: MediaQuery.sizeOf(context).width*0.98,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Text(context.loc.postCreate)),
                    Divider(thickness: 0.5),
                    Row(
                      children: [

                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: currentUser?.avatarUrl != null? NetworkImage(currentUser!.avatarUrl.toString()):AssetImage("assets/defaultUser.webp"),
                        ),

                        SizedBox(width: 10),
                        Text(
                            currentUser?.displayName ?? "Guest",
                            style: context.txt.socialUserName
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    PostTextForm(
                      context,
                      controller: postHead,
                      keyboardType: TextInputType.text,
                      hintText: context.loc.statusButton,
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top:8.0),
                      child: Stack(
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
                            onPressed: () {
                              file = null;
                              setStateOfDialog(() {});
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
                              width: MediaQuery.sizeOf(context).width*0.8,
                              decoration: BoxDecoration(

                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(context.loc.emptyPhotos,style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w700),),
                                  Text(context.loc.uploadPhotosPosts,style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w400),),
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
                    ),
                    if(getCalls == true)  Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Text("Name"), Text("Position")],
                            ),
                            MaterialButton(
                              padding: EdgeInsets.only(right: 21, left: 15),
                              onPressed: () {},
                              elevation: 0,
                              color: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.phone),
                                  SizedBox(width: 5),
                                  Text(
                                    "Call now",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.50,
                            child: Text(
                              "Add to your post",
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              getCalls = true;
                              setStateOfDialog(() {});
                            },
                            icon: Icon(Icons.phone),
                            splashRadius: 10,
                          ),

                          // Icon(Icons.pin_drop),
                        ],
                      ),
                    ),

                    MaterialButton(
                      onPressed: postingInProgress
                          ? null
                          : () async {
                        postingInProgress = true;
                        setStateOfDialog((){ });

                        await AppCubit.get(context).fetchPostsData(postHead.text, getCalls, null, file, selectedCompoundId!);

                        postingInProgress = false;
                        setStateOfDialog((){ });
                        Navigator.pop(context);

                      },
                      color: Colors.blue,
                      disabledColor: Colors.blue.withAlpha(200),
                      elevation: 0,
                      minWidth: double.infinity,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          Text(
                            "Post",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if(postingInProgress) SizedBox( height: 30 , width: 30,child: CircularProgressIndicator()),
                        ],
                      ),
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


  Future<void> commentPopUp(
      BuildContext context,
      TextEditingController postHead,
      int index,
      ChatMember postUser,

      ) async {

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final cubit = AppCubit.get(context);
        final isSending = ValueNotifier<bool>(false);
        return StatefulBuilder(
          builder: (context, setStateOfDialog) {

            TextEditingController newComment = TextEditingController();
            return AlertDialog(
              contentPadding: EdgeInsets.only( bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9), // Set your desired radius
              ),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: MediaQuery.sizeOf(context).width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          color: context.txt.socialBackgroundColor,
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 10,
                            top: 10,
                            bottom: 5,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: postUser.avatarUrl != null? NetworkImage(postUser.avatarUrl.toString()):AssetImage("assets/defaultUser.webp"),
                                  ),

                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        postUser.displayName,
                                        style: context.txt.socialUserName
                                      ),
                                      Text(
                                          formatPostTime(DateTime.tryParse(cubit.Posts[index]['created_at'])!),
                                        style:
                                        context.txt.socialPostSince
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: AlignmentDirectional.topStart,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    cubit.Posts[index]["post_head"],
                                    style: context.txt.socialPostHead
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width*0.95,
                        child: BlocBuilder<AppCubit, AppCubitStates>(
                          builder: (context, states) {
                            final source = (cubit.Posts[index]['source_url'] as List<dynamic>?) ?? [];
                            return PostCarousel(
                              userName: postUser.displayName,
                              source: source,
                              onPageChanged: (i) => cubit.onChangedCarousel(i),
                            );
                          },
                        ),
                      ),

                      Container(
                        width: MediaQuery.sizeOf(context).width * 0.95,
                        decoration: BoxDecoration(
                          color: context.txt.socialBackgroundColor,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),

                        child: Column(
                          children: [
                            //<---------------------Comments and Likes Indicators -------------------->
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                MediaQuery.sizeOf(context).width * 0.04,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "${(cubit.Posts[index]['Comments'] as List? ?? []).length} ${context.loc.comment}",
                                    style: context.txt.commentsCount
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              indent:
                              MediaQuery.sizeOf(context).width *
                                  0.04,
                              endIndent:
                              MediaQuery.sizeOf(context).width *
                                  0.04,
                              height: 1.1,
                              color: Colors.black12,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  MaterialButton(
                                    onPressed: () {},
                                    child: Row(
                                      spacing: 5,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.thumb_up_alt_outlined,
                                          color: context.txt.socialIconColor,
                                          size: 20,
                                        ),
                                        Text(context.loc.like),
                                      ],
                                    ),
                                  ),
                                  MaterialButton(
                                    onPressed: () {
                                    },
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      spacing: 5,
                                      children: [
                                        Icon(
                                          Icons.chat_outlined,
                                          color: context.txt.socialIconColor,
                                          size: 20,
                                        ),
                                        Text(context.loc.comment),
                                      ],
                                    ),
                                  ),
                                  MaterialButton(
                                    onPressed: () {},
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      spacing: 5,
                                      children: [
                                        Icon(
                                          Icons.share_rounded,
                                          color: context.txt.socialIconColor,
                                          size: 20,
                                        ),
                                        Text(context.loc.share),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),

                      commentsSection (context:context , cubit:cubit , index:index , newComment:newComment ,isSending:isSending , setStateOfDialog:setStateOfDialog),
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
}


/// A custom scroll physics that makes the TabBarView more sensitive to swipes.
class LessSensitivePageScrollPhysics extends PageScrollPhysics {
  const LessSensitivePageScrollPhysics({super.parent});

  @override
  LessSensitivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LessSensitivePageScrollPhysics(parent: buildParent(ancestor));
  }

  // This is the updated override with the correct signature
  @override
  Simulation? createBallisticSimulation(ScrollMetrics metrics, double velocity) {
    // Defer to the parent simulation if the user is not swiping
    // or if they are at the edge of the scroll view.
    if ((velocity.abs() < tolerance.velocity) ||
        (velocity > 0.0 && metrics.pixels >= metrics.maxScrollExtent) ||
        (velocity < 0.0 && metrics.pixels <= metrics.minScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    // Determine the target page
    final double target = _getTargetPixels(metrics, velocity);

    // If the target is different from the current position, create a simulation
    if (target != metrics.pixels) {
      return ScrollSpringSimulation(spring, metrics.pixels, target, velocity,
          tolerance: tolerance);
    }

    // If no simulation is needed, return null
    return null;
  }

  double _getTargetPixels(ScrollMetrics metrics, double velocity) {
    double page = metrics.pixels / metrics.viewportDimension;

    // This is the key logic: we give the swipe a "push"
    // to make it easier to cross the threshold for a page change.
    if (velocity < -tolerance.velocity) {
      page -= 0.6; // Adjust this value to control left swipe sensitivity
    } else if (velocity > tolerance.velocity) {
      page += 0.6; // Adjust this value to control right swipe sensitivity
    }

    // Snap to the nearest whole page
    return page.round() * metrics.viewportDimension;
  }
}