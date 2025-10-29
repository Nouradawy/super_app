import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/admob/v1.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/GeneralChat.dart';
import 'package:super_app/Layout/wellcomingPage.dart';
import 'package:super_app/Themes/lightTheme.dart';
import 'package:super_app/sevices/PresenceManager.dart';
import '../Components/Constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Confg/supabase.dart';
import '../l10n/app_localizations.dart';
import 'HomePage.dart';
bool _signInToggler = false;

class SignUp extends StatelessWidget {
  SignUp({super.key});
  final TextEditingController fullName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController compounds = TextEditingController();
  final TextEditingController buildingNum = TextEditingController();
  final TextEditingController apartmentNum = TextEditingController();



  @override
  Widget build(BuildContext context) {

    return BlocBuilder<AppCubit, AppCubitStates>(
      builder: (BuildContext context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Scaffold(
            backgroundColor: HexColor("#f9f9f9"),
            body: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      heading(context),
                      const SizedBox(height: 30),
                      form (context , email , fullName , password ),
                      if (_signInToggler == false)
                        Column(
                          children: [
                            SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.075,
                              ),
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                "Select Your Role",
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: HexColor("#111418"),
                                ),
                              ),
                            ),
                            roleSelection (context ,buildingNum ,apartmentNum ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      submitButton(context,context ,  email ,  fullName ,   password ,  buildingNum , apartmentNum ),
                      const SizedBox(height: 10),
                      footer (context),

                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> newCompound(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        content: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          width: MediaQuery.sizeOf(context).width * 0.8,
          child: JoinCommunity(),
        ),
      );
    },
  );
}

Column heading (BuildContext context){
  return Column(
    children: [
      Text(
        _signInToggler
            ? context.loc.signInHeading1
            : context.loc.signUpHeading1,
        style: context.txt.signInHeading1,
      ),
      const SizedBox(height: 5),
      Text(
        context.loc.signSubtitle,
        style: context.txt.signSubtitle,
      ),
    ],
  );
}

