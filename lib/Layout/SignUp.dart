import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:WhatsUnity/Layout/Cubit/cubit.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:WhatsUnity/Layout/wellcomingPage.dart';
import 'package:WhatsUnity/Themes/lightTheme.dart';
import 'package:WhatsUnity/services/PresenceManager.dart';
import '../Components/Constants.dart';


import '../Confg/Enums.dart';
import '../Confg/supabase.dart';
import '../OTPScreen.dart';
import 'MainScreen.dart';
bool _signInToggler = false;

class SignUp extends StatelessWidget {
  SignUp({super.key});
  final TextEditingController fullName = TextEditingController();
  final TextEditingController displayName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController compounds = TextEditingController();
  final TextEditingController buildingNum = TextEditingController();
  final TextEditingController apartmentNum = TextEditingController();
  final TextEditingController phoneNumber = TextEditingController();





  @override
  Widget build(BuildContext context) {
    final cubit = AppCubit.get(context);
    if(cubit.signupGoogleUserName != null) displayName.text = cubit.signupGoogleUserName!;
    bool signupMail = false;
    bool signinMail = false;
    return BlocBuilder<AppCubit, AppCubitStates>(
      builder: (BuildContext context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Scaffold(
            backgroundColor: HexColor("#f9f9f9"),
            body: SafeArea(
              child: Stack(
                alignment: AlignmentDirectional.center,
                fit: StackFit.expand,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          heading(context),
                          const SizedBox(height: 30),
                          form (context , email , fullName , displayName, password , phoneNumber ),
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
                          if(AppCubit.get(context).signupGoogleEmail == null)
                          submitButton(context,context ,  email ,  fullName , displayName, password ,  buildingNum , apartmentNum ,phoneNumber ),
                          signInProviders(context,fullName ,buildingNum , apartmentNum ,phoneNumber ,displayName),
                          SizedBox(height: 70,),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                      bottom: 30,
                      child: footer(context)),
                ],
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
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: [
          Padding(
            padding: const EdgeInsets.only(left:15.0),
            child: MaterialButton(
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
                width: MediaQuery.sizeOf(context).width*0.80/2,
                alignment: AlignmentDirectional.centerStart,
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  selectedCompoundId == null
                      ? context.loc.signUpAddCompound
                      : MyCompounds.values.last.toString(),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 28.0),
            child: SegmentedButton<OwnerTypes>(
              selected: <OwnerTypes>{AppCubit.get(context).ownerType},
              onSelectionChanged: (Set<OwnerTypes> newSelection)=>context.read<AppCubit>().ownerTypeChange(newSelection.first),
              segments: <ButtonSegment<OwnerTypes>>[

                ButtonSegment<OwnerTypes>(
                  value: OwnerTypes.owner,
                  label: Text(context.loc.owner),
                ),
                ButtonSegment<OwnerTypes>(
                  value: OwnerTypes.rental,
                  label: Text(context.loc.rental),
                ),
              ],
            ),
          ),

        ],
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
              keyboardType: TextInputType.number,
              hintText: context.loc.signUpBuildingNumber,
            ),
          ),
          SizedBox(
            width:
            MediaQuery.of(context).size.width * 0.80/2,
            child: defaultTextForm(
              context,
              controller: apartmentNum,
              keyboardType: TextInputType.number,
              hintText: context.loc.signUpApartmentNumber,
            ),
          ),],),
      Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width*0.75,
            child: GridView.builder(
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
              itemCount: context.read<AppCubit>().verFiles?.length ?? 0,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(context.read<AppCubit>().verFiles![index].path),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          context.read<AppCubit>().verFiles != null
              ? IconButton(
            onPressed: () {
              context.read<AppCubit>().verFiles = null;
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
                  Text(context.loc.uploadPhotosVerFiles,style: GoogleFonts.plusJakartaSans(fontWeight:FontWeight.w400),),

                  MaterialButton(
                    onPressed: ()=>context.read<AppCubit>().verFileImport(),
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

    ],
  );
}

Column form (BuildContext context , TextEditingController email , TextEditingController fullName , TextEditingController displayName ,  TextEditingController password ,TextEditingController phoneNumber) {
  return Column(
    children: [
      if(_signInToggler == false)...[

        SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: defaultTextForm(
            context,
            controller: fullName,
            keyboardType: TextInputType.name,
            labelText: context.loc.fullName,
            hintText: "Identical to your documents for verification ",

          ),
        ),

        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: defaultTextForm(
            context,
            controller: displayName,
            keyboardType: TextInputType.text,
            labelText: context.loc.displayName,
            hintText: context.loc.displayName,
          ),
        ),
      ],

      const SizedBox(height: 10),
      if(AppCubit.get(context).signupGoogleEmail == null)
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: defaultTextForm(
          context,
          controller: email,
          keyboardType: TextInputType.emailAddress,
          hintText: context.loc.emailAddress,
        ),
      ),
      if(AppCubit.get(context).signupGoogleEmail != null)
        Container(
          padding: EdgeInsets.only(right: 30 , left: 10),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey.shade300 , width: 1),
          ),

