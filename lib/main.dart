
import 'dart:async';
import 'package:WhatsUnity/Layout/Cubit/ManagerCubit/cubit.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Components/BlocObserver.dart';
import 'Components/Constants.dart';
import 'Confg/Enums.dart';
import 'Confg/supabase.dart';
import 'Layout/Cubit/AdminDashboard/cubit.dart';
import 'Layout/Cubit/ChatDetailsCubit/cubit.dart';
import 'Layout/Cubit/ReportCubit/cubit.dart';
import 'Layout/Cubit/cubit.dart';
import 'Layout/SignUp.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Model/AuthReadyGate.dart';
import 'Network/CacheHelper.dart';
import 'Themes/lightTheme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();


  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final mq = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first,);
    final capped = mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1),);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create:(context) => AppCubit()..loadCompounds(),),
        BlocProvider(create: (context)=> ReportCubit()),
        BlocProvider(create: (context)=> AdminCubit()),
        BlocProvider(create: (context)=> ManagerCubit()),
        BlocProvider(create: (context)=> ChatDetailsCubit()),
      ],
      child: ChangeNotifierProvider(
        create: (_) => AuthManager(),
        child: LayoutBuilder(

          builder: (BuildContext context, BoxConstraints constraints) {
            return MediaQuery(
              data: capped,
              child: MaterialApp(
                title: 'Flutter Demo',
                debugShowCheckedModeBanner:false,
                debugShowMaterialGrid: false,
                theme: myLightTheme(),
                supportedLocales: L10n.all,
                localeResolutionCallback: (deviceLocale, supportedLocales) {
                  // Return device locale if supported, else fallback to first supported
                  if (deviceLocale != null &&
                      supportedLocales.any((l) => l.languageCode == deviceLocale.languageCode)) {
                    return deviceLocale;
                  }
                  return supportedLocales.first;
                },
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
                 Builder(
                   builder: (context) {
                     final auth = context.watch<AuthManager>();
                     if (auth.status == AuthStatus.unknown) {
                       return const Scaffold(
                         body: Center(child: CircularProgressIndicator()),
                       );
                     }
                     if (auth.status == AuthStatus.authenticated &&
                         AppCubit.get(context).signupGoogleEmail == null &&
                         AppCubit.get(context).signInGoogle == false) {
                       return const AuthReadyGate();
                     }
                     requestPermission();
                     return SignUp();
                   },
                 ),
              ),
            );
          }
        ),
      ),
    );
  }
}

class AuthManager extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  StreamSubscription<AuthState>? _sub;

  AuthManager() {
    _sub = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null) {
            UserData = session.user;
            status = AuthStatus.authenticated;
            notifyListeners();
          }
          break;
        case AuthChangeEvent.signedOut:
          UserData = null;
          status = AuthStatus.unauthenticated;
          notifyListeners();
          break;
        case AuthChangeEvent.tokenRefreshed:
        // Silent: keep user authenticated, just refresh UserData
          if (session != null) {
            UserData = session.user;
            if (status != AuthStatus.authenticated) {
              status = AuthStatus.authenticated;
              notifyListeners();
            }
          }
          break;
        default:
          break;
      }
    });

    // initial status from current session
    final current = supabase.auth.currentSession;
    if (current != null) {
      UserData = current.user;
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
