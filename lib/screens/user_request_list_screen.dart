// lib/screens/user_request_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import 'chat_screen.dart';

class UserRequestListScreen extends StatelessWidget {
  const UserRequestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('내가 낸 요청 목록')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService.requestsForUser(uid),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('아직 낸 요청이 없습니다.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final req = docs[i];
              final data = req.data();
              final tripId   = data['tripId']  as String? ?? '';
              final country  = data['country'] as String? ?? '';
              final item     = data['item']    as String? ?? '';
              final quantity = data['quantity'] as int?    ?? 0;
              final status   = data['status']  as String? ?? '';

              return Dismissible(
                key: Key(req.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('요청 삭제'),
                      content: const Text('정말 이 요청을 삭제하시겠습니까?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('삭제')),
                      ],
                    ),
                  ) ?? false;
                },
                onDismissed: (_) async {
                  await FirebaseService.deleteRequest(req.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('요청이 삭제되었습니다.')),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('$country — $item (x$quantity)'),
                    subtitle: Text('상태: $status'),
                    trailing: IconButton(
                      icon: const Icon(Icons.message),
                      tooltip: '판매자와 채팅',
                      onPressed: () async {
                        if (tripId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('잘못된 여행 정보입니다.')),
                          );
                          return;
                        }
                        // 1) 여행 문서에서 판매자(소유자) ID 조회
                        final tripDoc = await FirebaseService.firestore
                            .collection('trips')
                            .doc(tripId)
                            .get();
                        final ownerId = tripDoc.data()?['userId'] as String?;
                        if (ownerId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('판매자 정보를 찾을 수 없습니다.')),
                          );
                          return;
                        }
                        // 2) 판매자 닉네임 조회
                        final ownerProfile = await FirebaseService.firestore
                            .collection('users')
                            .doc(ownerId)
                            .get();
                        final ownerNick = ownerProfile.data()?['nickname'] as String? ?? 'Unknown';
                        // 3) 채팅방 ID 생성 및 문서 보장
                        final me = uid;
                        final chatId = FirebaseService.chatIdFor(me, ownerId);
                        await FirebaseService.firestore
                            .collection('chats')
                            .doc(chatId)
                            .set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
                        // 4) ChatScreen으로 네비게이션
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
