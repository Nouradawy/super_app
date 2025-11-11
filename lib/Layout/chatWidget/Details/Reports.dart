import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/Layout/Cubit/ReportCubit/cubit.dart';
import 'package:super_app/Layout/Cubit/ReportCubit/states.dart';

class Reports extends StatelessWidget {
  const Reports({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = ReportCubit.get(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Reports"),
      ),
      body: BlocBuilder<ReportCubit,ReportCubitState>(
        builder: (context , states) {
          return Column(
            children: [
              Wrap(
                spacing: 8,
                children: List.generate(ReportsFilters.values.length, (i){
                  return FilterChip(
                      label: Text(i==2?'In Review':ReportsFilters.values[i].name),
                      selected: cubit.index == i,
                      onSelected: (selected) {

                      });
                }),
              ),
              const SizedBox(height: 12,),
              Expanded(child: cubit.reportsList()),

            ],
          );
        }
      )
    );
  }
}
