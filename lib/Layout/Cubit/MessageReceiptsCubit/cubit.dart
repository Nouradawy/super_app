import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:WhatsUnity/Layout/Cubit/MessageReceiptsCubit/states.dart';

import '../../../Confg/Enums.dart';
import '../../../Confg/supabase.dart';
import '../../chatWidget/Details/ChatMember.dart';

class SeenUser {
  final ChatMember member;
  final DateTime seenAt;
  SeenUser({required this.member, required this.seenAt});
}

class MessageReceiptsCubit extends Cubit<MessageReceiptsState> {
  final SupabaseClient client;
  MessageReceiptsCubit(this.client) : super(MessageReceiptsInitial());

  Future<void> fetchSeenUsers(String messageId) async {
    emit(MessageReceiptsLoading());
    try {
      final rows = await client
          .from('message_receipts')
          .select('user_id, seen_at')
          .eq('message_id', messageId)
          .not('seen_at', 'is', null);

      final List<dynamic> list = rows is List ? rows : [];
      final List<SeenUser> mapped = [];
      for (final r in list) {
        final uid = (r['user_id'] as String?)?.trim();
        if (uid == null) continue;
        final cm = ChatMembers.firstWhere(
              (m) => m.id.trim() == uid,
          orElse: () => ChatMember(id: uid, displayName: 'Unknown', building: '', apartment: '', userState: UserState.banned, phoneNumber: '', ownerType: null),
        );
        final rawSeen = r['seen_at'];
        DateTime? seenAt;
        if (rawSeen is String) {
          seenAt = DateTime.tryParse(rawSeen)?.toLocal();
        } else if (rawSeen is DateTime) {
          seenAt = rawSeen.toLocal();
        }
        if (seenAt != null) {
          mapped.add(SeenUser(member: cm, seenAt: seenAt));
        }
      }
      // Sort newest first
      mapped.sort((a, b) => b.seenAt.compareTo(a.seenAt));
      emit(MessageReceiptsLoaded(mapped));
    } catch (e) {
      emit(MessageReceiptsError(e.toString()));
    }
  }
}