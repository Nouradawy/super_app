
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
enum MaintenanceCategory {plumbing,electricity,plastering,gardening}

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

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // IMPORTANT: You must re-initialize Supabase in the background isolate
//   await Supabase.initialize(
//     url: 'https://nouradawysupabase.duckdns.org',
//     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQwOTk1MjAwLCJleHAiOjE5NTY1NTY4MDB9.EOD6RIRAhlJkyIRu92VOWxuCh9E5eJ_DCRWXvAO7YyA',
//   );
//
//   final supabase = Supabase.instance.client;
//
//   // Extract the message ID from the 'data' payload
//   final String? messageId = message.data['message_id'];
//
//   if (messageId != null && supabase.auth.currentUser != null) {
//     debugPrint('Background notification received for message: $messageId. Confirming delivery...');
//     try {
//       // Invoke the Edge Function to mark the message as delivered
//       await supabase.rpc('mark_message_delivered', params: {
//         'p_message_id': messageId,
//       });
//       debugPrint('Delivery confirmed successfully.');
//     } catch (e) {
//       debugPrint('Error confirming delivery: $e');
//     }
//   }
// }
//
// Future<void> getFireBaseToken () async {
//   final notificationSettings = await FirebaseMessaging.instance.requestPermission(provisional: true);
//   // final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
//   final fcmToken = await FirebaseMessaging.instance.getToken();
//   if(fcmToken != null){
//     await supabase.from('profiles').upsert({
//       'id' : Userid,
//       'FCM_Token':fcmToken
//     });
//   }
//
// }