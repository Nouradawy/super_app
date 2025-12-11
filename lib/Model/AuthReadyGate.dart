import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Components/Constants.dart';
import '../Confg/Enums.dart';
import '../Confg/supabase.dart';
import '../Layout/Cubit/ManagerCubit/cubit.dart';
import '../Layout/Cubit/cubit.dart';
import '../Layout/MainScreen.dart';
import '../Network/CacheHelper.dart';
import '../Services/PresenceManager.dart';

class AuthReadyGate extends StatefulWidget {
  const AuthReadyGate({super.key});

  @override
  State<AuthReadyGate> createState() => _AuthReadyGateState();
}

class _AuthReadyGateState extends State<AuthReadyGate> {
  late Future<void> _initFuture;

  Future<void> _init() async {
    final cubit = AppCubit.get(context);

    // 1\) Load compounds if not loaded
    if (categories.isEmpty) {
      await cubit.loadCompounds();
    }
    if(selectedCompoundId ==null ){

      final compoundId =await supabase.from('user_apartments').select('compound_id').eq('user_id', Userid).single();
      selectedCompoundId =compoundId['compound_id'];
    }

    debugPrint('Compoundid returned : $selectedCompoundId');
    debugPrint('MyCompounds : ${MyCompounds.length}');
    if(MyCompounds.length ==1){
      final compound = categories.expand((cat) => cat.compounds).firstWhere((compound)=>compound.id == selectedCompoundId);
      debugPrint('Compoundid returned : ${compound.name}');
      MyCompounds = {
        '0': "Add New Community",
        selectedCompoundId.toString(): compound.name.toString()
      };
    }

    userRole = Roles.values[UserData?.userMetadata?["role_id"]-1];
    debugPrint("Logedin as :${userRole?.name}");
      // 3\) Load members, posts, etc.
    await cubit.loadCompoundMembers(selectedCompoundId!);
    if(userRole != Roles.manager) {
      cubit.getPostsData(selectedCompoundId);
    }


    requestPermission();
  }

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PresenceManager(child: MainScreen());
      },
    );
  }
}