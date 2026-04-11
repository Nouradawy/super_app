import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_auth show AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/utils/BlocObserver.dart';
import 'core/constants/Constants.dart';
import 'core/config/Enums.dart';
import 'core/config/supabase.dart';
import 'core/theme/lightTheme.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/usecases/delete_message.dart';
import 'features/chat/domain/usecases/fetch_messages.dart';
import 'features/chat/domain/usecases/mark_message_seen.dart';
import 'features/chat/domain/usecases/resolve_user.dart';
import 'features/chat/domain/usecases/send_file_message.dart';
import 'features/chat/domain/usecases/send_voice_note.dart';
import 'features/chat/domain/usecases/send_text_message.dart';
import 'features/chat/domain/usecases/subscribe_to_channel.dart';
import 'features/chat/presentation/bloc/presence_cubit.dart';
import 'features/chat/presentation/bloc/chat_cubit.dart';
import 'features/maintenance/data/datasources/maintenance_remote_data_source.dart';
import 'features/maintenance/data/repositories/maintenance_repository_impl.dart';
import 'features/maintenance/presentation/bloc/maintenance_cubit.dart';
import 'features/maintenance/presentation/bloc/manager_cubit.dart';
import 'features/social/data/datasources/social_remote_data_source.dart';
import 'features/social/data/repositories/social_repository_impl.dart';
import 'features/social/presentation/bloc/social_cubit.dart';
import 'features/profile/presentation/bloc/profile_cubit.dart';
import 'features/chat/presentation/bloc/chat_details_cubit.dart';
import 'features/chat/presentation/bloc/message_receipts_cubit.dart';
import 'core/services/GoogleDriveService.dart';

import 'Layout/Cubit/cubit.dart';
import 'features/admin/presentation/bloc/report_cubit.dart';

import 'features/admin/data/datasources/admin_remote_data_source.dart';
import 'features/admin/data/repositories/admin_repository_impl.dart';
import 'features/admin/presentation/bloc/admin_cubit.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/auth/data/auth_ready_gate.dart';

import 'features/chat/presentation/widgets/chatWidget/Details/ChatMember.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const SimpleBlocObserver();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  supabase = Supabase.instance.client;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final authCubit = AuthCubit(
              repository: AuthRepositoryImpl(
                remoteDataSource: SupabaseAuthRemoteDataSourceImpl(supabase),
                supabaseClient: supabase,
                googleDriveService: driveService,
              ),
            );
            authCubit.presetBeforeSignin();
            return authCubit;
          },
        ),
        BlocProvider(create: (context) => AppCubit()),
        BlocProvider(create: (context) => ReportCubit()),
        BlocProvider(create: (context) => PresenceCubit()),
        BlocProvider(
          create: (context) => AdminCubit(
            adminRepository: AdminRepositoryImpl(
              remoteDataSource: SupabaseAdminRemoteDataSourceImpl(supabase: supabase),
            ),
          ),
        ),
        BlocProvider(create: (context) => ManagerCubit()),
        BlocProvider(
          create: (context) => ChatDetailsCubit(
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) {
            final authState = context.read<AuthCubit>().state;
            final members = (authState is Authenticated) ? authState.chatMembers : <ChatMember>[];
            return MessageReceiptsCubit(supabase, chatMembers: members);
          },
        ),
        BlocProvider(
          create: (context) {
            final chatRepository = ChatRepositoryImpl(
              ChatRemoteDataSourceImpl(supabase),
              supabase,
            );
            return ChatCubit(
              fetchMessagesUsecase: FetchMessages(chatRepository),
              sendTextMessageUsecase: SendTextMessage(chatRepository),
              sendFileMessageUsecase: SendFileMessage(chatRepository),
              sendVoiceNoteUsecase: SendVoiceNote(chatRepository),
              markMessageSeenUsecase: MarkMessageSeen(chatRepository),
              deleteMessageUsecase: DeleteMessage(chatRepository),
              resolveUserUsecase: ResolveUser(chatRepository),
              subscribeToChannelUsecase: SubscribeToChannel(chatRepository),
            );
          },
        ),
        BlocProvider(
          create: (context) => MaintenanceCubit(
            repository: MaintenanceRepositoryImpl(
              remoteDataSource: SupabaseMaintenanceRemoteDataSourceImpl(supabase),
              driveService: GoogleDriveService(),
              supabaseClient: supabase,
            ),
          ),
        ),
        BlocProvider(
          create: (context) => SocialCubit(
            repository: SocialRepositoryImpl(
              remoteDataSource: SocialRemoteDataSourceImpl(client: supabase),
              driveService: GoogleDriveService(),
            ),
          ),
        ),
        BlocProvider(create: (context) => ProfileCubit()),
      ],
      child: ChangeNotifierProvider(
        create: (_) => AuthManager(),
        child: MaterialApp(
          title: 'WhatsUnity',
          debugShowCheckedModeBanner: false,
          theme: myLightTheme(),
          supportedLocales: L10n.all,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale != null &&
                supportedLocales.any((l) => l.languageCode == deviceLocale.languageCode)) {
              return deviceLocale;
            }
            return supportedLocales.first;
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.0),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
            builder: (context, state) {
              final authManager = context.watch<AuthManager>();
              final authCubit = context.read<AuthCubit>();

              if (authManager.status == AuthStatus.unknown) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (authManager.status == AuthStatus.authenticated &&
                  authCubit.signupGoogleEmail == null &&
                  authCubit.signInGoogle == false) {
                return const AuthReadyGate();
              }

              requestPermission();
              return SignUp();
            },
          ),
        ),
      ),
    );
  }
}


class AuthManager extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  StreamSubscription<supabase_auth.AuthState>? _sub;

  AuthManager() {
    _sub = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null) {
            status = AuthStatus.authenticated;
            notifyListeners();
          }
          break;
        case AuthChangeEvent.signedOut:
          status = AuthStatus.unauthenticated;
          notifyListeners();
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (session != null) {
            if (status != AuthStatus.authenticated) {
              status = AuthStatus.authenticated;
              notifyListeners();
            }
          }
          break;
        default:
          break;
      }
    });

    final current = supabase.auth.currentSession;
    if (current != null) {
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
