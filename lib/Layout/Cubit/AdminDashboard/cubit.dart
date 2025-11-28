import 'package:WhatsUnity/Confg/Enums.dart';
import 'package:WhatsUnity/Themes/lightTheme.dart';
import 'package:bloc/bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:WhatsUnity/Layout/Cubit/AdminDashboard/states.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Components/Constants.dart';
import '../../../Confg/supabase.dart';
import '../../AdminDashboard/MembersManagement.dart';
import '../cubit.dart';

class AdminCubit extends Cubit<AdminCubitStates>{
  AdminCubit():super(AdminInitialState());
  static  AdminCubit get(context) => BlocProvider.of(context);

  int index = 0;
  int filterIndex = 0;
  bool showVerFiles = true;
  List<Users> membersDataFiltered = [];
  UserState filter = UserState.New;

  void indexChange(int currentIndex){
    index = currentIndex;
    emit(AdminIndexChangedState());
  }

  void showHideVerFiles(){
    showVerFiles = !showVerFiles;
    emit(VerFilesDropState());
  }

  ListView usersList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: membersDataFiltered.length,
      itemBuilder: (context,index){
        final member = ChatMembers.firstWhere((m)=>m.id.trim() == membersDataFiltered[index].authorId);
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
                                    Text(membersDataFiltered[index].ownerShipType)
                                  ],
                                ),
                                Text('Building ${member.building} • Apartment ${member.apartment}' ,style: context.txt.userNameCard.copyWith(fontWeight: FontWeight.w300 , fontSize: 11),)
                              ]),
                        ],),
                      Chip(
                        visualDensity: VisualDensity(vertical: -4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.symmetric(horizontal: 0.0,vertical: 0),
                        label: Text(membersDataFiltered[index].userState),
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
                    Text(membersDataFiltered[index].phoneNumber.toString() ,style: context.txt.cardBody),
                    SizedBox(
                      width: 60,
                      height: 20,
                      child: MaterialButton(onPressed: (){
                        launchUrl(Uri.parse("tel:<${membersDataFiltered[index].phoneNumber.toString()}>"));
                      },
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
                      child: MaterialButton(onPressed: (){
                        openWhatsApp(membersDataFiltered[index].phoneNumber.toString() , "Hello" ,defaultCountryCode: "20");
                      },
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
                      child: MaterialButton(
                        onPressed: () async {
                          try{
                            await supabase.from('profiles').update({"userState":UserState.approved.name}).eq('id',MembersData[index].authorId);
                          } catch (e){
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text('failed to Approve : ${e}'),
                                ),
                              );
                            return;
                          }
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Approved'),
                              ),
                            );
                          await context.read<AppCubit>().loadCompoundMembers(selectedCompoundId!);
                          emit(ChangUserState());


                        },
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
                      child: MaterialButton(onPressed: () async {
                        try{
                           await supabase.from('profiles').update({"userState":UserState.unApproved.name}).eq('id',MembersData[index].authorId);
                        } catch (e){
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('failed to Decline : ${e}'),
                              ),
                            );
                          return;
                        }
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('Declined'),
                            ),
                          );
                        await context.read<AppCubit>().loadCompoundMembers(selectedCompoundId!);
                        emit(ChangUserState());

                      },
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

  void filterRequests (UserState currentFilter) {

    membersDataFiltered =  MembersData.where((member)=>member.userState.toLowerCase() == currentFilter.name.toLowerCase()).toList();
    emit(FilterDataState());
  }
}






Future<void> openWhatsApp(
    String phoneNumber,
    String message, {
      String defaultCountryCode = '20', // Default to Egypt
    }) async {

  // 1. Clean: Remove all non-digit characters (+, -, spaces)
  String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

  // 2. Handle Local Numbers: Remove leading '0' if present
  // Example: "0101234..." becomes "101234..."
  if (cleanNumber.startsWith('0')) {
    cleanNumber = cleanNumber.substring(1);
  }

  // 3. Add Country Code: Prepend if it's not already there
  // Example: "101234..." becomes "20101234..."
  if (!cleanNumber.startsWith(defaultCountryCode)) {
    cleanNumber = "$defaultCountryCode$cleanNumber";
  }

  // 4. Create the URL
  final Uri whatsappUri = Uri.parse(
    "whatsapp://send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}",
  );

  // 5. Launch
  try {
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to web if app is not installed
      final Uri webUri = Uri.parse(
        "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}",
      );
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    }
  } catch (e) {
    print("Error launching WhatsApp: $e");
  }
}