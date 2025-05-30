import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firebase_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});
  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  String _country = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final first = DateTime.now().subtract(const Duration(days: 365 * 5));
    final last = DateTime.now().add(const Duration(days: 365 * 5));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작일과 종료일을 모두 선택해주세요.')),
      );
      return;
    }
    try {
      await FirebaseService.saveTrip(
        userId: FirebaseService.currentUser!.uid,
        country: _country,
        start: _startDate!,
        end: _endDate!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여행 일정이 저장되었습니다.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: \$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(title: const Text('일정 등록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: '국가'),
                validator: (v) => v == null || v.isEmpty ? '국가를 입력하세요' : null,
                onChanged: (v) => _country = v,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, true),
                      child: Text(
                        _startDate == null ? '시작일 선택' : df.format(_startDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text(
                        _endDate == null ? '종료일 선택' : df.format(_endDate!),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveTrip,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
