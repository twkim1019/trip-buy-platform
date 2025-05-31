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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '요청 목록 • $country',
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.requestsForTrip(tripId),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  '아직 요청이 없습니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              );
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final data = doc.data();
                final requesterId = data['userId'] as String;
                final item = data['item'] as String;
                final quantity = data['quantity'] as int;
                final notes = (data['notes'] as String?) ?? '';
                final status = (data['status'] as String?) ?? 'pending';

                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red.shade300,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (dir) async {
                    // 본인 요청만 삭제 허용
                    if (requesterId != FirebaseService.currentUser!.uid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('본인 요청만 삭제 가능합니다.'),
                          backgroundColor: Colors.black87,
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                      return false;
                    }
                    return true;
                  },
                  onDismissed: (_) async {
                    await FirebaseService.deleteRequest(doc.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('요청이 삭제되었습니다.'),
                        backgroundColor: Colors.black87,
                        duration: Duration(milliseconds: 1000),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream:
                            FirebaseService.streamUserProfile(requesterId),
                        builder: (ctx2, snap2) {
                          final nick =
                              snap2.data?.data()?['nickname'] as String? ??
                                  '';
                          return CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              (nick.isNotEmpty)
                                  ? nick[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                      title: Text(
                        '$item × $quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              notes,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '상태: ${status == 'pending' ? '대기 중' : status}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseService
                                .streamUserProfile(requesterId)
                                .first,
                            builder: (ctx3, sn3) {
                              final nick =
                                  sn3.data?.data()?['nickname'] as String? ??
                                      '';
                              return Text(
                                '$nick 님의 요청',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black38,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.black54,
                          size: 22,
                        ),
                        onPressed: () {
                          final chatId = FirebaseService.chatIdFor(
                            requesterId,
                            FirebaseService.currentUser!.uid,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUserId: requesterId,
                                otherNickname: '',
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
      ),
    );
  }
}



