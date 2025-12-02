import 'package:WhatsUnity/Layout/Cubit/AdminDashboard/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Confg/Enums.dart';
import '../Cubit/AdminDashboard/cubit.dart';


class Users{
  final String authorId;
  final String phoneNumber;
  final DateTime updatedAt;
  final String ownerShipType;
  final String userState;
  final String actionTakenBy;
  final List<Map<String, dynamic>> verFile;

  Users({
    required this.authorId,
    required this.phoneNumber,
    required this.updatedAt,
    required this.ownerShipType,
    required this.userState,
    required this.actionTakenBy,
    required this.verFile,
  });

  factory Users.fromJson(Map<String,dynamic> json){
    return Users(
      authorId: json['id'],
      phoneNumber: json['phone_number'],
      updatedAt: DateTime.tryParse(json['updated_at'])!,
      ownerShipType: json['owner_type'],
      userState: json['userState'],
      actionTakenBy: json['actionTakenBy'],
        verFile: json['verFiles']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': authorId.trim(),
      'phone_number' : phoneNumber,
      'updated_at': updatedAt.toIso8601String(),
      'owner_type': ownerShipType,
      'userState' : userState,
      'actionTakenBy' : actionTakenBy,
      'verFiles' : verFile

    };
  }


}



class MembersManagement extends StatelessWidget {
  const MembersManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = AdminCubit.get(context);
    return Scaffold(

        body: BlocBuilder<AdminCubit,AdminCubitStates>(
            builder: (context , states) {

              return Column(
                children: [
                  Wrap(
                    spacing: 8,
                    children: List.generate(UserState.values.length, (i){
                      return FilterChip(
                          label: Text(UserState.values[i].name),
                          selected: cubit.filterIndex == i,
                          onSelected: (selected) {
                            cubit.filterIndex = i;
                            cubit.filterRequests(UserState.values[i]);

                          });
                    }),
                  ),
                  const SizedBox(height: 12,),
                  Expanded(child: cubit.usersList()),

                ],
              );
            }
        )
    );
  }
}
