// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import '../firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    form.save();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseService.auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );
      // Navigator 호출 없이 authStateChanges() 로 자동 분기
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 전체 배경을 흰색으로, AppBar 제거 or 가볍게
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // (선택) 로고나 제목
              const FlutterLogo(size: 72),
              const SizedBox(height: 24),

              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 이메일 입력란
                    TextFormField(
                      key: const ValueKey('email'),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: '이메일',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      validator: (val) {
                        if (val == null ||
                            val.trim().isEmpty ||
                            !val.contains('@')) {
                          return '유효한 이메일을 입력해주세요.';
                        }
                        return null;
                      },
                      onSaved: (val) => _email = val ?? '',
                    ),
                    const SizedBox(height: 16),

                    // 비밀번호 입력란
                    TextFormField(
                      key: const ValueKey('password'),
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '비밀번호',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) {
                          return '6자 이상 비밀번호를 입력해주세요.';
                        }
                        return null;
                      },
                      onSaved: (val) => _password = val ?? '',
                    ),
                    const SizedBox(height: 24),

                    // 로그인 버튼
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('로그인', style: TextStyle(fontSize: 16)),
                        ),
                      ),

                    // (선택) 회원가입 전환 텍스트 버튼
                    TextButton(
                      onPressed: () {
                        // 회원가입 화면으로 이동하거나 모드를 토글
                      },
                      child: const Text('계정이 없으신가요? 회원가입'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

