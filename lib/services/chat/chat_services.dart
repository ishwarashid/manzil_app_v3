import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v3/models/message.dart';

class ChatService {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream(Map<String, dynamic> currentUser) {
    final currentUserId = currentUser['uid'];

    return FirebaseFirestore.instance
        .collection("chat_rooms")
        .where("users", arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> users = [];

      for (var doc in snapshot.docs) {
        final chatRoom = doc.data();
        final usersInRoom = List<String>.from(chatRoom["users"]);

        final otherUserId = usersInRoom.firstWhere((userId) => userId != currentUserId);

        final otherUserRef = FirebaseFirestore.instance.collection("users").doc(otherUserId);

        final otherUserDoc = await otherUserRef.get();
        print(otherUserDoc);
        print(otherUserDoc.exists);

        if (otherUserDoc.exists) {
          final otherUserData = otherUserDoc.data() as Map<String, dynamic>;
          otherUserData["id"] = otherUserId;
          users.add(otherUserData);
        }
      }
      print(users);

      return users;
    });
  }



  // return FirebaseFirestore.instance.collection("chat_rooms").doc(chatRoomId)
  //     .collection("messages").orderBy("timestamp", descending: true)
  //     .snapshots();

  // Stream<List<Map<String, dynamic>>> getUsersStream(
  //     String userId, otherUserId) {
  //   List<String> ids = [userId, otherUserId];
  //   ids.sort();
  //   String chatRoomId = ids.join("_");
  //
  //   return _firebase
  //       .collection("chat_rooms")
  //       .doc(chatRoomId)
  //       .collection("messages")
  //       .where("senderId", whereIn: [userId, otherUserId])
  //       .where("receiverId", whereIn: [userId, otherUserId])
  //       .snapshots()
  //       .map((snapshot) {
  //         return snapshot.docs.map((doc) {
  //           final user = doc.data();
  //           user["id"] = doc.id;
  //           return user;
  //         }).toList();
  //       });
  // }

  // create chat room, will be empty
  Future<void> createChatRoom(Map<String, dynamic> currentUser, String receiverId) async {
    final currentUserId = currentUser['uid'];

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // checks if the chat room already exist
    final chatRoomRef =
    FirebaseFirestore.instance.collection("chat_rooms").doc(chatRoomId);

    // If not, then create
    final chatRoomDoc = await chatRoomRef.get();
    if (!chatRoomDoc.exists) {
      await chatRoomRef.set({
        "users": [currentUserId, receiverId],
      });
    }
  }

  // send message
  Future<void> sendMessage(Map<String, dynamic> currentUser, String receiverId,
      String message) async {
    final currentUserId = currentUser['uid'];
    final Timestamp timestamp = Timestamp.now();

    final fullName = currentUser["first_name"] + " " + currentUser["last_name"];

    Message newMessage = Message(
        senderId: currentUserId,
        senderName: fullName,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp);

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    final chatRoomRef =
        FirebaseFirestore.instance.collection("chat_rooms").doc(chatRoomId);

    final chatRoomDoc = await chatRoomRef.get();
    if (!chatRoomDoc.exists) {
      await chatRoomRef.set({
        "users": [currentUserId, receiverId],
      });
    }

    await chatRoomRef.collection("messages").add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessages(String userId, otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
