// lib/screens/profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseService.auth.currentUser!.uid;
    // Firestore에 저장된 닉네임만 불러오기
    FirebaseService.streamUserProfile(uid).first.then((snap) {
      final data = snap.data();
      if (data != null && data['nickname'] is String) {
        _nicknameController.text = data['nickname'];
      }
      setState(() {});
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    // 닉네임만 Firestore에 업데이트
    final uid = FirebaseService.auth.currentUser!.uid;
    await FirebaseService.updateNickname(
      userId: uid,
      nickname: _nicknameController.text.trim(),
    );

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1) 로컬 선택된 이미지만 CircleAvatar에 표시
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundImage:
                    _pickedImage != null ? FileImage(_pickedImage!) : null,
                child: _pickedImage == null
                    ? const Icon(Icons.camera_alt, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // 2) 닉네임 입력
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 3) 저장 버튼
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _save,
                    child: const Text('저장'),
                  ),
          ],
        ),
      ),
    );
  }
}

