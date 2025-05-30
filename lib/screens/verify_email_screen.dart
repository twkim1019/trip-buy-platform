// lib/screens/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 1) 주기적으로 인증 상태 체크
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerified());
  }

  Future<void> _checkVerified() async {
    await user?.reload();
    if (user?.emailVerified ?? false) {
      _timer?.cancel();
      if (!mounted) return;
      // 이메일 인증 완료 시 홈으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _resendEmail() async {
    try {
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 메일을 다시 보냈습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증 대기')),
      body: Center(                          // ← Center 로 감싸줍니다
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 세로도 중간에 모이게
            crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙 정렬
            children: [
              const Text(
                '인증 메일을 보냈습니다.\n메일함에서 “인증”을 누른 뒤\n다시 로그인 해주세요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resendEmail,
                child: const Text('인증 메일 다시 보내기'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('로그인'),
              ),
            ],
          ),
        ),
      ),
    );
    }
  }
