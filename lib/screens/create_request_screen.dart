// lib/screens/create_request_screen.dart

import 'package:flutter/material.dart';
import '../firebase_service.dart';

class CreateRequestScreen extends StatefulWidget {
  final String tripId;
  final String country;

  const CreateRequestScreen({
    super.key,
    required this.tripId,
    required this.country,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController(text: '1');
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _itemCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseService.saveRequest(
        userId: FirebaseService.currentUser!.uid,
        tripId: widget.tripId,
        country: widget.country,
        item: _itemCtrl.text.trim(),
        quantity: int.parse(_quantityCtrl.text.trim()),
        notes: _notesCtrl.text.trim(),
      );
      Navigator.of(context).pop();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('요청 저장에 실패했습니다.'),
          backgroundColor: Colors.black87,
          duration: Duration(milliseconds: 1200),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 기본 흰색 배경, AppBar도 심플하게 흰색+검정 아이콘
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '요청하기 • ${widget.country}',
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: const Color(0xFFF9F9F9), // 연한 회색 배경
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // [아이템] 입력
                    TextFormField(
                      controller: _itemCtrl,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: '아이템 (필수)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '아이템을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 16),

                    // [수량] 입력
                    TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: '수량 (숫자만 입력)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null ||
                            v.trim().isEmpty ||
                            int.tryParse(v.trim()) == null ||
                            int.parse(v.trim()) < 1) {
                          return '1 이상의 숫자를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 16),

                    // [추가 요청] 입력
                    TextFormField(
                      controller: _notesCtrl,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: '추가 요청 (선택)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    const Spacer(),

                    // [요청 등록 버튼]
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isLoading ? null : _submit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '요청 등록',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
