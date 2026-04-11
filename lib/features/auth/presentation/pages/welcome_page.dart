import 'package:condition_builder/condition_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../core/config/supabase.dart';
import '../../../../core/constants/Constants.dart';
import '../../../home/presentation/pages/main_screen.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class JoinCommunity extends StatelessWidget {
  final bool atWelcome;
  const JoinCommunity({
    super.key,
    this.atWelcome = false,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return Scaffold(
        appBar: AppBar(
          title: const Text("Join a Community"),
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final cubit = context.read<AuthCubit>();
            final categories = state.categories;
            final compoundsLogos = state.compoundsLogos;

            if (categories.isEmpty) {
              cubit.loadCompounds();
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                defaultTextForm(context,
                    controller: controller,
                    keyboardType: TextInputType.text,
                    SuffixIcon: Icons.search,
                    onChanged: (s) {
                  cubit.getSuggestions(controller);
                }),
                Expanded(
                  child: BlocConsumer<AuthCubit, AuthState>(
                      listener: (context, states) {
                    if (states is CompoundSelected && atWelcome == false) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                        (Route<dynamic> route) =>
                            false, // This predicate removes all previous routes
                      );
                    } else if (states is CompoundSelected && atWelcome == true) {
                      Navigator.pop(context);
                    }
                  }, builder: (context, states) {
                    final currentCategories = states.categories;
                    final currentLogos = states.compoundsLogos;
                    
                    return ListView.builder(
                      itemCount: controller.text.isEmpty
                          ? currentCategories.length
                          : cubit.compoundSuggestions.length,
                      itemBuilder: (context, index) {
                        final category = controller.text.isEmpty
                            ? currentCategories[index]
                            : cubit.compoundSuggestions[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
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
                                final assetPath =
                                    currentLogos.firstWhere((file) {
                                  final fileName = file.split('/').last; // "23.png"
                                  final nameWithoutExt =
                                      fileName.split('.').first; // "23"
                                  return nameWithoutExt ==
                                      compound.id.toString();
                                }, orElse: () => 'null');

                                return ListTile(
                                  tileColor: Colors.white38,
                                  minTileHeight: 70,
                                  onTap: () => context
                                      .read<AuthCubit>()
                                      .selectCompound(
                                          compoundId: compound.id,
                                          compoundName: compound.name,
                                          atWelcome: atWelcome),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: compound.pictureUrl != null
                                        ? Image.network(
                                            compound.pictureUrl.toString(),
                                            width: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, exception, stackTrace) {
                                              return const SizedBox.shrink();
                                            },
                                          )
                                        : assetPath != 'null'
                                            ? Image.asset(
                                                assetPath,
                                                width: 80,
                                                fit: BoxFit.cover,
                                              )
                                            : const SizedBox.shrink(),
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
                  }),
                ),
              ],
            );
          },
        ));
  }
}
