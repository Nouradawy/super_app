
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';

import '../../../../Layout/Cubit/cubit.dart';
import '../../../../Layout/Cubit/states.dart';
import '../../../../core/config/Enums.dart';
import '../../../../core/config/supabase.dart';
import '../../../admin/presentation/pages/AdminDashboard/AdminDashboard.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/gatekeeper_user_page.dart';
import '../../../chat/presentation/pages/building_chat_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';


class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {


    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<AppCubit, AppCubitStates>(
          builder: (context, states) {
            final cubit = AppCubit.get(context);
            final Roles? role = (authState is Authenticated) ? authState.role : null;
            final List screens = [
              GatekeeperScreen(index: role == Roles.manager ? 0 : 1,),
              if (role != Roles.manager) BuildingChat(),
              ProfilePage(),
              if (role == Roles.admin) AdminDashboard(),
            ];

            return Scaffold(
              resizeToAvoidBottomInset: false,
              bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: cubit.bottomNavIndex,
                  onTap: (index) => cubit.bottomNavIndexChange(index),
                  items: <BottomNavigationBarItem>[

                    BottomNavigationBarItem(
                        icon: FaIcon(FontAwesomeIcons.house, size: 18),
                        label: "Home"
                    ),
                    if (role != Roles.manager)
                      BottomNavigationBarItem(
                          icon: FaIcon(FontAwesomeIcons.solidMessage, size: 18),
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
                            , size: 19),
                        label: "Profile"
                    ),
                    if (role == Roles.admin)
                      BottomNavigationBarItem(
                          icon: FaIcon(FontAwesomeIcons.userTie
                              , size: 19),
                          label: "Admin dashboard"
                      ),
                  ]),
              body: IndexedStack(
                index: cubit.bottomNavIndex,
                children: List<Widget>.from(screens),
              ),
            );
          }
        );
      }
    );
  }
}
