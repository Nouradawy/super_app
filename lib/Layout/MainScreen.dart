import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/HomePage.dart';

import 'BuildingChat.dart';
import 'Cubit/cubit.dart';
import 'Profile.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List screens=[
      HomePage(),
      BuildingChat(),
      Profile(),
    ];

    return BlocBuilder<AppCubit,AppCubitStates>(
      builder: (context,states) {
        return Scaffold(
          bottomNavigationBar: BottomNavigationBar(
              type:BottomNavigationBarType.fixed,
              currentIndex: AppCubit.get(context).bottomNavIndex,
              onTap: (index)=>AppCubit.get(context).bottomNavIndexChange(index),
              items: [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: "Home"
                ),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat_outlined),
                    label: "Chats"
                ),
                // BottomNavigationBarItem(
                //     icon: Icon(Icons.handyman_outlined),
                //     label: "Services"
                // ),
                // BottomNavigationBarItem(
                //     icon: Icon(Icons.announcement_outlined),
                //     label: "announcements"
                // ),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: "Profile"
                )
              ]),
          body: screens[AppCubit.get(context).bottomNavIndex],
        );
      }
    );
  }
}
