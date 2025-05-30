// lib/firebase_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  /// Firebase Authentication instance
  static final FirebaseAuth auth = FirebaseAuth.instance;

  /// Firebase Firestore instance
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Firebase Storage instance
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // ── Authentication ──

  static User? get currentUser => auth.currentUser;

  // ── User Profile ──

  /// 저장·업데이트: users/{userId}
  static Future<void> updateProfile({
    required String userId,
    String? nickname,
    String? photoUrl,
  }) {
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    data['updatedAt'] = FieldValue.serverTimestamp();
    return firestore
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  /// 실시간 구독
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(
      String userId) {
    return firestore.collection('users').doc(userId).snapshots();
  }

  /// 프로필 이미지 업로드 → 다운로드 URL 반환
  static Future<String> uploadProfileImage(String userId, File file) async {
    final ref = storage.ref().child('profiles/$userId.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  // ── Trips ──

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

  static Stream<QuerySnapshot<Map<String, dynamic>>> tripsForUser(
      String userId) {
    return firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> deleteTrip(String docId) {
    return firestore.collection('trips').doc(docId).delete();
  }

  /// 모든 사용자 여행 일정 스트림
  static Stream<QuerySnapshot<Map<String, dynamic>>> allTrips() {
    return firestore
        .collection('trips')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 여행지 이미지 리스트 업로드 → URL 리스트 반환
  static Future<List<String>> uploadTripImages(
      String tripId, List<File> files) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final ref = storage
          .ref()
          .child('trips/$tripId/image_$i.jpg');
      await ref.putFile(files[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  // ── Requests ──

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

  static Stream<QuerySnapshot<Map<String, dynamic>>> requestsForTrip(
      String tripId) {
    return firestore
        .collection('requests')
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> requestsForUser(
      String userId) {
    return firestore
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> deleteRequest(String reqId) {
    return firestore.collection('requests').doc(reqId).delete();
  }

  // ── Chat ──

  /// 두 UID를 알파벳순으로 결합해 chatId 생성
  static String chatIdFor(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// 메시지 전송
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
  static Future<void> updateNickname({
    required String userId,
    required String nickname,
  }) {
    return firestore
      .collection('users')
      .doc(userId)
      .set({'nickname': nickname}, SetOptions(merge: true));
  }
  /// 메시지 스트림
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

