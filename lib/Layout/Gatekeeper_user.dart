import 'package:WhatsUnity/Confg/Enums.dart';
import 'package:WhatsUnity/Confg/supabase.dart';
import 'package:WhatsUnity/Layout/Cubit/cubit.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:condition_builder/condition_builder.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'HomePage.dart';
import 'ManagerHomePage.dart';

class GatekeeperScreen extends StatelessWidget {
  final int index;
  const GatekeeperScreen({super.key , required this.index});


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppCubitStates>(
      builder: (context, state) {
        return ConditionBuilder<dynamic>.on(
              () => currentUser?.userState == UserState.New,
              () => Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.blue,
                        size: 100,
                      ),
                      SizedBox(height: 60),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.8,
                        child: Text(
                          "Your account has been created successfully. We are waiting for an administrator to pick up your request.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .on(
              () => currentUser?.userState == UserState.underReview,
              () => Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.find_in_page_outlined,
                        color: Colors.orange,
                        size: 100,
                      ),
                      SizedBox(height: 60),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.8,
                        child: Text(
                          "An admin is currently reviewing your documents to verify your residency. This usually takes 1-3 hours.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .on(
              () => currentUser?.userState == UserState.unApproved,
              () => Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rule, color: Colors.redAccent, size: 100),
                      SizedBox(height: 60),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.8,
                        child: Text(
                          "We couldn't verify your account based on the information provided. Please update your profile details and try again.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .on(
              () => currentUser?.userState == UserState.onConflict,
              () => Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.report_problem,
                        color: Colors.amber[700],
                        size: 100,
                      ),
                      SizedBox(height: 60),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.8,
                        child: Text(
                          "The Unit ID you selected is already claimed by another user. administrator will currently investigate this and will contact you soon.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .build(orElse: () {
              if(index == 1) {
                return HomePage();
              }
              if(index == 0){
                return ManagerHomepage();
              }
            });
      },
    );
  }
}
