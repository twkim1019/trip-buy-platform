// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/auth_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Agent App',
      // ① 앱 기본 로케일을 한국어로 지정
      locale: const Locale('ko', 'KR'),
      // ② 지원하는 로케일 목록
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      // ③ Flutter 내장 위젯들의 지역화 Delegate
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(primarySwatch: Colors.blue),
      // ④ 인증 상태에 따라 진입 화면 분기
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          final user = snapshot.data;
          // 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // 비로그인 상태 → AuthScreen
          if (user == null) {
            return const AuthScreen();
          }
          // 로그인은 되어 있으나 이메일 미인증 → VerifyEmailScreen
          if (!user.emailVerified) {
            return const VerifyEmailScreen();
          }
          // 로그인 & 이메일 인증 완료 → HomeScreen
          return const HomeScreen();
        },
      ),
    );
  }
}
