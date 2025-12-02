import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/admob/v1.dart';
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
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();



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
                          form (context , email , fullName , displayName, password , phoneNumber , _formKey1 ),
                          if (cubit.signInToggler == false)
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
                                roleSelection (context ,buildingNum ,apartmentNum, _formKey2 ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          if(AppCubit.get(context).signupGoogleEmail == null)
                          submitButton(context,context ,email , fullName , displayName, password ,buildingNum , apartmentNum ,phoneNumber , _formKey1 , _formKey2),
                          signInProviders(context ,fullName ,buildingNum , apartmentNum ,phoneNumber ,displayName , _formKey1 , _formKey2),
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
          child: JoinCommunity(atWelcome: true,),
        ),
      );
    },
  );
}

Column heading (BuildContext context){
  return Column(
    children: [
      Text(
        AppCubit.get(context).signInToggler
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

Column roleSelection (BuildContext context ,buildingNum ,apartmentNum , _formKey2 ) {
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
        apartmentInfo (context , buildingNum ,  apartmentNum , _formKey2 ),
    ],
  );
}

Form apartmentInfo (BuildContext context ,TextEditingController buildingNum ,
    TextEditingController apartmentNum  ,GlobalKey _formKey2 ) {

  return Form(
    key:_formKey2,
    child: Column(
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
                validation: (value){
                  if (value == null || value.trim().isEmpty) {
                    return "Building Number can't be Empty";
                  }
                  return null;
                },
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
                validation: (value){
                  if (value == null || value.trim().isEmpty) {
                    return "Apartment Number can't be Empty";
                  } else if (AppCubit.get(context).apartmentConflict){
                    return "Apartment already taken";
                  }
                  return null;
                },

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
                height: MediaQuery.sizeOf(context).height*0.15,
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
    ),
  );
}

Form form (BuildContext context , TextEditingController email ,
    TextEditingController fullName , TextEditingController displayName ,
    TextEditingController password ,TextEditingController phoneNumber , GlobalKey _formKey1) {
  return Form(
    key:_formKey1,
    child: Column(
      children: [
        if(AppCubit.get(context).signInToggler == false)...[

          SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: defaultTextForm(
              context,
              controller: fullName,
              validation: (value){
                if (value == null || value.trim().isEmpty) {
                  return "Full Name can't be Empty";
                }
                return null;
              },
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
              validation: (value){
                if (value == null || value.trim().isEmpty) {
                  return "Username can't be Empty";
                }
                return null;
              },
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
            validation: (value){
              if (value == null || value.trim().isEmpty) {
                return "email address can't be Empty";
              }
              return null;
            },
            keyboardType: TextInputType.emailAddress,
            labelText: context.loc.emailAddress,
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
              validation: (value){
                if (value == null || value.trim().isEmpty) {
                  return "password can't be Empty";
                }
                return null;
              },
              keyboardType: TextInputType.text,
              labelText: context.loc.password,
              hintText: context.loc.password,
              IsPassword: true,
            ),
          ),
        ],

        const SizedBox(height: 10),
        if (AppCubit.get(context).signInToggler == false)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: defaultTextForm(
            context,
            controller: phoneNumber,
            validation: (value){
              if (value == null || value.trim().isEmpty) {
                return "phoneNumber can't be Empty";
              }
              return null;
            },
            keyboardType: TextInputType.number,
            labelText: context.loc.phoneNumber,
            hintText: "Whatsapp phone number",
          ),
        ),
      ],
    ),
  );
}

