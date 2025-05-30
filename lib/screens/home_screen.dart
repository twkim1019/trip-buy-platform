// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../firebase_service.dart';
import 'create_trip_screen.dart';
import 'trip_list_screen.dart';
import 'user_request_list_screen.dart';
import 'profile_screen.dart';
import 'all_trips_screen.dart';  // ← 추가

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          // 전체 일정 조회 버튼
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: '전체 일정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AllTripsScreen()),
              );
            },
          ),
          // 내 요청 보기
          IconButton(
            icon: const Icon(Icons.request_page),
            tooltip: '내 요청 보기',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserRequestListScreen()),
              );
            },
          ),
          // 내 프로필
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '내 프로필',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          // 일정 목록
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: '일정 목록',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TripListScreen()),
              );
            },
          ),
          // 로그아웃
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => FirebaseService.auth.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          '환영합니다! 🛫\n구매대행 앱에 오신 것을 환영해요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateTripScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '새 일정 등록',
      ),
    );
  }
}
