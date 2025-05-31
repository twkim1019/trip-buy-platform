// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherNickname;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherNickname,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 내 uid
    final me = FirebaseService.currentUser!.uid;
    // 채팅방 id (알파벳 순서대로 정렬해서 생성)
    final chatId = FirebaseService.chatIdFor(me, widget.otherUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherNickname, style: const TextStyle(fontWeight: FontWeight.w500)),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      // 메인 배경은 연한 그레이 톤
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // 1) 메시지 리스트
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseService.streamMessages(chatId),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    reverse: true, // 최신 메시지가 아래에 오도록 뒤집기
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (ctx, iReverse) {
                      // 뒤집어 놓았으니 실제 인덱스는 length-1-iReverse
                      final i = docs.length - 1 - iReverse;
                      final msg = docs[i].data();
                      final isMe = msg['senderId'] == me;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[200] : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMe ? 12 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              )
                            ],
                          ),
                          child: Text(
                            msg['text'] as String,
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 2) 입력창 + 전송 버튼 (바닥 고정)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
              child: Row(
                children: [
                  // 입력란
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: '메시지 입력...',
                        fillColor: Colors.grey[200],
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMeessage(chatId),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // 전송 버튼
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () => _sendMeessage(chatId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMeessage(String chatId) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FirebaseService.sendMessage(
      chatId: chatId,
      senderId: FirebaseService.currentUser!.uid,
      text: text,
    );
    _controller.clear();
  }
}
