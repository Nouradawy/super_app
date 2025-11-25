import 'package:WhatsUnity/Themes/lightTheme.dart';
import 'package:bloc/bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:WhatsUnity/Layout/Cubit/AdminDashboard/states.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../Components/Constants.dart';
import '../../../Confg/supabase.dart';
import '../../AdminDashboard/MembersManagement.dart';

class AdminCubit extends Cubit<AdminCubitStates>{
  AdminCubit():super(AdminInitialState());
  static  AdminCubit get(context) => BlocProvider.of(context);

  int index = 0;
  bool showVerFiles = true;


  void indexChange(int currentIndex){
    index = currentIndex;
    emit(AdminIndexChangedState());
  }

  void showHideVerFiles(){
    showVerFiles = !showVerFiles;
    emit(VerFilesDropState());
  }

  ListView usersList(){

    return ListView.builder(
      shrinkWrap: true,
      itemCount: MembersData.length,
      itemBuilder: (context,index){
        final member = ChatMembers.firstWhere((m)=>m.id.trim() == MembersData[index].authorId);

        return Card(
          elevation: 0.5,
          margin: EdgeInsets.symmetric(horizontal: 30 , vertical: 7),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0 , horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Reported User Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                            child: member.avatarUrl == null ? Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 15),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 5,
                                  children: [
                                    Text(member.displayName,style:context.txt.userNameCard),
                                    Text('•'),
                                    Text(MembersData[index].ownerShipType)
                                  ],
                                ),
                                Text('Building ${member.building} • Apartment ${member.apartment}' ,style: context.txt.userNameCard.copyWith(fontWeight: FontWeight.w300 , fontSize: 11),)
                              ]),
                        ],),
                      Chip(
                        visualDensity: VisualDensity(vertical: -4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.symmetric(horizontal: 0.0,vertical: 0),
                        label: Text(MembersData[index].userState),
                        labelStyle:TextStyle(color: Colors.redAccent , fontWeight: FontWeight.w900 , ),
                        backgroundColor: Colors.red.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),

                      ),
                    ]),
                const SizedBox(height: 20),
                Text(member.fullName.toString() ,style: context.txt.cardBody, ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Text(MembersData[index].phoneNumber.toString() ,style: context.txt.cardBody),
                    SizedBox(
                      width: 60,
                      height: 20,
                      child: MaterialButton(onPressed: (){},
                        padding: EdgeInsets.only(right: 5),

                        elevation: 0,
                        color: Colors.white70,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: Colors.grey , width: 1)
                        ),
                        child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 5,
                        children: [
                        Icon(Icons.phone,size: 15),
                          Text("call")

                      ],),),
                    ),
                    SizedBox(
                      width: 100,
                      height: 20,
                      child: MaterialButton(onPressed: (){},
                        padding: EdgeInsets.only(right: 5),

                        elevation: 0,
                        color: Colors.white70,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: Colors.grey , width: 1)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 5,
                          children: [
                            FaIcon(FontAwesomeIcons.whatsapp,size: 15),
                            Text("Message")

                          ],),),
                    )
                  ],
                ),
                const SizedBox(height: 20),


                AnimatedCrossFade(
                    firstChild: InkWell(
                      onTap: () {
                        showVerFiles = !showVerFiles;
                        emit(VerFilesDropState());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(10)

                        ),
                        child: Row(
                          children: [
                            Icon(Icons.keyboard_arrow_right_sharp),
                            Text("Submitted Documents")
                          ],),
                      ),
                    ),
                    secondChild: InkWell(
                      onTap: (){
                        showVerFiles = !showVerFiles;
                        emit(VerFilesDropState());
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.keyboard_arrow_down_sharp),
                                Text("Submitted Documents")
                              ],),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: MembersData[index].verFile
                                  .map<Widget>((item) {

                                final url = item['path'] ?? '';
                                if (url.isEmpty) return const SizedBox.shrink();

                                return InkWell(
                                  onTap:()=> fullScreenImageViewer(context:context , imageData:item , userName:member.displayName , isVerf: true),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                                  ),
                                );
                              })
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    crossFadeState: showVerFiles?CrossFadeState.showSecond:CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 500),),

                const SizedBox(height: 12),

                Divider(thickness: 0.7),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 25,
                      child: MaterialButton(onPressed: (){},
                        padding: EdgeInsets.only(right: 5),

                        elevation: 0,
                        color: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            // side: BorderSide(color: Colors.black38 , width: 1)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 5,
                          children: [
                            Icon(Icons.check_circle,size: 15 , color: Colors.white70,),
                            Text("Approve",style: context.txt.cardBody.copyWith(color: Colors.white),)

                          ],),),
                    ),
                    SizedBox(
                      width: 110,
                      height: 25,
                      child: MaterialButton(onPressed: (){},
                        padding: EdgeInsets.only(right: 5),

                        elevation: 0,
                        color: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                          // side: BorderSide(color: Colors.black38 , width: 1)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 5,
                          children: [
                            Icon(Icons.dangerous_sharp,size: 15 , color: Colors.white70,),
                            Text("Decline",style: context.txt.cardBody.copyWith(color: Colors.white),)

                          ],),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
Future<String?> _freshSignedUrl(Map<String, dynamic> file) async {
  try {
    final raw = (file['bucket'] ?? '').toString();
    // If DB stores full signed URL in 'bucket', parse and re-sign
    if (raw.startsWith('http')) {
      final uri = Uri.parse(raw);
      final idx = uri.pathSegments.indexOf('sign');
      if (idx == -1 || idx + 2 >= uri.pathSegments.length) return null;
      final bucket = uri.pathSegments[idx + 1];
      final path = uri.pathSegments.sublist(idx + 2).join('/');
      final signed = await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl(path, 60 * 60); // 1h
      return signed;
    }

    // If DB stores { bucket: 'my_bucket', path: 'users/.../file.jpg' }
    final bucket = raw;
    final path = (file['path'] ?? '').toString();
    if (bucket.isEmpty || path.isEmpty) return null;
    final signed = await Supabase.instance.client.storage
        .from(bucket)
        .createSignedUrl(path, 60 * 60);
    return signed;
  } catch (e) {
    debugPrint('sign error: $e');
    return null;
  }
}