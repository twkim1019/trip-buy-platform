// lib/screens/chat_screen.dart

import 'dart:math';
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
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 현재 로그인된 사용자 UID
    final String me = FirebaseService.currentUser!.uid;
    // 두 UID를 알파벳 순으로 결합해 채팅방 ID 생성
    final String chatId = FirebaseService.chatIdFor(me, widget.otherUserId);

    // 실제 키보드 높이(viewInsets) + 하단 안전영역(padding) 중 더 큰 값을 bottom에 사용
    final double bottomInset   = MediaQuery.of(context).viewInsets.bottom;
    final double safePadding   = MediaQuery.of(context).padding.bottom;
    final double bottomPadding = max(bottomInset, safePadding);

    // 입력창(채팅 바)의 고정 높이 (원한다면 수정 가능)
    const double inputBarHeight = 56.0;

    return Scaffold(
      // Flutter가 키보드에 맞춰 전체 레이아웃을 밀어올리지 않도록 false 설정
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Chat with ${widget.otherNickname}'),
      ),
      body: Stack(
        children: [
          // ─────────────────────────────────────────────────────────────────────
          // 1) 메시지 목록 영역
          //    Stack 전체를 차지하되, 하단에 inputBarHeight + safePadding 만큼 빈 여백을 남겨 둡니다.
          //    (그래야 메시지 목록이 입력창 뒤로 가리지 않고, 드래그가 가능합니다.)
          Padding(
            padding: EdgeInsets.only(
              bottom: inputBarHeight + safePadding,
            ),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.streamMessages(chatId),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('아직 메시지가 없습니다.'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final msgData = docs[i].data();
                    final bool isMe = (msgData['senderId'] as String) == me;
                    final String text = msgData['text'] as String? ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ─────────────────────────────────────────────────────────────────────
          // 2) 입력창(채팅 바) 영역
          //    Positioned로 하단에 고정: bottom = 키보드 높이(viewInsets.bottom) OR 하단 안전영역(padding.bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding,
            height: inputBarHeight,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      cursorColor: Theme.of(context).primaryColor,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(chatId, me),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: () => _sendMessage(chatId, me),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 메시지 전송 메소드
  void _sendMessage(String chatId, String me) {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    FirebaseService.sendMessage(
      chatId: chatId,
      senderId: me,
      text: text,
    );
    _controller.clear();

    // 메시지 전송 후 스크롤을 맨 아래로 이동
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }
}
