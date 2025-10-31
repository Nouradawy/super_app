import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v2.dart' as drive;
import 'package:hexcolor/hexcolor.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_app/Confg/supabase.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/chatWidget/GeneralChat/GeneralChat.dart';

import '../Components/Constants.dart';
import '../main.dart';
import '../sevices/GoogleDriveService.dart';
import 'SignUp.dart';

class Profile extends StatelessWidget {

  Profile({super.key});
  final List profile = ["Edit Profile","Notifications","Privacy","Security" , "SignOut"];
  TextEditingController UserName = TextEditingController();



  @override
  Widget build(BuildContext context) {

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
                        backgroundImage: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuC0gA22XSLt6JF3Am-2RSZ2ErhBjK3JHiF8Bw6RU56kDjQ2Ln4xcsvZkuHOPsBkUEaZ-j20SSNFl1WRv6O-SUdr2zgotNghimzgNh95viw-PwFqSXQRq-rlKoDjuZ3dlS_9lKrVBswIe0kU95v9OeerbUXrckK5VFZft2-fwIpU_m_rwbWNgrrAFNibY1KnmxljY3ACtUNuuVLA2Ll-dmSBJzgAtt2KrH4Pz_mIgw8_U26DlTF_HenZZa5zQz9CzG6UYzIrj7G6jKA"),
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
            
                Text(UserData?.userMetadata?["display_name"]?.toString() ?? "Guest",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 20),),
                if(UserData !=null) ...[
                  Text("Resident",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500 ,fontSize: 13, color: HexColor("#637488")),),
                  Text("Joined 2022",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500 ,fontSize: 11, color: HexColor("#637488")),),
                ],


                  MaterialButton(onPressed: () async {
                    AppCubit.get(context).googleSignin(

                    );

                  },
                    child: Text(googleUser ==  null?"Link Drive":"Unlink"),),
                  SizedBox(height: 20),
                  Container(
                    width: MediaQuery.sizeOf(context).width*0.8,
                    decoration: BoxDecoration(
                      color:Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                          child: Text(AppCubit.get(context).ActivateDropdown?profile[AppCubit.get(context).AccountIndex]:"Account",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700 ,fontSize: 15),),
                        ),
                        Divider(height: 1,color: Colors.grey.shade200,),

                        ListView.builder(
                          shrinkWrap: true,
                          itemBuilder: (context,index) {
                            return MaterialButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {

                                if(index == profile.length-1)
                                  {
                                    context.read<AppCubit>().signOut();

                                  } else {
                                  AppCubit.get(context).AccountSettingsDropdown(index);
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
                                          Text(profile[index],style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400 ,fontSize: 15),textAlign: TextAlign.center,),
                                          Icon(index == profile.length-1 ? Icons.logout:Icons.arrow_forward_ios,size: 20,color: Colors.grey.shade500,)
                                        ],
                                      ),
                                    ),
                                  if(index < profile.length-1 )Divider(height: 1,color: Colors.grey.shade200,),
                                ],
                              ),
                            );
                          },  itemCount: profile.length,
                        ),
                        if(AppCubit.get(context).AccountIndex == 0 && AppCubit.get(context).ActivateDropdown)Column(
                          children: [
                            Container(
                              padding:EdgeInsets.symmetric(vertical: 10),
                              child: defaultTextForm(context,controller: UserName , keyboardType: TextInputType.text ,hintText:UserData?.userMetadata?["display_name"] ?? "Display name",),),

                            MaterialButton(
                                onPressed: () async {
                                  final UserResponse res = await supabase.auth.updateUser(
                                    UserAttributes(

                                      data: { 'display_name': UserName.text },
                                    ),
                                  );

                                  UserData = res.user;
                                  AppCubit.get(context).AccountSettingsDropdown(0);
                                },
                              child: Text("Update"),
                            ),
                          ],
                        ),
            
                      ],
                    ),
                  ),
              ],),
            ),
          ),
        );
      }
    );
  }
}
