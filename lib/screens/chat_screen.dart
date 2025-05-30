// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherNickname;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherNickname,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final me = FirebaseService.currentUser!.uid;
    final chatId = FirebaseService.chatIdFor(me, widget.otherUserId);

    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.otherNickname}')),
      // 키보드 올라올 때 자동으로 body를 올려줌
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.streamMessages(chatId),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final msg = docs[i].data();
                    final isMe = msg['senderId'] == me;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(msg['text'] as String),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 입력창
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                0,
                8,
                MediaQuery.of(context).viewInsets.bottom + 40 + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration:
                          const InputDecoration(hintText: '메시지를 입력하세요'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      FirebaseService.sendMessage(
                        chatId: chatId,
                        senderId: me,
                        text: text,
                      );
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
