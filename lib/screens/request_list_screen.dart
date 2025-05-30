// lib/screens/request_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import 'chat_screen.dart';

class RequestListScreen extends StatelessWidget {
  final String tripId;
  final String country;

  const RequestListScreen({
    super.key,
    required this.tripId,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    final me = FirebaseService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('요청 목록 - $country')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService.requestsForTrip(tripId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('등록된 요청이 없습니다.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final req = docs[i];
              final data = req.data();
              final requesterId = data['userId'] as String;
              final item        = data['item']    as String;
              final quantity    = data['quantity'] as int;
              final notes       = data['notes']    as String;
              final status      = data['status']   as String;

              // 요청 하나당 프로필 스트림을 구독해서 닉네임을 가져옵니다.
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseService.streamUserProfile(requesterId),
                builder: (ctx2, snap2) {
                  final profile = snap2.data?.data() ?? {};
                  final nick = profile['nickname'] as String? ?? '익명';

                  return Dismissible(
                    key: Key(req.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await FirebaseService.deleteRequest(req.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('요청이 삭제되었습니다.')),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        // 요청자 이니셜 아바타
                        leading: CircleAvatar(
                          child: Text(
                            nick.isNotEmpty ? nick[0] : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),

                        // “닉네임 님의 요청: 아이템 (x수량)” 형태로 표시
                        title: Text('$nick 님의 구매 요청: $item (x$quantity)'),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (notes.isNotEmpty) Text('추가 요청: $notes'),
                            Text('상태: $status'),
                          ],
                        ),

                        // 메시지 버튼: 채팅 화면으로 연결
                        trailing: IconButton(
                          icon: const Icon(Icons.message),
                          tooltip: '메시지 보내기',
                          onPressed: () {
                            final chatId = FirebaseService.chatIdFor(me, requesterId);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: requesterId,
                                  otherNickname: nick,
                                ),
                              ),
                            );
                          },
                        ),
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