          width: MediaQuery.of(context).size.width * 0.85,
          height: 45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppCubit.get(context).signupGoogleEmail! , style: GoogleFonts.manrope(color: Colors.grey.shade500 ,fontWeight: FontWeight.w700  ,fontSize: 13),),
              Icon(Icons.check_circle , color: Colors.greenAccent,)
            ],
          ),
        ),
      if(AppCubit.get(context).signupGoogleEmail == null) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: defaultTextForm(
            context,
            controller: password,
            keyboardType: TextInputType.text,
            hintText: context.loc.password,
            IsPassword: true,
          ),
        ),
      ],

      const SizedBox(height: 10),
      if (_signInToggler == false)
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: defaultTextForm(
          context,
          controller: phoneNumber,
          keyboardType: TextInputType.number,
          labelText: context.loc.phoneNumber,
          hintText: "Whatsapp phone number",
        ),
      ),
    ],
  );
}

Container submitButton( BuildContext buildContext ,context , TextEditingController email , TextEditingController fullName , TextEditingController displayName ,  TextEditingController password , TextEditingController buildingNum , TextEditingController apartmentNum , TextEditingController phoneNumber ){
  return Container(
    padding: EdgeInsets.only(
      left: MediaQuery.of(context).size.width * 0.075,
      right: MediaQuery.of(context).size.width * 0.075,
    ),
    child: MaterialButton(
      elevation: 0,
      color: HexColor("#dae7f7"),
      enableFeedback: AppCubit.get(context).signingIn,
      disabledColor: Colors.grey,
      onPressed: AppCubit.get(context).signingIn == false
        ? null
        :() async {
        AppCubit.get(context).signInSwitcher();
        ///Sign up case......
        if (_signInToggler == false) {

          try {
            if (selectedCompoundId == null) {
              AppCubit.get(context).signInSwitcher();
              if (!buildContext.mounted) return;
              ScaffoldMessenger.of(buildContext)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Please select a compound.'),
                  ),
                );
              return;
            }

            final building = buildingNum.text.trim();
            final apartment = apartmentNum.text.trim();

            if (building.isEmpty || apartment.isEmpty) {
              AppCubit.get(context).signInSwitcher();
              if (!buildContext.mounted) return;
              ScaffoldMessenger.of(buildContext)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Building and apartment are required.'),
                  ),
                );
              return;
            }

            final taken = await apartmentAlreadyTaken(
              compoundId: selectedCompoundId!.toString(),
              buildingNum: buildingNum.text,
              apartmentNum: apartmentNum.text,
            );

            if (taken) {
              AppCubit.get(context).signInSwitcher();
              if (!buildContext.mounted) return;
              ScaffoldMessenger.of(buildContext)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(buildContext.loc.apartmentConflict1),
                        Text(buildContext.loc.apartmentConflict2),
                        Text.rich(TextSpan(
                          text: buildContext.loc.apartmentConflict3,
                          style: buildContext.txt.signSubtitle.copyWith(color: Colors.blue),
                          recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                            AppCubit.get(context).apartmentConflict = true;
                            },
                        )),

                      ],
                    ),
                  ),
                );
              if(AppCubit.get(context).apartmentConflict ==false)
              {
                return;
              }

            }
            if(AppCubit.get(context).apartmentConflict = true && AppCubit.get(context).verFiles==null){
              AppCubit.get(context).signInSwitcher();
              ScaffoldMessenger.of(buildContext)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(buildContext.loc.apartmentConflict4),
                        Text(buildContext.loc.apartmentConflict2),


                      ],
                    ),
                  ),
                );
            }

            await supabase.auth.signUp(
              email: email.text,
              password: password.text,
              data: {
                "display_name": displayName.text,
                "FullName": fullName.text,
                "role_id": AppCubit.get(context).roleName!.index+1,
                'compound_id':selectedCompoundId.toString(),
                'building_num': buildingNum.text,
                'apartment_num': apartmentNum.text,
                "ownerType" : AppCubit.get(context).ownerType.name,
                "phoneNumber" : phoneNumber.text,
              },
            );
          } on AuthException catch (error) {

            AppCubit.get(context).signInSwitcher();
            ScaffoldMessenger.of(buildContext).showSnackBar(
              SnackBar(
                backgroundColor: Colors.pink,
                behavior: SnackBarBehavior.floating,
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline),
                    const SizedBox(width: 8),
                    Flexible(child: Text(error.message.toString())),
                  ],
                ),
              ),
            );
            return;
          }


          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OtpScreen().copyWithEmail(email.text)),
          );

          return;

        }
        ///Sign in case......
        else {
          AppCubit.get(context).resetUserData();
          try{
            await supabase.auth.signInWithPassword(
              email: email.text,
              password: password.text,
            );
          }on AuthException catch(error){
            AppCubit.get(context).signInSwitcher();
            ScaffoldMessenger.of(buildContext).showSnackBar(
              SnackBar(
                backgroundColor: Colors.pink,
                behavior: SnackBarBehavior.floating,
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline),
                    const SizedBox(width: 8),
                    Flexible(child: Text(error.message.toString())),
                  ],
                ),
              ),
            );
          }
        }


        UserData = Supabase.instance.client.auth.currentSession?.user;
        userRole = Roles.values[UserData?.userMetadata?["role_id"]];

        if (UserData != null) {
          presetBeforeSignin(context);
          AppCubit.get(context).signInSwitcher();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PresenceManager(child: MainScreen()),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              if(AppCubit.get(context).signingIn == false) ...[
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator()),
              ],
              Text(
                _signInToggler ? buildContext.loc.signIn : buildContext.loc.signUp,
                style: buildContext.txt.role.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Column signInProviders (BuildContext context , TextEditingController fullName ,TextEditingController buildingNum , TextEditingController apartmentNum , TextEditingController phoneNumber , TextEditingController userName ){
  return Column(
    children: [
      if(AppCubit.get(context).signupGoogleEmail == null)
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text("or" , style: TextStyle(fontWeight: FontWeight.w700 , color: Colors.grey),),
      ),
      Container(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.075,
          right: MediaQuery.of(context).size.width * 0.075,
        ),
        child: MaterialButton(
          height: 40,
          onPressed: (){
            if(_signInToggler)
              {
                AppCubit.get(context).supabaseSignInWithGoogle(context:context,isSignin: true);
              }
            else if(AppCubit.get(context).signupGoogleEmail == null) {
              AppCubit.get(context).supabaseSignInWithGoogle(context:context);
            } else {
              AppCubit.get(context).continueGoogleRegistration(context ,fullName.text , AppCubit.get(context).roleName!.index+1 ,buildingNum.text , apartmentNum.text ,AppCubit.get(context).ownerType , phoneNumber.text ,userName.text );
            }

          },
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.black26 , width: 1)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 15,
            children: [
              Image.asset("assets/Google_icon-may25.webp",height: 25,),
              Text(AppCubit.get(context).signupGoogleEmail != null?"Continue Google Registration":_signInToggler?"Sign in with Google":"Register with Google")
            ],),
        ),
      ),
    ],
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
              text: _signInToggler ? " ${context.loc.signUpFooter}" : " ${context.loc.signIn}",
              style: context.txt.signSubtitle.copyWith(color: Colors.blue , fontWeight: FontWeight.w800),
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

Future<bool> apartmentAlreadyTaken({
  required String compoundId,
  required String buildingNum,
  required String apartmentNum,
}) async {
  final rows = await supabase
      .from('user_apartments')
      .select('user_id')
      .eq('compound_id', compoundId)
      .eq('building_num', buildingNum)
      .eq('apartment_num', apartmentNum)
      .limit(1);
  return rows.isNotEmpty;
}