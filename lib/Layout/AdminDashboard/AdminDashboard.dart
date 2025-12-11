import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:WhatsUnity/Components/Constants.dart';
import 'package:WhatsUnity/Layout/Cubit/AdminDashboard/cubit.dart';
import 'package:WhatsUnity/Layout/Cubit/AdminDashboard/states.dart';

import '../../Confg/Enums.dart';
import '../Cubit/ReportCubit/cubit.dart';
import '../chatWidget/Details/ChatMember.dart';
import '../chatWidget/Details/Reports.dart';
import 'MembersManagement.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final List account = ["User Management","Verifications Requests" , "User Reports"];
    final cubit = AdminCubit.get(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
      ),
      body: BlocBuilder<AdminCubit,AdminCubitStates>(
        builder: (context,states) {
          return Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemBuilder: (context,index) {
                  return MaterialButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      context.read<AdminCubit>().indexChange(index);
                      ReportCubit.get(context).getReportList();
                      cubit.filterRequests(UserState.New);
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(account[index],style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400 ,fontSize: 15),textAlign: TextAlign.center,),
                              Icon(Icons.arrow_forward_ios,size: 20,color: Colors.grey.shade500,)
                            ],
                          ),
                        ),
                        if(index < account.length-1 )Divider(height: 1,color: Colors.grey.shade200,),
                      ],
                    ),
                  );
                },  itemCount: account.length,
              ),
             if(cubit.index ==0) ...[
               Expanded(
                 child: ChatMembersScreen(
                   compoundId: selectedCompoundId!,
                 ),
               ),
             ],
              if(cubit.index ==1) ...[
                Expanded(
                  child: MembersManagement(),
                ),
              ],
              if(cubit.index ==2) ...[
                Expanded(
                  child: Reports(),
                ),
              ]
            ],
          );
        }
      ),
    );
  }
}
