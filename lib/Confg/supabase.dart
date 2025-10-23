import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/CompoundsList.dart';
// ignore: non_constant_identifier_names
User? UserData;
// ignore: non_constant_identifier_names
String Userid =  UserData!.id;
late final SupabaseClient supabase;
List<Category> categories=[];
enum Roles {user,manager}

class SupabaseArgs {
  final String url;
  final String anonKey;

  SupabaseArgs({
    required this.url,
    required this.anonKey,

  });
}

Future<List<Category>> fetchCompounds (SupabaseArgs args) async  {

  debugPrint('Background isolate started fetching data for Categories...');
  final supabase = SupabaseClient(args.url, args.anonKey);

  final response = await supabase
      .from('compound_categories')
      .select('*, compounds(*)'); // MAGIC!

  // Supabase returns a List<dynamic> where each element is a Map (a category)
  // We parse this raw data into our clean Dart models
  final data = (response as List)
      .map((categoryJson) => Category.fromJson(categoryJson))
      .toList();
  debugPrint('Background isolate finished.');
  return data;
}

