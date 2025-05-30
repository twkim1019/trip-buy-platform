// lib/screens/all_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import 'create_request_screen.dart';
import 'chat_screen.dart';

/// 모든 사용자의 여행 일정을 볼 수 있는 화면
class AllTripsScreen extends StatelessWidget {
  const AllTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전체 여행 일정')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService.firestore
            .collection('trips')
            .orderBy('createdAt', descending: true)
            .snapshots(),
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
              final doc = docs[i];
              final data = doc.data();
              final ownerId = data['userId'] as String? ?? '';
              final country = data['country'] as String? ?? '';
              final startDate = (data['startDate'] as Timestamp?)?.toDate();
              final endDate = (data['endDate'] as Timestamp?)?.toDate();

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseService.firestore
                    .collection('users')
                    .doc(ownerId)
                    .get(),
                builder: (ctx2, userSnap) {
                  final ownerNick = userSnap.data?.data()?['nickname'] as String? ?? 'Unknown';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(ownerNick.isNotEmpty ? ownerNick[0] : '?'),
                      ),
                      title: Text('$ownerNick님의 목적지: $country'),
                      subtitle: Text(
                        startDate != null && endDate != null
                            ? '${startDate.year}-${startDate.month.toString().padLeft(2,'0')}-${startDate.day.toString().padLeft(2,'0')}'
                              ' → '
                              '${endDate.year}-${endDate.month.toString().padLeft(2,'0')}-${endDate.day.toString().padLeft(2,'0')}'
                            : '날짜 정보 없음',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart),
                            tooltip: '구매 요청',
                            onPressed: () {
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
                          IconButton(
                            icon: const Icon(Icons.message),
                            tooltip: '판매자와 채팅',
                            onPressed: () async {
                              // 1) 판매자 닉네임 얻기
                              final me = FirebaseService.currentUser!.uid;
                              final chatId = FirebaseService.chatIdFor(me, ownerId);
                              await FirebaseService.firestore
                                  .collection('chats')
                                  .doc(chatId)
                                  .set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
                              // 2) ChatScreen으로 이동
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
              );
            },
          );
        },
      ),
    );
  }
}
