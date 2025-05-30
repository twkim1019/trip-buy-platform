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
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 초기값 불러오기
    final user = FirebaseService.currentUser!;
    FirebaseService.streamUserProfile(user.uid).first.then((snap) {
      final data = snap.data();
      setState(() {
        _nickname = (data?['nickname'] as String?) ?? '';
      });
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    form.save();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseService.currentUser!.uid;
      await FirebaseService.updateNickname(userId, _nickname);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임이 업데이트되었습니다.')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            Form(
              key: _formKey,
              child: TextFormField(
                initialValue: _nickname,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return '닉네임을 입력하세요.';
                  }
                  return null;
                },
                onSaved: (val) => _nickname = val!.trim(),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('저장'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

