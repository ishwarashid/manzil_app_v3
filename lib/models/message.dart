import 'package:cloud_firestore/cloud_firestore.dart';

class Message {

  Message({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp
  });

  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "sender_name": senderName,
      "receiverId": receiverId,
      "message": message,
      "timestamp": timestamp
    };
  }

}