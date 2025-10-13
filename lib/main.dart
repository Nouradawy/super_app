import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_app/Components/Constants.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/HomePage.dart';
import 'package:super_app/Layout/Maintenance.dart';
import 'package:super_app/Network/CacheHelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Components/BlocObserver.dart';
import 'Confg/supabase.dart';
import 'Layout/GeneralChat.dart';
import 'Layout/Profile.dart';
import 'Layout/SignUp.dart';
import 'Layout/wellcomingPage.dart';



void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const SimpleBlocObserver();
  await Supabase.initialize(
    // ⚠️ IMPORTANT: Replace with your own URL and Anon Key
    url: 'https://nouradawysupabase.duckdns.org',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQwOTk1MjAwLCJleHAiOjE5NTY1NTY4MDB9.EOD6RIRAhlJkyIRu92VOWxuCh9E5eJ_DCRWXvAO7YyA',
  );
  await CacheHelper.init();
  String?Compounds = await CacheHelper.getData(key: "MyCompounds", type: "String");
  if (Compounds != null) {
    MyCompounds = json.decode(Compounds);
  }
  int? CompoundIndex = await CacheHelper.getData(key: "compoundCurrentIndex", type: "int");
  if(CompoundIndex != null){
    selectedCompoundId = CompoundIndex;
    print(selectedCompoundId);
  }

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:(context) => AppCubit()..getPostsData(selectedCompoundId),
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner:false,
        debugShowMaterialGrid: false,
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a purple toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "ho
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: StreamBuilder<AuthState>(
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
              // User is logged in, show the HomePage
              UserData = snapshot.data!.session!.user; // You can set your global UserData here
              requestPermision();
              return  HomePage();
            } else {
              requestPermision();
              // User is not logged in, show the SignUp page
              return  SignUp();
            }
          },
        ),
      ),
    );
  }
}

Future<void> requestPermision() async {
  if(await Permission.microphone.status.isDenied || await Permission.storage.status.isDenied)
  {
    await [
      Permission.microphone,
      Permission.storage
    ].request();
  }
}