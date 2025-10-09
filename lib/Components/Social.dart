import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/GeneralChat.dart';
import 'package:super_app/sevices/GoogleDriveService.dart';
import '../Confg/supabase.dart';
import '../sevices/DriveImageWidget.dart';
import 'Constants.dart';

bool Mounted =false;
class Social extends StatelessWidget {
  TextEditingController postHead = TextEditingController();
  List<XFile>? file;

  Social({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: [Tab(text: "Social"), Tab(text: "Chat")],
        ),
        Expanded(
          child: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: () => AppCubit.get(context).getPostsData(selectedCompoundId!),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            "assets/person.svg",
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width:
                          MediaQuery.sizeOf(context).width *
                              0.75,
                          child: MaterialButton(
                            elevation: 0,
                            color: HexColor("#F0F2F5"),
                            onPressed: () {
                              newPost(context, postHead);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // circular border
                              // optional border line
                            ),
                            child: Text("What's on your mind?"),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: false,
                        itemCount: AppCubit.get(context).Posts.length,
                        itemBuilder: (context, index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.95,
                                margin: EdgeInsets.only(top: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                  color: HexColor("#F0EFF4"),
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
                                          Container(
                                            height: 35,
                                            width: 35,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: SvgPicture.asset(
                                              "assets/person.svg",
                                            ),
                                          ),

                                          SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppCubit.get(context).Posts[index]["user_name"],
                                                style:
                                                GoogleFonts.plusJakartaSans(
                                                  fontWeight:
                                                  FontWeight.w900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                "1d",
                                                style:
                                                GoogleFonts.plusJakartaSans(
                                                  height: 0.8,
                                                  fontWeight:
                                                  FontWeight.w300,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 3),
                                      Align(
                                        alignment: AlignmentDirectional.topStart,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            AppCubit.get(context).Posts[index]["post_head"],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DriveImagesGridWidget( driveUrls: AppCubit.get(context).Posts[index]['source_url']
                                  .map((item) => item['uri'] as String)
                                  .toList()
                                  .cast<String>(),
                                  driveService: GoogleDriveService()),

                              Container(
                                width: MediaQuery.sizeOf(context).width * 0.95,
                                decoration: BoxDecoration(
                                  color: HexColor("#F0EFF4"),
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
                                        MediaQuery.sizeOf(context).width *
                                            0.04,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${(AppCubit.get(context).Posts[index]['Comments']  as List?  ?? [] ).length} comment",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: HexColor(
                                                "#1c1e21",
                                              ).withAlpha(170),
                                            ),
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
                                        horizontal: 12.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                                  color: HexColor(
                                                    "#1c1e21",
                                                  ).withAlpha(170),
                                                  size: 20,
                                                ),
                                                Text("Like"),
                                              ],
                                            ),
                                          ),
                                          MaterialButton(
                                            onPressed: () {
                                              commentPopUp(context , postHead,index);
                                            },
                                            child: Row(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                              spacing: 5,
                                              children: [
                                                Icon(
                                                  Icons.chat_outlined,
                                                  color: HexColor(
                                                    "#1c1e21",
                                                  ).withAlpha(170),
                                                  size: 20,
                                                ),
                                                Text("comment"),
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
                                                  color: HexColor("#1c1e21").withAlpha(170),
                                                  size: 20,
                                                ),
                                                Text("share"),
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
              Generalchat(compoundId: selectedCompoundId!,),
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
    bool postProgressBar = false;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        bool getCalls = false;
        return StatefulBuilder(
          builder: (context, setStateOfDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              content: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Text("Create post")),
                    Divider(thickness: 0.5),
                    Row(
                      children: [
                        Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset("assets/person.svg"),
                        ),

                        SizedBox(width: 10),
                        Text(
                          "Omar Yasser",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    PostTextForm(
                      context,
                      controller: postHead,
                      keyboardType: TextInputType.text,
                      hintText: "What's on your mind ?",
                    ),

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
                            : SizedBox.shrink(),
                      ],
                    ),
                    getCalls == true
                        ? Row(
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
                        )
                        : SizedBox.shrink(),
                    Row(
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
                          onPressed: () async {
                            List<XFile>? result = await ImagePicker()
                                .pickMultiImage(
                                  imageQuality: 70,
                                  maxWidth: 1440,
                                );

                            if (result.isEmpty) return;

                            file = result;
                            setStateOfDialog(() {});
                          },
                          icon: Icon(Icons.photo_album),
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
                    MaterialButton(
                      onPressed: () async {
                        postProgressBar = true;
                        setStateOfDialog((){ });

                        await AppCubit.get(context).fetchPostsData(postHead.text, getCalls, null, file, selectedCompoundId!);

                        postProgressBar = false;
                        setStateOfDialog((){ });
                        Navigator.pop(context);

                      },
                      color: Colors.blue,
                      elevation: 0,
                      minWidth: double.infinity,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      child: Text(
                        "Post",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    postProgressBar == true
                        ? LinearProgressIndicator()
                        : SizedBox.shrink(),
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
      ) async {

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateOfDialog) {
            List Comments= [];
            TextEditingController Comment = TextEditingController();
            return AlertDialog(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Set your desired radius
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
                          color: HexColor("#F0EFF4"),
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
                                  Container(
                                    height: 35,
                                    width: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset(
                                      "assets/person.svg",
                                    ),
                                  ),

                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppCubit.get(context).Posts[index]["user_name"],
                                        style:
                                        GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                          FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "1d",
                                        style:
                                        GoogleFonts.plusJakartaSans(
                                          height: 0.8,
                                          fontWeight:
                                          FontWeight.w300,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),
                              Align(
                                alignment: AlignmentDirectional.topStart,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    AppCubit.get(context).Posts[index]["post_head"],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DriveImagesGridWidget( driveUrls: AppCubit.get(context).Posts[index]['source_url']
                          .map((item) => item['uri'] as String)
                          .toList()
                          .cast<String>(),
                          driveService: GoogleDriveService()),
                      Container(
                        width: MediaQuery.sizeOf(context).width * 0.95,
                        decoration: BoxDecoration(
                          color: HexColor("#F0EFF4"),
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
                                MediaQuery.sizeOf(context).width *
                                    0.04,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "${(AppCubit.get(context).Posts[index]['Comments'] as List? ?? []).length} comments",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: HexColor(
                                        "#1c1e21",
                                      ).withAlpha(170),
                                    ),
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
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
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
                                          color: HexColor(
                                            "#1c1e21",
                                          ).withAlpha(170),
                                          size: 20,
                                        ),
                                        Text("Like"),
                                      ],
                                    ),
                                  ),
                                  MaterialButton(
                                    onPressed: () {
                                      commentPopUp(context , postHead,index);
                                    },
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      spacing: 5,
                                      children: [
                                        Icon(
                                          Icons.chat_outlined,
                                          color: HexColor(
                                            "#1c1e21",
                                          ).withAlpha(170),
                                          size: 20,
                                        ),
                                        Text("comment"),
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
                                          color: HexColor("#1c1e21").withAlpha(170),
                                          size: 20,
                                        ),
                                        Text("share"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          SvgPicture.asset("assets/person.svg"),
                          SizedBox(width: 8,),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(5)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: MediaQuery.sizeOf(context).width*0.64
                                  ),
                                  child: PostTextForm(
                                    context,
                                    controller: Comment,
                                    keyboardType: TextInputType.text,
                                    hintText: 'Comment as ${UserData!.userMetadata!["display_name"]}',
                                  ),),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 28,
                                  ),
                                  child: IconButton(
                                      onPressed: () async {
                                        Comments = AppCubit.get(context).Posts[index]['Comments']?? [];
                                        Comments.add({'authorid':Userid,
                                            'comment':Comment.text,});
                                        print(Comments);
                                        await supabase.from('Posts').update({
                                          'Comments':Comments
                                        }).eq('id',AppCubit.get(context).Posts[index]['id']).select();
                                        Comments.clear();
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(Icons.send_rounded),
                                      iconSize:15,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    splashRadius: 15,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      ListView.builder(
                          padding:EdgeInsets.only(left:5),
                        shrinkWrap: true,
                          itemCount: (AppCubit.get(context).Posts[index]['Comments'] as List?  ?? []).length,
                          itemBuilder: (context , commentIndex){

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                SvgPicture.asset(
                                  "assets/person.svg",
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
                                      Text('Name'),
                                      Text((AppCubit.get(context).Posts[index]['Comments'] as List)[commentIndex]['comment'].toString()),
                                    ],
                                  ),
                                ),
                              ],),
                          );

                          }
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
}
