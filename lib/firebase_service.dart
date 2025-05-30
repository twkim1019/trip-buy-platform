// lib/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  /// Firebase Authentication instance
  static final FirebaseAuth auth = FirebaseAuth.instance;

  /// 현재 로그인된 사용자 반환 (로그인 전엔 null)
  static User? get currentUser => auth.currentUser;

  /// Firebase Firestore instance
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// 사용자 프로필 저장 또는 업데이트
  /// 컬렉션: users, 문서 ID: userId
  static Future<void> saveUserProfile({
    required String userId,
    required String nickname,
    String? photoUrl,
  }) {
    return firestore
        .collection('users')
        .doc(userId)
        .set({
          'nickname': nickname,
          'photoUrl': photoUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// 사용자 프로필 스트림 (실시간 업데이트)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(
      String userId) {
    return firestore.collection('users').doc(userId).snapshots();
  }

  /// 여행 일정 저장
  static Future<void> saveTrip({
    required String userId,
    required String country,
    required DateTime start,
    required DateTime end,
  }) {
    final now = DateTime.now();
    return firestore.collection('trips').add({
      'userId': userId,
      'country': country,
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'createdAt': Timestamp.fromDate(now),
    });
  }

  /// 특정 사용자의 여행 일정 스트림
  static Stream<QuerySnapshot<Map<String, dynamic>>> tripsForUser(
      String userId) {
    return firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 여행 일정 삭제
  static Future<void> deleteTrip(String docId) {
    return firestore.collection('trips').doc(docId).delete();
  }

  /// 구매 요청 저장
  static Future<void> saveRequest({
    required String userId,
    required String tripId,
    required String country,
    required String item,
    required int quantity,
    String? notes,
  }) {
    final now = DateTime.now();
    return firestore.collection('requests').add({
      'userId': userId,
      'tripId': tripId,
      'country': country,
      'item': item,
      'quantity': quantity,
      'notes': notes ?? '',
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
    });
  }

  /// 특정 여행의 요청 스트림
  static Stream<QuerySnapshot<Map<String, dynamic>>> requestsForTrip(
      String tripId) {
    return firestore
        .collection('requests')
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 특정 사용자의 모든 요청 스트림
  static Stream<QuerySnapshot<Map<String, dynamic>>> requestsForUser(
      String userId) {
    return firestore
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 두 UID를 알파벳 순으로 결합해 채팅방 ID 생성
  static String chatIdFor(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// 채팅 메시지 전송
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> deleteRequest(String reqId) {
  return firestore.collection('requests').doc(reqId).delete();
}
  /// 채팅 메시지 실시간 스트림
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(
      String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}

