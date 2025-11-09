import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:super_app/Components/Constants.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/HomePage.dart';
import 'package:super_app/Network/CacheHelper.dart';

import 'package:super_app/Themes/lightTheme.dart';

import 'Components/BlocObserver.dart';
import 'Confg/supabase.dart';
import 'Layout/SignUp.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'OTPScreen.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const SimpleBlocObserver();
  // await Firebase.initializeApp();
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Supabase.initialize(
    // ⚠️ IMPORTANT: Replace with your own URL and Anon Key
    url: 'https://nouradawysupabase.duckdns.org',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQwOTk1MjAwLCJleHAiOjE5NTY1NTY4MDB9.EOD6RIRAhlJkyIRu92VOWxuCh9E5eJ_DCRWXvAO7YyA',
  );
  supabase = Supabase.instance.client;
  await CacheHelper.init();

  String?Compounds = await CacheHelper.getData(key: "MyCompounds", type: "String");
  if (Compounds != null) {
    MyCompounds = json.decode(Compounds);
  }
  int? CompoundIndex = await CacheHelper.getData(key: "compoundCurrentIndex", type: "int");
  if(CompoundIndex != null){
    selectedCompoundId = CompoundIndex;
    debugPrint(selectedCompoundId.toString());
  }

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:(context) => AppCubit()..loadCompounds(),
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner:false,
        debugShowMaterialGrid: false,
        theme: myLightTheme(),
        supportedLocales: L10n.all,
        locale:const Locale('en'),
        localizationsDelegates:const[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ] ,
         home:
         StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            // 1. While waiting for the first auth event, you can show a loading screen
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 2. Once data is received, check if there is a session
            if (snapshot.hasData && snapshot.data!.session != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // safe to call cubit and other side-effects now
                context.read<AppCubit>().getPostsData(selectedCompoundId);
                context.read<AppCubit>().loadCompoundMembers(selectedCompoundId!);
                UserData = snapshot.data!.session!.user;
                requestPermission();
              });
              return  HomePage();
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                requestPermission();
              });
              // User is not logged in, show the SignUp page
              return  SignUp();
            }
          },
        ),
      ),
    );
  }
}

