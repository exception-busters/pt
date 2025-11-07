import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/core/router/app_router.dart';
import 'package:flutter_application_1/color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wkmnnzndtggrlrzjlncn.supabase.co', // Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrbW5uem5kdGdncmxyempsbmNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExODU1NDIsImV4cCI6MjA3Njc2MTU0Mn0.bd9pcs-4YDyL98YcKhBzq53u2CONtjUv7NdYEcDA-eU', // Supabase anon key
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // 🔥 테스트용: 앱 시작 시 강제 로그아웃 및 캐시 정리
  try {
    await Supabase.instance.client.auth.signOut();
    print('🔥 앱 시작 시 강제 로그아웃 완료');
    
    // SharedPreferences 캐시도 정리
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🔥 SharedPreferences 캐시 정리 완료');
  } catch (e) {
    print('⚠️ 강제 로그아웃/캐시 정리 실패: $e');
  }

  runApp(const ProviderScope(child: PTApp()));
}

class PTApp extends ConsumerWidget {
  const PTApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PT 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: mainButtonColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: mainButtonColor,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: mainButtonColor,
            foregroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: mainButtonColor, width: 2),
          ),
          filled: true,
          fillColor: backgroundColor,
        ),
      ),
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}
