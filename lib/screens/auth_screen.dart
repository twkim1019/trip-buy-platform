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
  String _email = '', _password = '', _nickname = '';
  bool _isLoading = false;
  String? _error;
  bool _isLogin = true; // true: 로그인, false: 회원가입

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    form.save();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        // --- 로그인 ---
        await FirebaseService.auth.signInWithEmailAndPassword(
          email: _email.trim(),
          password: _password,
        );
      } else {
        // --- 회원가입 ---
        final cred = await FirebaseService.auth
            .createUserWithEmailAndPassword(
              email: _email.trim(),
              password: _password,
            );
        // 닉네임 프로필 저장
        await FirebaseService.saveUserProfile(
          userId: cred.user!.uid,
          nickname: _nickname.trim(),
        );
        // 이메일 인증 메일 발송
        await cred.user!.sendEmailVerification();
      }
      // Navigator 호출 없이 authStateChanges()로 분기 유지
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? '로그인' : '회원가입';
    final actionText = _isLogin ? '로그인' : '회원가입';
    final switchText =
        _isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있나요? 로그인';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 이메일
                      TextFormField(
                        key: const ValueKey('email'),
                        decoration: const InputDecoration(labelText: '이메일'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || !val.contains('@')) {
                            return '유효한 이메일을 입력해주세요.';
                          }
                          return null;
                        },
                        onSaved: (val) => _email = val ?? '',
                      ),
                      const SizedBox(height: 12),
                      // 비밀번호
                      TextFormField(
                        key: const ValueKey('password'),
                        decoration: const InputDecoration(labelText: '비밀번호'),
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return '6자 이상 비밀번호를 입력해주세요.';
                          }
                          return null;
                        },
                        onSaved: (val) => _password = val ?? '',
                      ),
                      const SizedBox(height: 12),
                      if (!_isLogin) ...[
                        // 회원가입 모드에서만 닉네임 입력
                        TextFormField(
                          key: const ValueKey('nickname'),
                          decoration: const InputDecoration(labelText: '닉네임'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return '닉네임을 입력해주세요.';
                            }
                            return null;
                          },
                          onSaved: (val) => _nickname = val ?? '',
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(actionText),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(switchText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
