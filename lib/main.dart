import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'Components/BlocObserver.dart';
import 'Components/Constants.dart';
import 'Confg/supabase.dart';
import 'Layout/Cubit/AdminDashboard/cubit.dart';
import 'Layout/Cubit/ReportCubit/cubit.dart';
import 'Layout/Cubit/cubit.dart';
import 'Layout/MainScreen.dart';
import 'Layout/SignUp.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Model/AuthReadyGate.dart';
import 'Network/CacheHelper.dart';
import 'Services/PresenceManager.dart';
import 'Themes/lightTheme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const SimpleBlocObserver();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    // ⚠️ IMPORTANT: Replace with your own URL and Anon Key
    url: 'https://nouradawysupabase.duckdns.org',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQwOTk1MjAwLCJleHAiOjE5NTY1NTY4MDB9.EOD6RIRAhlJkyIRu92VOWxuCh9E5eJ_DCRWXvAO7YyA',
  );
  supabase = Supabase.instance.client;
  await CacheHelper.init();

  await loadCachedData();

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create:(context) => AppCubit()..loadCompounds(),),
        BlocProvider(create: (context)=> ReportCubit()),
        BlocProvider(create: (context)=> AdminCubit()),
      ],
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
         builder: (context, child) {
           return Directionality(
             textDirection: TextDirection.ltr,
             child: child ?? const SizedBox.shrink(),
           );
         },
         home:
         StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            // 2. Once data is received, check if there is a session
            if (snapshot.hasData && snapshot.data!.session != null && AppCubit.get(context).signupGoogleEmail == null && AppCubit.get(context).signInGoogle ==false ) {
              UserData = snapshot.data!.session!.user;
              return AuthReadyGate();
            } else {

              requestPermission();
              // User is not logged in, show the SignUp page
              return  SignUp();
            }
          },
        ),
      ),
    );
  }
}

