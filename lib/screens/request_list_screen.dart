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
              final requesterId = data['userId'] as String? ?? '';
              final item        = data['item']    as String? ?? '';
              final quantity    = data['quantity'] as int?    ?? 0;
              final notes       = data['notes']    as String? ?? '';
              final status      = data['status']   as String? ?? '';

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
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseService.streamUserProfile(requesterId),
                      builder: (ctx2, snap2) {
                        final nick = snap2.data?.data()?['nickname'] as String? ?? '?';
                        return CircleAvatar(child: Text(nick[0]));
                      },
                    ),
                    title: Text('$item (x$quantity)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notes.isNotEmpty) Text('추가 요청: $notes'),
                        Text('상태: $status'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.message),
                      tooltip: '채팅',
                      onPressed: () async {
                        if (requesterId.isEmpty) return;
                        // 1) 채팅방 ID 생성
                        final chatId = FirebaseService.chatIdFor(me, requesterId);
                        // 2) 채팅방 문서 생성(merge)해서 보장
                        await FirebaseService.firestore
                            .collection('chats')
                            .doc(chatId)
                            .set({'createdAt': FieldValue.serverTimestamp()},
                                 SetOptions(merge: true));
                        // 3) 요청자 닉네임 조회
                        final userSnap = await FirebaseService.firestore
                            .collection('users')
                            .doc(requesterId)
                            .get();
                        final otherNick = userSnap.data()?['nickname'] as String? ?? 'Unknown';
                        // 4) ChatScreen으로 이동
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: requesterId,
                              otherNickname: otherNick,
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
      ),
    );
  }
}
