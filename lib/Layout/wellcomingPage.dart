// wellcomingPage.dart

import 'package:flutter/material.dart';
import '../Components/CompoundsList.dart';
import 'Cubit/cubit.dart';

class JoinCommunity extends StatelessWidget {
  const JoinCommunity({super.key});

  @override
  Widget build(BuildContext context) {

    List StaticComp;

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
              StaticComp = AppCubit.get(context).fetchCompounds();
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
                    ...category.compounds.map((compound) {
                      return ListTile(
                        leading: const Icon(Icons.location_city),
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