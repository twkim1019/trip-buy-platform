// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _nickname = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseService.currentUser!.uid;
    FirebaseService.streamUserProfile(uid).listen((snapshot) {
      final data = snapshot.data();
      if (data != null && mounted) {
        setState(() {
          _nickname = data['nickname'] ?? '';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseService.currentUser!.uid;
    await FirebaseService.saveUserProfile(
      userId: uid,
      nickname: _nickname,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: _nickname,
                      decoration: const InputDecoration(labelText: '닉네임'),
                      validator: (v) => v == null || v.isEmpty ? '닉네임을 입력하세요' : null,
                      onChanged: (v) => _nickname = v,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
