// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import 'create_trip_screen.dart';
import 'create_request_screen.dart';
import 'request_list_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'user_request_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.request_page),
            tooltip: '내 요청 보기',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UserRequestListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '내 프로필',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => FirebaseService.auth.signOut(),
          ),
        ],
      ),

      body: Column(
        children: [
          // 상단 환영 메시지
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.streamUserProfile(me!),
              builder: (ctx, snap) {
                final data = snap.data?.data();
                final nick = data?['nickname'] as String?;
                return Text(
                  nick != null && nick.isNotEmpty
                    ? '$nick님, 환영합니다! 🛫'
                    : '환영합니다! 🛫 구매대행 앱에 오신 것을 환영해요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                );
              },
            ),
          ),
          const Divider(),

          // 전체 여행 일정 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.allTrips(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('등록된 여행 일정이 없습니다.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc  = docs[i];
                    final data = doc.data();
                    final ownerId = data['userId'] as String;
                    final country = data['country'] as String? ?? '알 수 없는 지역';
                    final startTs = data['startDate'] as Timestamp?;
                    final endTs   = data['endDate']   as Timestamp?;
                    final start = startTs?.toDate();
                    final end   = endTs?.toDate();
                    final dateText = (start != null && end != null)
                      ? '${start.year}-${start.month.toString().padLeft(2,'0')}-${start.day.toString().padLeft(2,'0')}'
                        ' → '
                        '${end.year}-${end.month.toString().padLeft(2,'0')}-${end.day.toString().padLeft(2,'0')}'
                      : '날짜 정보 없음';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        // ① 여행자 닉네임 아바타
                        leading: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseService.streamUserProfile(ownerId),
                          builder: (ctx2, snap2) {
                            final profile = snap2.data?.data();
                            final ownerNick = profile?['nickname'] as String? ?? '';
                            return CircleAvatar(
                              child: Text(
                                ownerNick.isNotEmpty ? ownerNick[0] : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),

                        // ② 제목·부제
                        title: Text('$country'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateText),
                            const SizedBox(height: 4),
                            // 소제목: “홍길동 님의 여행”
                            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseService.streamUserProfile(ownerId),
                              builder: (ctx3, snap3) {
                                final p = snap3.data?.data();
                                final nick = p?['nickname'] as String? ?? '';
                                return Text(
                                  nick.isNotEmpty
                                    ? '$nick 님의 여행'
                                    : '작성자 정보 없음',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                );
                              },
                            ),
                          ],
                        ),

                        // ③ 요청·채팅 버튼
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.list_alt),
                              tooltip: '요청 보기',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RequestListScreen(
                                      tripId: doc.id,
                                      country: country,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat),
                              tooltip: '채팅',
                              onPressed: () {
                                final chatId = FirebaseService.chatIdFor(me, ownerId);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      otherUserId: ownerId,
                                      otherNickname: '',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        onTap: () {
                          // 바로 구매 요청 작성
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateRequestScreen(
                                tripId: doc.id,
                                country: country,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ④ 새 일정 등록 FAB
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: '새 일정 등록',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateTripScreen()),
          );
        },
      ),
    );
  }
}

