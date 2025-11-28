// wellcomingPage.dart

import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:WhatsUnity/Confg/supabase.dart';
import 'package:WhatsUnity/Layout/Cubit/cubit.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:WhatsUnity/Layout/MainScreen.dart';
import '../Components/Constants.dart';


class JoinCommunity extends StatelessWidget {
  const JoinCommunity({super.key});


  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Join a Community"),
      ),
      body: categories.isEmpty
           ? const CircularProgressIndicator()
           : Column(
             children: [
               defaultTextForm(
                   context,
                   controller: controller,
                   keyboardType:TextInputType.text,
                   SuffixIcon: Icons.search,
                   onChanged:(s){AppCubit.get(context).getSuggestions(controller);}
               ),
               Expanded(
                 child: BlocConsumer<AppCubit,AppCubitStates>(
                   listener: (context , states) {
                     if(states is CompoundIdChange && UserData !=null){

                       Navigator.pushAndRemoveUntil(
                         context,
                         MaterialPageRoute(
                             builder: (context) => MainScreen()),
                             (Route<
                             dynamic> route) => false, // This predicate removes all previous routes
                       );
                     } else if(states is CompoundIdChange && UserData == null){
                       Navigator.pop(context);
                     }
                   },
                   builder: (context,states) {
                     return ListView.builder(
                             itemCount: controller.text.isEmpty?categories.length:AppCubit.get(context).compoundSuggestions.length,
                             itemBuilder: (context, index) {

                               final category = controller.text.isEmpty?categories[index]:AppCubit.get(context).compoundSuggestions[index];

                               return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display the category name as a title
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Divider(),

                          // Map the list of compounds to a list of ListTile widgets
                          ...category.compounds.reversed.map((compound) {
                            final assetPath = compoundsLogos.firstWhere((file) {
                              final fileName = file.split('/').last;          // "23.png"
                              final nameWithoutExt = fileName.split('.').first; // "23"
                              return nameWithoutExt == compound.id.toString();
                            },orElse: () =>'null');

                            return ListTile(
                              tileColor:Colors.white38,
                              minTileHeight:70,
                              onTap:()=>context.read<AppCubit>().selectCompound(compound: compound,atWelcome: true),
                              leading: ClipRRect(
                                borderRadius:BorderRadius.circular(10),
                                child: compound.pictureUrl != null ?
                                Image.network(
                                  compound.pictureUrl.toString(),
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context,exception,stackTrace){
                                    return SizedBox.shrink();
                                  },
                                ) : assetPath != 'null'?Image.asset(assetPath , width: 80,
                                  fit: BoxFit.cover,):SizedBox.shrink(),
                              ),
                              subtitle: Text(compound.developer!),
                              title: Text(compound.name),
                              // You can add more details here if needed
                              // subtitle: Text(compound.location ?? ''),
                            );
                          }).toList(),
                        ],
                      ),
                               );
                             },
                           );
                   }
                 ),
               ),
             ],
           ),
    );

  }
}

