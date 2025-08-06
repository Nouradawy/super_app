import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';

import '../sevices/GoogleDriveService.dart';

final GoogleDriveService driveService = GoogleDriveService();
GoogleSignInAccount? googleUser;



Widget defaultTextForm(
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


String formatTimestampToAmPm(String timestamp) {
  DateTime dateTime = DateTime.parse(timestamp).toLocal(); // Convert Firestore Timestamp to DateTime
  String formattedTime = DateFormat('h:mm a').format(dateTime); // e.g., "2:30 PM"
  return formattedTime;
}