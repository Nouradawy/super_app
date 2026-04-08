import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/bloc/auth_cubit.dart';
import '../../../core/config/Enums.dart';
import '../../../core/config/supabase.dart';
import '../../../core/constants/Constants.dart';
import '../../../core/services/PresenceManager.dart';
import '../../home/presentation/pages/main_screen.dart';

class AuthReadyGate extends StatefulWidget {
  const AuthReadyGate({super.key});

  @override
  State<AuthReadyGate> createState() => _AuthReadyGateState();
}

class _AuthReadyGateState extends State<AuthReadyGate> {
  late Future<void> _initFuture;

  Future<void> _init() async {
    final authCubit = context.read<AuthCubit>();
    await authCubit.presetBeforeSignin();
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