Column submitButton( BuildContext buildContext ,context ,
    TextEditingController email , TextEditingController fullName , TextEditingController displayName ,
    TextEditingController password , TextEditingController buildingNum , TextEditingController apartmentNum , TextEditingController phoneNumber ,
    GlobalKey<FormState> _formKey1 , GlobalKey<FormState> _formKey2
    ){

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if(AppCubit.get(context).apartmentConflict || (AppCubit.get(context).verFiles==null && AppCubit.get(context).signingIn ))...[
        Text(buildContext.loc.apartmentConflict1, style: buildContext.txt.signSubtitle.copyWith(color: Colors.pinkAccent ,fontWeight: FontWeight.w400)),
        Text(buildContext.loc.apartmentConflict2, style: buildContext.txt.signSubtitle.copyWith(color: Colors.pinkAccent ,fontWeight: FontWeight.w400)),
        if(AppCubit.get(context).verFiles==null)
        Text(buildContext.loc.apartmentConflict3, style: buildContext.txt.signSubtitle.copyWith(color: Colors.pinkAccent ,fontWeight: FontWeight.w400))
      ],

      Container(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.075,
          right: MediaQuery.of(context).size.width * 0.075,
        ),
        child: MaterialButton(
          elevation: 0,
          color: HexColor("#dae7f7"),
          enableFeedback: AppCubit.get(context).signingIn,
          disabledColor: Colors.grey,
          onPressed: AppCubit.get(context).signingIn == true
            ? null
            :() async {

            ///Sign up case......
            if (AppCubit.get(context).signInToggler == false) {
              await AppCubit.get(context).apartmentAlreadyTaken(
                compoundId: selectedCompoundId!.toString(),
                buildingNum: buildingNum.text,
                apartmentNum: apartmentNum.text,
              );
              // 2) Validate forms; stop if either is invalid
              final isForm1Valid = _formKey1.currentState?.validate() ?? false;
              final isForm2Valid = _formKey2.currentState?.validate() ?? false;
              if (!isForm1Valid || !isForm2Valid) {
                return; // Do not continue to signup or toggle signing state
              }



              final building = buildingNum.text.trim();
              final apartment = apartmentNum.text.trim();
              if ((selectedCompoundId == null) ||  (building.isEmpty || apartment.isEmpty) ) {
                if (!buildContext.mounted) return;
                ScaffoldMessenger.of(buildContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text( selectedCompoundId == null?'Please select a compound.' : 'Building and apartment are required.'),
                    ),
                  );
                return;
              }
              AppCubit.get(context).signInSwitcher();

              try {
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

              AppCubit.get(context).signInSwitcher();
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
                  if(AppCubit.get(context).signingIn == true) ...[
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator()),
                  ],
                  Text(
                    AppCubit.get(context).signInToggler ? buildContext.loc.signIn : buildContext.loc.signUp,
                    style: buildContext.txt.role.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Column signInProviders (BuildContext context ,TextEditingController fullName ,
    TextEditingController buildingNum , TextEditingController apartmentNum , TextEditingController phoneNumber ,
    TextEditingController userName , GlobalKey<FormState> _formKey1 , GlobalKey<FormState> _formKey2){
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
          onPressed: () async {
            if(AppCubit.get(context).signInToggler)
              {
                AppCubit.get(context).supabaseSignInWithGoogle(context:context,isSignin: true);
              }
            else if(AppCubit.get(context).signupGoogleEmail == null ) {

              AppCubit.get(context).supabaseSignInWithGoogle(context:context);
            } else {


              // 2) Validate forms; stop if either is invalid
              final isForm1Valid = _formKey1.currentState?.validate() ?? false;
              final isForm2Valid = _formKey2.currentState?.validate() ?? false;
              if (!isForm1Valid || !isForm2Valid) {
                return; // Do not continue to signup or toggle signing state
              }
              await AppCubit.get(context).apartmentAlreadyTaken(
                compoundId: selectedCompoundId!.toString(),
                buildingNum: buildingNum.text,
                apartmentNum: apartmentNum.text,
              );

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
              Text(AppCubit.get(context).signupGoogleEmail != null?"Continue Google Registration":AppCubit.get(context).signInToggler?"Sign in with Google":"Register with Google")
            ],),
        ),
      ),
    ],
  );
}

Row footer (BuildContext context ){
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text.rich(
        TextSpan(
          style: context.txt.signSubtitle,
          children: <TextSpan>[
            TextSpan(
              text:
              AppCubit.get(context).signInToggler
                  ? context.loc.signUpQuestion
                  : context.loc.haveAccountQuestion,
            ),
            TextSpan(
              text: AppCubit.get(context).signInToggler ? " ${context.loc.signUpFooter}" : " ${context.loc.signIn}",
              style: context.txt.signSubtitle.copyWith(color: Colors.blue , fontWeight: FontWeight.w800),
              recognizer:
              TapGestureRecognizer()
                ..onTap = () {

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


