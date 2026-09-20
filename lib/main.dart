import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/admin/admin_login_page.dart';
import 'pages/home_page.dart';
import 'providers/cart_provider.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // نقرأ الـURL الحالي عشان نعرف إذا كنا داخلين على /admin
  // Flutter Web بيستخدم hash URL strategy by default:
  //   https://site.com/#/admin  →  Uri.base.fragment = '/admin'
  final fragment = Uri.base.fragment;
  final isAdminRoute = fragment.startsWith('/admin');

  runApp(ScrubbanStoreApp(isAdminRoute: isAdminRoute));
}

class ScrubbanStoreApp extends StatelessWidget {
  final bool isAdminRoute;

  const ScrubbanStoreApp({super.key, required this.isAdminRoute});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'Scrubban Store',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: isAdminRoute ? const _AdminGate() : const HomePage(),
      ),
    );
  }
}

/// يقرر: هل الأدمن مسجّل دخول؟ → Dashboard / Login
class _AdminGate extends StatelessWidget {
  const _AdminGate();

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    if (authService.isLoggedIn) {
      return const AdminDashboardPage();
    }
    return const AdminLoginPage();
  }
}