Column roleSelection (BuildContext context ,buildingNum ,apartmentNum  ) {
  return Column(
    children: [
      SizedBox(height: 20),
      if (AppCubit.get(context).roleName != Roles.manager)
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            border:
            AppCubit.get(context).roleName == Roles.user
                ? Border.all(color: Colors.black)
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: MaterialButton(
            onPressed: () {
              if (AppCubit.get(context).roleName != Roles.user) {
                AppCubit.get(context,).SignupRoleName(Roles.user);

              } else {
                AppCubit.get(context,).SignupRoleName(null);
              }
            },
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(width: 20),
                Container(
                  padding: EdgeInsets.all(5),
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: HexColor("#dae7f7"),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    "assets/person.svg",
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.residentRole,
                        style: context.txt.role,
                      ),
                      Text(
                        context.loc.residentRoleDescription,
                        style: context.txt.roleDescription,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      SizedBox(height: 10),
      if (AppCubit.get(context).roleName != Roles.user)  /// Hide Manger Container to view the User Form (apartmentInfo)
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            border:
            AppCubit.get(context).roleName == Roles.manager
                ? Border.all(color: Colors.black)
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: MaterialButton(
            onPressed: () {
              if (AppCubit.get(context).roleName != Roles.manager) {
                AppCubit.get(context).SignupRoleName(Roles.manager);
              } else {
                AppCubit.get(context).SignupRoleName(null);
              }
            },
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(width: 35),
                Container(
                  padding: EdgeInsets.all(5),
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: HexColor("#dae7f7"),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.work, size: 21),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                  ),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                    context.loc.managerRole,
                        style: context.txt.role,
                      ),
                      Text(
                        context.loc.managerRoleDescription,
                        style: context.txt.roleDescription,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      if (AppCubit.get(context).roleName == Roles.user)
        apartmentInfo (context , buildingNum ,  apartmentNum),
    ],
  );
}

Column apartmentInfo (BuildContext context ,TextEditingController buildingNum , TextEditingController apartmentNum) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 15,
    children: [
      MaterialButton(
        padding:EdgeInsets.zero,
        height: 50,
        elevation: 0,
        color: HexColor("#dae7f7"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
        ),
        onPressed: () {
          newCompound(context);
        },
        child: Container(
          width: MediaQuery.sizeOf(context).width*0.85,
          alignment: AlignmentDirectional.centerStart,
          padding: EdgeInsets.only(left: 20),
          child: Text(
            selectedCompoundId == null
                ? context.loc.signUpAddCompound
                : MyCompounds.values.last.toString(),
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        spacing: MediaQuery.of(context).size.width *0.05,
        children: [
          SizedBox(
            width:
            MediaQuery.of(context).size.width * 0.80/2,
            child: defaultTextForm(
              context,
              controller: buildingNum,
              keyboardType: TextInputType.text,
              hintText: context.loc.signUpBuildingNumber,
            ),
          ),
          SizedBox(
            width:
            MediaQuery.of(context).size.width * 0.80/2,
            child: defaultTextForm(
              context,
              controller: apartmentNum,
              keyboardType: TextInputType.text,
              hintText: context.loc.signUpApartmentNumber,
            ),
          ),],)
    ],
  );
}

Column form (BuildContext context , TextEditingController email , TextEditingController fullName ,  TextEditingController password ) {
  return Column(
    children: [
      if (_signInToggler == false)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: defaultTextForm(
            context,
            controller: fullName,
            keyboardType: TextInputType.name,
            hintText: context.loc.fullName,
          ),
        ),
      const SizedBox(height: 20),
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: defaultTextForm(
          context,
          controller: email,
          keyboardType: TextInputType.name,
          hintText: context.loc.emailAddress,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: defaultTextForm(
          context,
          controller: password,
          keyboardType: TextInputType.name,
          hintText: context.loc.password,
          IsPassword: true,
        ),
      ),
    ],
  );
}

Container submitButton( BuildContext buildContext ,context , TextEditingController email , TextEditingController fullName ,  TextEditingController password , TextEditingController buildingNum , TextEditingController apartmentNum ){
  return Container(
    padding: EdgeInsets.only(
      left: MediaQuery.of(context).size.width * 0.075,
      right: MediaQuery.of(context).size.width * 0.075,
    ),
    child: MaterialButton(
      elevation: 0,
      color: HexColor("#dae7f7"),
      onPressed: () async {
        ///Sign up case......
        if (_signInToggler == false) {
          await supabase.auth.signUp(
            email: email.text,
            password: password.text,
            data: {
              "display_name": fullName.text.trim().split(r'\s+').first,
              "FullName": fullName.text,
              "role_id": AppCubit.get(context).roleName!.index+1,
              'compound_id':selectedCompoundId.toString(),
              'building_num': buildingNum.text,
              'apartment_num': apartmentNum.text
            },
          );

          await supabase.auth.signInWithPassword(
            email: email.text,
            password: password.text,
          );
        }
        ///Sign in case......
        else {
          await supabase.auth.signInWithPassword(
            email: email.text,
            password: password.text,
          );
        }

        UserData = Supabase.instance.client.auth.currentSession?.user;
        Userid =  UserData!.id;

        AppCubit.get(context).getPostsData(selectedCompoundId);
        if (UserData != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PresenceManager(child: HomePage()),
            ),
          );
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: Center(
          child: Text(
            _signInToggler ? buildContext.loc.signIn : buildContext.loc.signUp,
            style: buildContext.txt.role.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
}

Row footer (BuildContext context){
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text.rich(
        TextSpan(
          style: context.txt.signSubtitle,
          children: <TextSpan>[
            TextSpan(
              text:
              _signInToggler
                  ? context.loc.signUpQuestion
                  : context.loc.haveAccountQuestion,
            ),
            TextSpan(
              text: _signInToggler ? context.loc.signUp : context.loc.signIn,
              style: context.txt.signSubtitle.copyWith(color: Colors.blue),
              recognizer:
              TapGestureRecognizer()
                ..onTap = () {
                  _signInToggler = !_signInToggler;
                  AppCubit.get(
                    context,
                  ).SignUpSignInToggle();
                },
            ),
          ],
        ),
      ),
    ],
  );
}