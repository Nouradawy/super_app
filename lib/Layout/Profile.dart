import 'package:WhatsUnity/Confg/Enums.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:WhatsUnity/Themes/lightTheme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Components/Constants.dart';
import '../Confg/supabase.dart';
import '../OTPScreen.dart';
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

  TextEditingController userName = TextEditingController(text: currentUser?.displayName);
  TextEditingController fullName = TextEditingController(text: currentUser?.fullName);
  TextEditingController email = TextEditingController(text: UserData?.email);
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  final emailFocusNode = FocusNode();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();





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
                  // Text(currentUser!.ownerType!.name,style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500 ,fontSize: 13, color: HexColor("#637488")),),
                  Text('Building ${currentUser?.building} • Apartment ${currentUser?.apartment}',style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500 ,fontSize: 11, color: HexColor("#637488")),),
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
                                ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount:UserData?.appMetadata["provider"] == "google" ?1:account.length,  //TODO: google filter reset
                                  itemBuilder: (context,index) {
                                    return AnimatedCrossFade(
                                      key: ValueKey('account_item_$index'),
                                      crossFadeState: context.watch<AppCubit>().isActive(ProfileSection.account, index)
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(milliseconds: 500),
                                      firstCurve: Curves.easeInOut,
                                      secondCurve: Curves.easeInOut,
                                      sizeCurve: Curves.easeInOut,
                                      firstChild: MaterialButton(
                                        key: ValueKey('account_collapsed_$index'),
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          debugPrint(UserData?.appMetadata["provider"].toString());
                                          cubit.accountSettingsDropdown(ProfileSection.account,index);

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
                                            if(index < account.length-1 && UserData?.appMetadata["provider"] != "google") Divider(height: 1,color: Colors.grey.shade200,),

                                          ],
                                        ),
                                      ),
                                      secondChild: MaterialButton(
                                        key: ValueKey('account_expanded_$index'),
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          cubit.accountSettingsDropdown(ProfileSection.account,index);
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
                                            if(index < account.length-1) Divider(height: 1,color: Colors.grey.shade200,),
                                            if(index ==0) Column(
                                                children: [

                                                  if(cubit.isOTP==false) ...[
                                                  Form(
                                                    key:_formKey1,
                                                    child: Column(
                                                      children: [
                                                        const SizedBox(height: 25),
                                                        SizedBox(
                                                          width: MediaQuery.of(context).size.width * 0.70,
                                                          child: defaultTextForm(
                                                            context,
                                                            controller: fullName,
                                                            onChanged: (v)=>context.read<AppCubit>().profileApplyChanges(),
                                                            validation: (value){
                                                              if (value == null || value.trim().isEmpty) {
                                                                return "fullName can't be Empty";
                                                              }
                                                              return null;
                                                            },
                                                            keyboardType: TextInputType.name,
                                                            labelText: context.loc.displayName,

                                                          ),
                                                        ),
                                                        const SizedBox(height: 15),
                                                        SizedBox(
                                                          width: MediaQuery.of(context).size.width * 0.70,
                                                          child: defaultTextForm(
                                                            context,
                                                            controller: userName,
                                                            onChanged: (v)=>context.read<AppCubit>().profileApplyChanges(),
                                                            validation: (value){
                                                              if (value == null || value.trim().isEmpty) {
                                                                return "userName can't be Empty";
                                                              }
                                                              return null;
                                                            },
                                                            keyboardType: TextInputType.name,
                                                            labelText: context.loc.displayName,

                                                          ),
                                                        ),
                                                        if(UserData?.appMetadata["provider"].toString() != "google") ...[
                                                          const SizedBox(height: 15),

                                                          SizedBox(
                                                            width: MediaQuery.of(context).size.width * 0.70,
                                                            child: defaultTextForm(
                                                              context,
                                                              controller: email,
                                                              onChanged: (v)=>context.read<AppCubit>().profileApplyChanges(),
                                                              validation: (value){
                                                                if (value == null || value.trim().isEmpty) {
                                                                  return "email can't be Empty";
                                                                }
                                                                return null;
                                                              },
                                                              keyboardType: TextInputType.name,
                                                              labelText: context.loc.emailAddress,

                                                            ),
                                                          ),
                                                          if (state is AppEmailChangeFailedState)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 8.0),
                                                              child: Text(
                                                                state.message,
                                                                style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w600),
                                                              ),
                                                            ),
                                                        ],
                                                        const SizedBox(height: 15),
                                                      ],
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:AlignmentDirectional.centerEnd,
                                                    child: Padding(
                                                      padding:  EdgeInsets.only(right:MediaQuery.sizeOf(context).width*0.050, bottom: 7),
                                                      child: MaterialButton(
                                                        onPressed:() async {

                                                          if (!(_formKey1.currentState?.validate() ?? false)) return;
                                                          if(userName.text != currentUser?.displayName) {
                                                            await supabase.from('profiles').update(
                                                              {'display_name':userName.text , 'full_name':fullName.text})
                                                              .eq('id', currentUser!.id);

                                                            if(email.text == UserData?.email) {
                                                              final authRes = await supabase.auth.refreshSession();
                                                              final session = authRes.session;
                                                              UserData = session?.user;
                                                              await AppCubit.get(context).loadCompoundMembers(selectedCompoundId!);
                                                            }

                                                          }
                                                          if(email.text != UserData?.email){
                                                            cubit.requestEmailChange(email.text);
                                                          }

                                                        } ,
                                                        elevation: 0,
                                                        disabledColor: Colors.indigo.shade200,
                                                        color: Colors.indigoAccent.shade200,
                                                        child: Text("Apply",style: TextStyle(color: Colors.white),),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                                  if(cubit.isOTP)...[
                                                    SizedBox(
                                                        height:MediaQuery.sizeOf(context).height*0.36,
                                                        child: OtpScreen(email:email.text,isProfile: true,)),
                                                  ]

                                                ]
                                              ),

                                            if(index ==1) Form(
                                              key: _formKey2,
                                              child: Column(
                                                children: [
                                                  const SizedBox(height: 25),
                                                  SizedBox(
                                                    width: MediaQuery.of(context).size.width * 0.70,
                                                    child: defaultTextForm(
                                                      context,
                                                      controller: password,
                                                      IsPassword:true,
                                                      onChanged: (v)=>context.read<AppCubit>().profileApplyChanges(),
                                                      validation: (value){
                                                        if (value == null || value.trim().isEmpty) {
                                                          return "password can't be Empty";
                                                        }
                                                        if(password.text != confirmPassword.text) {
                                                          return "password mismatch";
                                                        }
                                                        return null;
                                                      },
                                                      keyboardType: TextInputType.name,
                                                      labelText: context.loc.password,

                                                    ),
                                                  ),

                                                    const SizedBox(height: 15),

                                                    SizedBox(
                                                      width: MediaQuery.of(context).size.width * 0.70,
                                                      child: defaultTextForm(
                                                        context,
                                                        controller: confirmPassword,
                                                        IsPassword:true,
                                                        onChanged: (v)=>context.read<AppCubit>().profileApplyChanges(),
                                                        validation: (value){
                                                          if (value == null || value.trim().isEmpty) {
                                                            return "confirm password can't be Empty";
                                                          }
                                                          if(password.text != confirmPassword.text) {
                                                            return "password mismatch";
                                                          }
                                                          return null;
                                                        },
                                                        keyboardType: TextInputType.name,
                                                        labelText: context.loc.confirmPassword,

                                                      ),
                                                    ),

                                                  if (state is AppPasswordUpdatedState)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: Text(
                                                        'Password changed successfully',
                                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),

                                                  const SizedBox(height: 15),
                                                  Align(
                                                    alignment:AlignmentDirectional.centerEnd,
                                                    child: Padding(
                                                      padding:  EdgeInsets.only(right:MediaQuery.sizeOf(context).width*0.050, bottom: 7),
                                                      child: MaterialButton(
                                                        onPressed:() async {
                                                          if (!(_formKey2.currentState?.validate() ?? false)) return;
                                                          await supabase.auth.updateUser(UserAttributes(password: password.text));
                                                          cubit.appPasswordUpdated();
                                                        } ,
                                                        elevation: 0,
                                                        disabledColor: Colors.indigo.shade200,
                                                        color: Colors.indigoAccent.shade200,
                                                        child: Text("Submit changes",style: TextStyle(color: Colors.white),),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: preferences.length,
                                  itemBuilder: (context,index) {
                                    return AnimatedCrossFade(
                                      key: ValueKey('preferences_item_$index'),
                                      crossFadeState: context.watch<AppCubit>().isActive(ProfileSection.preferences, index)
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(milliseconds: 500),
                                      firstCurve: Curves.easeInOut,
                                      secondCurve: Curves.easeInOut,
                                      sizeCurve: Curves.easeInOut,
                                      firstChild: MaterialButton(
                                        key: ValueKey('preferences_collapsed_$index'),
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          cubit.accountSettingsDropdown(ProfileSection.preferences , index);

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
                                      ),
                                      secondChild: MaterialButton(
                                        key: ValueKey('preferences_expanded_$index'),
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {

                                          cubit.accountSettingsDropdown(ProfileSection.preferences , index);

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
                                            //TODO: EDIT:Preferences 1st tab
                                            if(index ==0) Column(
                                              children: [
                                                Text("Coming Soon"),
                                              ],
                                            ),
                                          ],
                                        ),
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

                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: support.length,
                                  itemBuilder: (context,index) {
                                    return AnimatedCrossFade(
                                      key: ValueKey('support_item_$index'),

                                      crossFadeState: context.watch<AppCubit>().isActive(ProfileSection.support, index)
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(milliseconds: 500),
                                      firstCurve: Curves.easeInOut,
                                      secondCurve: Curves.easeInOut,
                                      sizeCurve: Curves.easeInOut,
                                      firstChild: MaterialButton(
                                        key: ValueKey('support_collapsed_$index'),
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {

                                          cubit.accountSettingsDropdown(ProfileSection.support , index);

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
                                      ),
                                      secondChild: MaterialButton(
                                        key: ValueKey('support_expanded_$index'),
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
                                            cubit.accountSettingsDropdown(ProfileSection.support , index);
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
                                            // if(index ==0) Column(
                                            //   children: [
                                            //     SizedBox(
                                            //       width: MediaQuery.of(context).size.width * 0.85,
                                            //       child: defaultTextForm(
                                            //         context,
                                            //         controller: userName,
                                            //         validation: (value){
                                            //           if (value == null || value.trim().isEmpty) {
                                            //             return "Full Name can't be Empty";
                                            //           }
                                            //           return null;
                                            //         },
                                            //         keyboardType: TextInputType.name,
                                            //         labelText: context.loc.fullName,
                                            //         hintText: "Identical to your documents for verification ",
                                            //
                                            //       ),
                                            //     ),
                                            //   ],
                                            // ),
                                          ],
                                        ),
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
                          onPressed: (){
                            context.read<AppCubit>().signOut();
                          },
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
