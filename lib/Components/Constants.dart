import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:permission_handler/permission_handler.dart';
import '../sevices/GoogleDriveService.dart';

final GoogleDriveService driveService = GoogleDriveService();
GoogleSignInAccount? googleUser;
Map<String,dynamic> MyCompounds = {'0': "Add New Community"};
int? selectedCompoundId;

Future<void> requestPermission() async {
  if(await Permission.microphone.status.isDenied || await Permission.storage.status.isDenied)
  {
    await [
      Permission.microphone,
      Permission.storage
    ].request();
  }
}


Widget defaultTextForm(
    context,{
      required TextEditingController controller,
      required TextInputType keyboardType,
      String? hintText,
      bool IsPassword = false,
      IconData? SuffixIcon,
      IconData? preIcon,
      Function(String)? onChanged,


}) {
  final bool isactive = IsPassword;
  isactive ? IsPassword = AppCubit.get(context).isPassword : null;

  return TextFormField(
    onChanged: onChanged,
  controller: controller,
  keyboardType:keyboardType,
  obscureText:IsPassword,
  decoration:InputDecoration(
      enabledBorder:OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300 ,width:1 ),
        borderRadius: BorderRadius.circular(7)// default border color
      ),
    border: OutlineInputBorder(),
    filled:true,
    fillColor: Colors.white,
    isDense: true,
    hintText:hintText,
    hintStyle: GoogleFonts.manrope(color: Colors.grey.shade500 ,fontWeight: FontWeight.w500  ,fontSize: 15),
    prefixIcon: preIcon==null?null:Icon(
      preIcon,color: Theme.of(context).primaryColor,
    ),
    suffixIcon:IsPassword?
    isactive ? IconButton(onPressed: () {AppCubit.get(context).Passon();}, icon: Icon(AppCubit.get(context).suffixIcon),) : IconButton(onPressed: () {}, icon: Icon(SuffixIcon),)
        :isactive ? IconButton(onPressed: () {AppCubit.get(context).Passon();}, icon: Icon(AppCubit.get(context).suffixIcon),) : IconButton(onPressed: () {}, icon: Icon(SuffixIcon),),
  ) ,
  );
}

Widget PostTextForm(
    context,{
      required TextEditingController controller,
      required TextInputType keyboardType,
      String? hintText,
      bool IsPassword = false,
      IconData? SuffixIcon,
      IconData? preIcon,


    }) {
  final bool isactive = IsPassword;
  isactive ? IsPassword = AppCubit.get(context).isPassword : null;

  return TextFormField(
    controller: controller,
    keyboardType:keyboardType,
    obscureText:IsPassword,
    maxLines: null,
    textAlignVertical: TextAlignVertical.top,
    decoration:InputDecoration(
      contentPadding:EdgeInsets.symmetric(horizontal: 10),
      border: InputBorder.none,
      filled:false,
      isDense:true,
      hintText:hintText,
      hintStyle: GoogleFonts.manrope(color: Colors.grey.shade500 ,fontWeight: FontWeight.w400  ,fontSize: 13),
      prefixIcon: preIcon==null?null:Icon(
        preIcon,color: Theme.of(context).primaryColor,
      ),

    ) ,
  );
}


String formatTimestampToAmPm(DateTime dt) {
  final local = dt.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final ampm = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $ampm';
}