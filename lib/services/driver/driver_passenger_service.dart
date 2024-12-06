import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manzil_app_v3/services/chat/chat_services.dart';
import 'package:manzil_app_v3/services/ride/ride_services.dart';

class DriverPassengerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final RidesService _ridesService = RidesService();

  Stream<Map<String, dynamic>?> getCurrentRide(String passengerId) {
    return _firestore
        .collection('rides')
        .where('passengerID', isEqualTo: passengerId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return {
        'id': doc.id,
        ...doc.data(),
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getAcceptedDrivers(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('acceptedBy')
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> acceptedDrivers = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final driverId = doc.id;

        // Check if driver has any active rides as a passenger
        final activeRidesQuery = await _firestore
            .collection('rides')
            .where('passengerID', isEqualTo: driverId)
            .where('status', whereNotIn: ['cancelled', 'completed'])
            .get();

        // Only include driver if they don't have any active rides as a passenger
        if (activeRidesQuery.docs.isEmpty) {
          acceptedDrivers.add({
            'driverId': driverId,
            'driverName': data['driverName'],
            'driverNumber': data['driverNumber'],
            'driverRatings': data['driverRatings'] ?? 0,
            'driverLocation': data['driverLocation'],
            'driverCoordinates': data['driverCoordinates'],
            'distanceFromPassenger': data['distanceFromPassenger'],
            'driverDistanceFromDestination': data['distanceFromPassenger'],
            'calculatedFare': data['calculatedFare'],
            'timestamp': data['timestamp'],
          });
        }
      }

      return acceptedDrivers;
    });
  }

  Future<void> acceptDriver({
    required String rideId,
    required Map<String, dynamic> currentUser,
    required Map<String, dynamic> driverInfo,
  }) async {
    try {
      // First check if ride exists and is private
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data() as Map<String, dynamic>;
      final isPrivate = rideData['isPrivate'] as bool;

      if (isPrivate) {
        final hasActive = await _ridesService.hasActiveRides(driverInfo['driverId']);
        if(hasActive) {
          throw Exception(
              'Cannot accept this driver as they already have an active ride.'
          );
        }
      }

      final hasPrivateRides = await _ridesService.hasPrivateRide(driverInfo['driverId']);
      if (hasPrivateRides) {
        throw Exception(
            'You cannot accept this driver as they already have an private ride.'
        );
      }

      // Update the main ride document
      final rideRef = _firestore.collection('rides').doc(rideId);
      await rideRef.update({
        'status': 'accepted',
        'selectedDriverId': driverInfo['driverId'],
        'driverNumber': driverInfo['driverNumber'],
        'driverRatings': driverInfo['driverRatings'] ?? 0,
        'driverName': driverInfo['driverName'],
        'passengerNumber': ['passengerNumber'],
        'driverLocation': driverInfo['driverLocation'],
        'driverCoordinates': driverInfo['driverCoordinates'],
        'distanceFromPassenger': driverInfo['distanceFromPassenger'],
        'driverDistanceFromDestination': driverInfo['driverDistanceFromDestination'],
        'calculatedFare': driverInfo['calculatedFare'],
        'acceptedAt': Timestamp.now(),
      });

      // Create chat room
      await _chatService.createChatRoom(currentUser, driverInfo['driverId']);

      // Cancel other drivers
      // await _cancelOtherDrivers(rideId, driverInfo['driverId']);

    } catch (e) {
      print('Error accepting driver: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> _cancelOtherDrivers(String rideId, String acceptedDriverId) async {
    try {
      final acceptedByRef = _firestore
          .collection('rides')
          .doc(rideId)
          .collection('acceptedBy');

      final snapshot = await acceptedByRef.get();

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        if (doc.id != acceptedDriverId) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error canceling other drivers: $e');
      throw Exception('Failed to cancel other drivers');
    }
  }
}