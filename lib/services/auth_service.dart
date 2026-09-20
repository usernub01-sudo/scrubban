import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// هل فيه مستخدم مسجّل دخول دلوقتي؟
  bool get isLoggedIn => _client.auth.currentUser != null;

  /// بيانات المستخدم الحالي (أو null)
  User? get currentUser => _client.auth.currentUser;

  /// إيميل الأدمن الحالي
  String? get currentEmail => currentUser?.email;

  /// تسجيل دخول بالإيميل والباسورد
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// تسجيل خروج
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
