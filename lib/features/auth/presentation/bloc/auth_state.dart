import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:WhatsUnity/core/config/Enums.dart';
import 'package:WhatsUnity/core/config/supabase.dart';
import 'package:WhatsUnity/core/models/CompoundsList.dart';
import 'package:WhatsUnity/features/chat/presentation/widgets/chatWidget/Details/ChatMember.dart';

abstract class AuthState {
  final List<Category> categories;
  final List<String> compoundsLogos;

  AuthState({
    this.categories = const [],
    this.compoundsLogos = const [],
  });
}

class AuthInitial extends AuthState {
  AuthInitial({
    super.categories,
    super.compoundsLogos,
  });
}

class AuthLoading extends AuthState {
  AuthLoading({
    super.categories,
    super.compoundsLogos,
  });
}

class Authenticated extends AuthState {
  final User user;
  final Roles? role;
  final ChatMember? currentUser;
  final List<ChatMember> chatMembers;
  final List<Users> membersData;
  final Map<String, dynamic> myCompounds;
  final int? selectedCompoundId;

  final bool enabledMultiCompound;
  final GoogleSignInAccount? googleUser;

  Authenticated({
    required this.user,
    this.role,
    this.currentUser,
    this.chatMembers = const [],
    this.membersData = const [],
    this.myCompounds = const {'0': "Add New Community"},
    this.selectedCompoundId,
    this.enabledMultiCompound = false,
    this.googleUser,
    super.categories,
    super.compoundsLogos,
  });

  Authenticated copyWith({
    User? user,
    Roles? role,
    ChatMember? currentUser,
    List<ChatMember>? chatMembers,
    List<Users>? membersData,
    Map<String, dynamic>? myCompounds,
    int? selectedCompoundId,
    bool? enabledMultiCompound,
    GoogleSignInAccount? googleUser,
    List<Category>? categories,
    List<String>? compoundsLogos,
  }) {
    return Authenticated(
      user: user ?? this.user,
      role: role ?? this.role,
      currentUser: currentUser ?? this.currentUser,
      chatMembers: chatMembers ?? this.chatMembers,
      membersData: membersData ?? this.membersData,
      myCompounds: myCompounds ?? this.myCompounds,
      selectedCompoundId: selectedCompoundId ?? this.selectedCompoundId,
      enabledMultiCompound: enabledMultiCompound ?? this.enabledMultiCompound,
      googleUser: googleUser ?? this.googleUser,
      categories: categories ?? this.categories,
      compoundsLogos: compoundsLogos ?? this.compoundsLogos,
    );
  }
}

class Unauthenticated extends AuthState {
  Unauthenticated({
    super.categories,
    super.compoundsLogos,
  });
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message, {
    super.categories,
    super.compoundsLogos,
  });
}

class RegistrationSuccess extends AuthState {
  RegistrationSuccess({
    super.categories,
    super.compoundsLogos,
  });
}

class SignUpSuccess extends AuthState {
  final String email;
  SignUpSuccess({
    required this.email,
    super.categories,
    super.compoundsLogos,
  });
}

class ApartmentTakenStatus extends AuthState {
  final bool isTaken;
  ApartmentTakenStatus({
    required this.isTaken,
    super.categories,
    super.compoundsLogos,
  });
}

class CompoundSelected extends AuthState {
  final int compoundId;
  CompoundSelected(this.compoundId, {
    super.categories,
    super.compoundsLogos,
  });
}

class GoogleSignupState extends AuthState {
  GoogleSignupState({
    super.categories,
    super.compoundsLogos,
  });
}

class ProfileUpdated extends AuthState {
  ProfileUpdated({
    super.categories,
    super.compoundsLogos,
  });
}

class EmailChangeRequested extends AuthState {
  EmailChangeRequested({
    super.categories,
    super.compoundsLogos,
  });
}

class PasswordUpdated extends AuthState {
  PasswordUpdated({
    super.categories,
    super.compoundsLogos,
  });
}

class CompoundMembersUpdated extends AuthState {
  final int compoundId;
  final List<ChatMember> chatMembers;
  final List<Users> membersData;
  final ChatMember? currentUser;

  CompoundMembersUpdated({
    required this.compoundId,
    required this.chatMembers,
    required this.membersData,
    this.currentUser,
    super.categories,
    super.compoundsLogos,
  });
}

