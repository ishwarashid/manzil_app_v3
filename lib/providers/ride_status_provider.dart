import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RideStatus {
  final List<Map<String, dynamic>> activeRidesWithCompleted;

  RideStatus({
    required this.activeRidesWithCompleted,
  });

  factory RideStatus.fromSnapshot(QuerySnapshot snapshot) {
    final rides = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        ...data,
        'id': doc.id,
      };
    }).toList();

    return RideStatus(
      activeRidesWithCompleted: rides,
    );
  }
}

final userRideStatusProvider = StreamProvider.family<RideStatus, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('rides')
      .where('passengerID', isEqualTo: userId)
      .where('status', whereIn: ['accepted', 'picked', 'paying', 'completed'])
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) => RideStatus.fromSnapshot(snapshot));
});