// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_service.dart';
import 'create_request_screen.dart';
import 'request_list_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 전체 trips 스트림 (createdAt 내림차순)
    final tripStream = FirebaseService.firestore
        .collection('trips')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
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
            onPressed: () {
              FirebaseService.auth.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tripStream,
        builder: (ctx, tripSnap) {
          if (tripSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tripDocs = tripSnap.data?.docs ?? [];
          if (tripDocs.isEmpty) {
            return const Center(child: Text('등록된 여행 일정이 없습니다.'));
          }

          return ListView.builder(
            itemCount: tripDocs.length,
            itemBuilder: (ctx, i) {
              final tripDoc = tripDocs[i];
              final tripData = tripDoc.data();
              final country = tripData['country'] as String? ?? '미정';
              final startTs = tripData['startDate'] as Timestamp?;
              final endTs = tripData['endDate'] as Timestamp?;
              final ownerId = tripData['userId'] as String;

              // 날짜 문자열 생성
              String dates;
              if (startTs != null && endTs != null) {
                final s = startTs.toDate();
                final e = endTs.toDate();
                dates =
                    '${s.year}-${s.month.toString().padLeft(2,'0')}-${s.day.toString().padLeft(2,'0')}'
                    ' → '
                    '${e.year}-${e.month.toString().padLeft(2,'0')}-${e.day.toString().padLeft(2,'0')}';
              } else {
                dates = '날짜 미정';
              }

              // 여행자 프로필(닉네임) 스트림
              final ownerProfileStream = FirebaseService.streamUserProfile(ownerId);

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: ownerProfileStream,
                  builder: (ctx2, profSnap) {
                    final profData = profSnap.data?.data();
                    final ownerNick = profData?['nickname'] as String? ?? '익명';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          ownerNick.isNotEmpty
                              ? ownerNick[0]
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('$ownerNick 님의 $country'),
                      subtitle: Text(dates),
                      // ① 터치 → 요청 추가 화면
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateRequestScreen(
                              tripId: tripDoc.id,
                              country: country,
                            ),
                          ),
                        );
                      },
                      // ② 우측 아이콘 버튼 두 개
                      trailing: SizedBox(
                        width: 96, // 두 개 아이콘이 들어갈 넉넉한 폭
                        child: Row(
                          children: [
                            // 요청 목록
                            IconButton(
                              icon: const Icon(Icons.list_alt),
                              tooltip: '요청 목록',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RequestListScreen(
                                      tripId: tripDoc.id,
                                      country: country,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // 채팅
                            IconButton(
                              icon: const Icon(Icons.message),
                              tooltip: '채팅',
                              onPressed: () {
                                final me = FirebaseService.currentUser!.uid;
                                final chatId = FirebaseService.chatIdFor(
                                  me,
                                  ownerId,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      otherUserId: ownerId,
                                      otherNickname: ownerNick,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
    );
  }
}
