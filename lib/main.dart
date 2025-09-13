import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/HomePage.dart';
import 'package:super_app/Layout/Maintenance.dart';

import 'Confg/supabase.dart';
import 'Layout/GeneralChat.dart';
import 'Layout/Profile.dart';
import 'Layout/SignUp.dart';
import 'Layout/wellcomingPage.dart';



void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    // ⚠️ IMPORTANT: Replace with your own URL and Anon Key
    url: 'https://ckwdavrschtisigmxwmy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrd2RhdnJzY2h0aXNpZ214d215Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzIxMDQsImV4cCI6MjA2ODg0ODEwNH0.RYmu2jeNU-0yTbtVpBWMni1eUeQUksdbdpFrBBrEAx4',
  );



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
        home: JoinCommunity(),
      ),
    );
  }
}

