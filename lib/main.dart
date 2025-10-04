import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_app/Components/Constants.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/HomePage.dart';
import 'package:super_app/Layout/Maintenance.dart';
import 'package:super_app/Network/CacheHelper.dart';

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
    url: 'http://192.168.100.53:8000',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
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

Session? session = Supabase.instance.client.auth.currentSession;


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    UserData = session?.user;
    return BlocProvider(
      create:(context) => AppCubit(),
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
          // and then invoke "hot reload" (save your changes or press the "hot
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
        home: session == null ? SignUp():HomePage(),
      ),
    );
  }
}

