import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/GeneralChat.dart';

import '../Components/Constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Confg/supabase.dart';
import 'HomePage.dart';

class SignUp extends StatelessWidget {

   SignUp({super.key});
  TextEditingController FullName = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool signInToggler = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit,AppCubitStates>(
      builder: (BuildContext context, state) {
        return Scaffold(
          backgroundColor:HexColor("#f9f9f9"),
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40,),
                  Text(signInToggler?"LogIn Your Account":"Create Your Account" ,style:GoogleFonts.manrope(fontSize: 25, fontWeight: FontWeight.w900 , color:HexColor("#111418")),),
                  SizedBox(height: 5,),
                  Text("Join our vibrant residential community." ,style:GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500 , color:HexColor("#637488")),),
                  SizedBox(
                    height: 30,
                  ),
                  if(signInToggler == false)SizedBox(
                    width:MediaQuery.of(context).size.width*0.85,
                    child: defaultTextForm(
                      context,
                      controller: FullName,
                      keyboardType: TextInputType.name,
                      hintText:"Full Name",
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width:MediaQuery.of(context).size.width*0.85,
                    child: defaultTextForm(
                      context,
                      controller: email,
                      keyboardType: TextInputType.name,
                      hintText:"Email Address",
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width:MediaQuery.of(context).size.width*0.85,
                    child: defaultTextForm(
                      context,
                      controller: password,
                      keyboardType: TextInputType.name,
                      hintText:"Password",
                      IsPassword: true,
                    ),
                  ),
                 if(signInToggler == false) Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width*0.075
                        ),
                          alignment: AlignmentDirectional.centerStart,
                          child: Text("Select Your Role" ,style:GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w900 , color:HexColor("#111418")),)),

                      SizedBox(height: 20,),

                      Container(
                        width: MediaQuery.of(context).size.width*0.85,
                        height:80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:AppCubit.get(context).RoleName == "USER"?Border.all(color: Colors.black):null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: MaterialButton(
                          onPressed: (){
                            AppCubit.get(context).SignupRoleName("USER");
                          },
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 20,),
                              Container(
                                padding: EdgeInsets.all(5),
                                width:35,
                                height: 35,
                                decoration: BoxDecoration(

                                  color: HexColor("#dae7f7"),
                                  shape:BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  "assets/person.svg",
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Column(
                                  mainAxisAlignment:MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Text("Resident" ,style:GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600 , color:Colors.black),),
                                  Text("I live in the community" ,style:GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500 , color:HexColor("#637488")),),

                                ],),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        width: MediaQuery.of(context).size.width*0.85,
                        height:80,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border:AppCubit.get(context).RoleName == "MANAGER"?Border.all(color: Colors.black):null,
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child:MaterialButton(
                          onPressed: (){
                            AppCubit.get(context).SignupRoleName("MANAGER");
                          },
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 35,),
                              Container(
                                padding: EdgeInsets.all(5),
                                width:35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: HexColor("#dae7f7"),
                                  shape:BoxShape.circle,
                                ),
                                child: Icon(
                                    Icons.work,
                                  size: 21,
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Column(
                                  mainAxisAlignment:MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Manager" ,style:GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600 , color:Colors.black),),
                                    Text("I manage the community" ,style:GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500 , color:HexColor("#637488")),),

                                  ],),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height:
                    20,
                  ),
                  Container(
                    padding: EdgeInsets.only(
                        left:MediaQuery.of(context).size.width*0.075 ,
                        right:MediaQuery.of(context).size.width*0.075 ),
                    child: MaterialButton(
                      elevation:0,
                      color: HexColor("#dae7f7"),
                      onPressed: () async {
                        if(signInToggler ==false){
                          await supabase.auth.signUp(
                              email: email.text,
                              password: password.text,
                              data:{
                                "display_name":FullName.text.trim().split(r'\s+').first,
                                "FullName":FullName.text,
                                "role":AppCubit.get(context).RoleName,
                              }
                          );
                          await supabase.auth.signInWithPassword(
                            email: email.text,
                            password: password.text,
                          );


                        } else {
                          await supabase.auth.signInWithPassword(
                            email: email.text,
                            password: password.text,
                          );

                        }
                        UserData = Supabase.instance.client.auth.currentSession?.user;
                      if(UserData !=null) {

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child:SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: Center(child: Text(signInToggler?"Sign In":"Sign Up" ,style:GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700 , color:Colors.black),))),

                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text.rich(
                         TextSpan(
                             style:GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500 , color:HexColor("#637488")),
                             children: <TextSpan>[
                               TextSpan(text:"Already have an account?"),
                               TextSpan(
                                 text:" Sign in",
                                 style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500 , color:Colors.blue),
                                 recognizer: TapGestureRecognizer() ..onTap=(){
                                   signInToggler = !signInToggler;
                                   AppCubit.get(context).SignUpSignInToggle();
                                 },
                               ),

                             ]
                         )

        ),

                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}
