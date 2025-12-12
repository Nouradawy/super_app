
import 'package:WhatsUnity/Layout/Gatekeeper_user.dart';
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
import 'ManagerHomePage.dart';
import 'Profile.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {


    return BlocBuilder<AppCubit,AppCubitStates>(
      builder: (context,states) {
        final cubit = AppCubit.get(context);
        final Roles? role = cubit.currentUserRole ?? userRole;
        final List screens=[
          GatekeeperScreen(index: role == Roles.manager?0:1,),
          if(role != Roles.manager) BuildingChat(),
          Profile(),
          if (role == Roles.admin) AdminDashboard(),
        ];
        return Scaffold(
          bottomNavigationBar: BottomNavigationBar(
              type:BottomNavigationBarType.fixed,
              currentIndex: cubit.bottomNavIndex,
              onTap: (index)=>cubit.bottomNavIndexChange(index),
              items: <BottomNavigationBarItem>[

                BottomNavigationBarItem(
                    icon: FaIcon(FontAwesomeIcons.house,size: 18),
                    label: "Home"
                ),
                if(role != Roles.manager)
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
                if(role == Roles.admin)
                  BottomNavigationBarItem(
                      icon: FaIcon(FontAwesomeIcons.userTie
                          ,size: 19),
                      label: "Admin dashboard"
                  ),
              ]),
          body: screens[cubit.bottomNavIndex],
        );
      }
    );
  }
}
