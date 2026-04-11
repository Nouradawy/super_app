import 'package:WhatsUnity/Layout/Cubit/cubit.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:condition_builder/condition_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/Enums.dart';
import '../../../../core/config/supabase.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../home/presentation/pages/manager_home_page.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class GatekeeperScreen extends StatelessWidget {
  final int index;
  const GatekeeperScreen({super.key , required this.index});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser = (authState is Authenticated) ? authState.currentUser : null;

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
                          const Icon(
                            Icons.hourglass_empty,
                            color: Colors.blue,
                            size: 100,
                          ),
                          const SizedBox(height: 60),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.8,
                            child: const Text(
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
                          const Icon(
                            Icons.find_in_page_outlined,
                            color: Colors.orange,
                            size: 100,
                          ),
                          const SizedBox(height: 60),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.8,
                            child: const Text(
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
                          const Icon(Icons.rule, color: Colors.redAccent, size: 100),
                          const SizedBox(height: 60),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.8,
                            child: const Text(
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
                          const SizedBox(height: 60),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.8,
                            child: const Text(
                              "The Unit ID you selected is already claimed by another user. administrator will currently investigate this and will contact you soon.",
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).on(
                () => currentUser?.userState == UserState.banned,
                () => Scaffold(
                  appBar: AppBar(),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.no_accounts,
                          color: Colors.redAccent,
                          size: 100,
                        ),
                        const SizedBox(height: 60),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.8,
                          child: const Text(
                            "Your account has been banned . For breaking Community Rules.",
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
                    return const HomePage();
                  }
                  if(index == 0){
                    return const ManagerHomepage();
                  }
                  return const Scaffold(body: Center(child: Text("Unknown State")));
                });
          },
        );
      },
    );
  }
}
