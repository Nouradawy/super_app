import 'package:flutter/material.dart';

import 'Cubit/cubit.dart';

class JoinCommunity extends StatelessWidget {
  const JoinCommunity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Join a Community"),
      ),
      body: MaterialButton(onPressed:(){
        AppCubit.get(context).fetchCompounds();
      },
      child:Text("Click here"))
    );
  }
}
