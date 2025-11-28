
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:WhatsUnity/Layout/HomePage.dart';

import '../Confg/Enums.dart';
import '../Confg/supabase.dart';
import 'AdminDashboard/AdminDashboard.dart';
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
      AdminDashboard(),
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
                    icon: FaIcon(FontAwesomeIcons.house,size: 18),
                    label: "Home"
                ),
                BottomNavigationBarItem(
                    icon: FaIcon(FontAwesomeIcons.solidMessage,size: 18),
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
                    icon: FaIcon(FontAwesomeIcons.userLarge
                        ,size: 19),
                    label: "Profile"
                ),
                if(userRole == Roles.admin)
                  BottomNavigationBarItem(
                      icon: FaIcon(FontAwesomeIcons.userTie
                          ,size: 19),
                      label: "Admin dashboard"
                  ),
              ]),
          body: screens[AppCubit.get(context).bottomNavIndex],
        );
      }
    );
  }
}
