import 'package:WhatsUnity/Themes/lightTheme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Confg/supabase.dart';
import '../Services/PolicyDialog.dart';

import 'Cubit/cubit.dart';
import 'Cubit/states.dart';
import 'SignUp.dart';

class Profile extends StatelessWidget {

  Profile({super.key});
  final List profile = ["Edit Profile","Notifications","Privacy","Security" , "SignOut"];
  final List account = ["Edit Profile","Change Password"];
  final List preferences = ["Notifications","Appearance"];
  final List support = ["Help Center","Privacy Policy","Terms of Use"];

  TextEditingController UserName = TextEditingController();



  @override
  Widget build(BuildContext context) {
    final cubit  = AppCubit.get(context);
    return BlocConsumer<AppCubit,AppCubitStates>(
      listener: (context , state){
        if (state is AppSignOutSuccessState) {
          // This navigation is now guaranteed to run when sign-out is successful.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SignUp()),
                (Route<dynamic> route) => false,
          );
        }
      },
      builder: (context,state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text("Profile",style: GoogleFonts.plusJakartaSans(),),
            actions:[Icon(Icons.settings)],
          ),
          body:SingleChildScrollView(
            child: Container(
              color: HexColor("#f9f9f9"),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  alignment: AlignmentDirectional.center,
                  child: Stack(
                    alignment: AlignmentDirectional.bottomEnd,
                    children: [
                      Icon(Icons.edit),
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: currentUser?.avatarUrl != null?NetworkImage(currentUser!.avatarUrl.toString()):AssetImage("assets/defaultUser.webp"),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white , width: 4),
                            shape:BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            
                Text(currentUser?.displayName.toString() ?? "Guest",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 20),),
                if(UserData !=null) ...[
                  Text("Resident",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500 ,fontSize: 13, color: HexColor("#637488")),),
                  Text("Joined 2022",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500 ,fontSize: 11, color: HexColor("#637488")),),
                ],


                  // MaterialButton(onPressed: () async {
                  //   AppCubit.get(context).googleSignin(
                  //
                  //   );
                  //
                  // },
                  //   child: Text(googleUser ==  null?"Link Drive":"Unlink"),),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left:10.0 , bottom: 8),
                            child: Text("ACCOUNT",style: context.txt.profileListHead),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width*0.8,
                            decoration: BoxDecoration(
                              color:Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if(cubit.ActivateDropdown)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                                  child: Text(account[cubit.AccountIndex]),
                                ),
                                if(cubit.ActivateDropdown)
                                Divider(height: 1,color: Colors.grey.shade200,),

                                ListView.builder(
                                  shrinkWrap: true,
                                  itemBuilder: (context,index) {
                                    return MaterialButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {

                                        if(index == account.length-1)
                                          {
                                            context.read<AppCubit>().signOut();

                                          } else {
                                          cubit.AccountSettingsDropdown(index);
                                        }

                                      },
                                      child: Column(
                                        children: [
                                          Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(account[index],style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400 ,fontSize: 15),textAlign: TextAlign.center,),
                                                  Icon(Icons.arrow_forward_ios,size: 20,color: Colors.grey.shade500,)
                                                ],
                                              ),
                                            ),
                                          if(index < account.length-1 )Divider(height: 1,color: Colors.grey.shade200,),
                                        ],
                                      ),
                                    );
                                  },  itemCount: account.length,
                                ),


                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left:10.0 , bottom: 8),
                            child: Text("PREFERENCES",style: context.txt.profileListHead),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width*0.8,
                            decoration: BoxDecoration(
                              color:Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if(cubit.ActivateDropdown)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                                    child: Text(preferences[cubit.AccountIndex]),
                                  ),
                                if(cubit.ActivateDropdown)
                                  Divider(height: 1,color: Colors.grey.shade200,),

                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: preferences.length,
                                  itemBuilder: (context,index) {
                                    return MaterialButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {

                                        if(index == account.length-1)
                                        {
                                          context.read<AppCubit>().signOut();

                                        } else {
                                          cubit.AccountSettingsDropdown(index);
                                        }

                                      },
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(preferences[index],style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400 ,fontSize: 15),textAlign: TextAlign.center,),
                                                Icon(Icons.arrow_forward_ios,size: 20,color: Colors.grey.shade500,)
                                              ],
                                            ),
                                          ),
                                          if(index < preferences.length-1 )Divider(height: 1,color: Colors.grey.shade200,),
                                        ],
                                      ),
                                    );
                                  },
                                ),


                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left:10.0 , bottom: 8),
                            child: Text("SUPPORT & LEGAL",style: context.txt.profileListHead),
                          ),
                          Container(
                            width: MediaQuery.sizeOf(context).width*0.8,
                            decoration: BoxDecoration(
                              color:Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if(cubit.ActivateDropdown)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                                    child: Text(support[cubit.AccountIndex]),
                                  ),
                                if(cubit.ActivateDropdown)
                                  Divider(height: 1,color: Colors.grey.shade200,),

                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: support.length,
                                  itemBuilder: (context,index) {
                                    return MaterialButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        if(index == 1)
                                        {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(maxHeight: 520, minWidth: 320),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: PolicyDialog(
                                                    mdFileName: context.loc.language == "English"
                                                        ? 'Privacy_policy.md'
                                                        : 'Privacy_policy_ar.md',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                          // context.read<AppCubit>().signOut();

                                        } else if(index == 2) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(maxHeight: 520, minWidth: 320),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: PolicyDialog(
                                                    mdFileName: context.loc.language == "English"
                                                        ?'Terms_condetions.md'
                                                        :'Terms_condetions_ar.md'
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          cubit.AccountSettingsDropdown(index);
                                        }

                                      },
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(support[index],style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400 ,fontSize: 15),textAlign: TextAlign.center,),
                                                Icon(Icons.arrow_forward_ios,size: 20,color: Colors.grey.shade500,)
                                              ],
                                            ),
                                          ),
                                          if(index < support.length-1 )Divider(height: 1,color: Colors.grey.shade200,),
                                        ],
                                      ),
                                    );
                                  },
                                ),


                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width*0.8,
                    child: Column(
                      children: [
                        MaterialButton(onPressed: (){
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 520, minWidth: 320),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Help Keep WhatsUnity Running!" , style:GoogleFonts.openSans(fontWeight: FontWeight.w600) ,),
                                      const SizedBox(height: 7,),
                                      Text("We love building WhatsUnity and our goal is to keep it a fast, independent, and ad-free experience for everyone", style:GoogleFonts.openSans()),
                                      const SizedBox(height: 7,),
                                      Text("Running servers costs money, and we rely on community donations to keep the lights on. If you find WhatsUnity useful, please consider a small contribution to support our work.", style:GoogleFonts.openSans()),
                                      const SizedBox(height: 7,),
                                      MaterialButton(
                                        color: Colors.deepOrange,
                                        height: 42,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        elevation: 0,
                                        onPressed: (){
                                          launchUrl(
                                            Uri.parse("https://ipn.eg/S/nouradawynbe/instapay/673PPO"),
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          spacing: 10,
                                          children: [
                                            FaIcon(FontAwesomeIcons.arrowRightFromBracket,color: HexColor("#ae060e"),size: 16,),
                                            Text("Instapay" , style: GoogleFonts.plusJakartaSans(color: Colors.white ,fontSize: 14, fontWeight: FontWeight.w900),),
                                          ],
                                        ),),
                                  ],),
                                ),
                              ),
                            ),
                          );
                        },
                          color: Colors.pinkAccent,
                          height: 42,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            FaIcon(FontAwesomeIcons.handHoldingHeart,color: Colors.white,size: 18,),
                            Text("Donate to Community" , style: GoogleFonts.plusJakartaSans(color: Colors.white ,fontSize: 14, fontWeight: FontWeight.w900),),
                          ],
                        ),),
                        const SizedBox(height: 10,),
                        MaterialButton(
                          color: Colors.blueGrey.shade100,
                          height: 42,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                          onPressed: (){},
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 10,
                            children: [
                              FaIcon(FontAwesomeIcons.arrowRightFromBracket,color: HexColor("#ae060e"),size: 16,),
                              Text("Log Out" , style: GoogleFonts.plusJakartaSans(color: HexColor("#ae060e") ,fontSize: 14, fontWeight: FontWeight.w900),),
                            ],
                          ),),
                      ],
                    ),
                  ),
              ],
              ),
            ),
          ),
        );
      }
    );
  }
}
