// wellcomingPage.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import '../Components/Constants.dart';
import '../Model/CompoundsList.dart';
import '../Network/CacheHelper.dart';
import 'Cubit/cubit.dart';
import 'HomePage.dart';

class JoinCommunity extends StatelessWidget {
  const JoinCommunity({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Join a Community"),
      ),
      body: FutureBuilder<List<Category>>(
        future: AppCubit.get(context).fetchCompounds(),
        builder: (context, snapshot) {
          // 1. Handle the LOADING state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Handle any ERRORS
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 3. Handle the case where there is NO DATA
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No communities found.'));
          }

          // 4. If we reach here, we have data! It's now safe to use !
          final categories = snapshot.data!;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {

              final category = categories[index];

              // IMPORTANT: The itemBuilder MUST return a widget.
              // Here, we return a Column for each category.
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
                      return ListTile(
                        tileColor:Colors.white38,
                        minTileHeight:70,
                        onTap:() async {
                          MyCompounds.addAll({compound.id.toString(): compound.name.toString()});

                          await CacheHelper.saveData(key: "MyCompounds", value: json.encode(MyCompounds));

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                                (Route<dynamic> route) => false, // This predicate removes all previous routes
                          );
                          selectedCompoundId = compound.id;
                        },
                        leading: ClipRRect(
                          borderRadius:BorderRadius.circular(10),
                          child: Image.network(
                              compound.pictureUrl.toString(),
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context,exception,stackTrace){
                                return SizedBox.shrink();
                            },
                          ),
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
        },
      ),
    );
  }
}