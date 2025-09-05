import 'package:flutter/material.dart';

class JoinCommunity extends StatelessWidget {
  const JoinCommunity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Join a Community"),
      ),
      body: ListView.builder(
          itemBuilder: (context,index){
            return ListTile(
              leading: Text(""),
            );
          }
      ),
    );
  }
}
