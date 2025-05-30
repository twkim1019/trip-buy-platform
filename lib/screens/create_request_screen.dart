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
  String _item = '';
  int _quantity = 1;
  String _notes = '';

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await FirebaseService.saveRequest(
        userId: FirebaseService.currentUser!.uid,
        tripId: widget.tripId,
        country: widget.country,
        item: _item,
        quantity: _quantity,
        notes: _notes,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 요청이 등록되었습니다.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('구매 요청 등록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('여행 국가: ${widget.country}'),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: '물건 이름'),
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
                onChanged: (v) => _item = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: '수량'),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return '1 이상 숫자 입력';
                  return null;
                },
                onChanged: (v) => _quantity = int.tryParse(v) ?? 1,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: '추가 요청 사항'),
                maxLines: 3,
                onChanged: (v) => _notes = v,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitRequest,
                child: const Text('요청 등록'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
