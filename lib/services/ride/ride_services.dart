import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manzil_app_v3/widgets/vehicle_selection_dialog.dart';

class RidesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getRides(String userId) {
    return _firestore
        .collection('rides')
        .where('passengerID', isNotEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> rides = [];

      for (var document in querySnapshot.docs) {
        final acceptedByDoc = await _firestore
            .collection('rides')
            .doc(document.id)
            .collection('acceptedBy')
            .doc(userId)
            .get();

        if (!acceptedByDoc.exists) {
          final doc = document.data();
          rides.add({
            'id': document.id,
            'passengerName': doc['passengerName'],
            'passengerID': doc['passengerID'],
            'passengerNumber': doc['passengerNumber'],
            'pickupLocation': doc['pickupLocation'],
            'pickupCoordinates': doc['pickupCoordinates'],
            'destination': doc['destination'],
            'destinationCoordinates': doc['destinationCoordinates'],
            'seats': doc['seats'],
            'offeredFare': doc['offeredFare'],
            'paymentMethod': doc['paymentMethod'],
            'isPrivate': doc['isPrivate'],
            'status': doc['status'],
            'createdAt': doc['createdAt'],
          });
        }
      }

      rides.sort((a, b) =>
          (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));

      return rides;
    });
  }

  Future<bool> hasActiveRides(String driverId) async {
    try {
      final selectedRidesQuery = await _firestore
          .collection('rides')
          .where('selectedDriverId', isEqualTo: driverId)
          .where('status', whereIn: ['accepted', 'picked', 'paying'])
          .limit(1)
          .get();

      if (selectedRidesQuery.docs.isNotEmpty) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking active rides: $e');
      throw Exception('Failed to check active rides');
    }
  }

  Future<bool> hasPrivateRide(String driverId) async {
    try {
      final driverRidesQuery = await _firestore
          .collection('rides')
          .where('selectedDriverId', isEqualTo: driverId)
          .where('status', whereIn: ['accepted', 'picked', 'paying']).get();

      return driverRidesQuery.docs.any((doc) {
        final data = doc.data();
        return data['isPrivate'] == true;
      });
    } catch (e) {
      print('Error checking private rides: $e');
      throw Exception('Failed to check private rides');
    }
  }

  Future<Map<String, dynamic>> validateDriverDocuments(String driverId) async {
    final driverDoc = await _firestore.collection('users').doc(driverId).get();
    final driverData = driverDoc.data() as Map<String, dynamic>;

    if (!driverData.containsKey('cnic') ||
        !driverData.containsKey('drivingLicense')) {
      return {
        'isValid': false,
        'needsSetup': true,
        'message': 'Please complete your driver setup first'
      };
    }

    final cnicExpiry = (driverData['cnicExpiry'] as Timestamp).toDate();
    final licenseExpiry = (driverData['licenseExpiry'] as Timestamp).toDate();
    final now = DateTime.now();

    // if (cnicExpiry.isBefore(now)) {
    //   return {
    //     'isValid': false,
    //     'needsSetup': false,
    //     'message': 'Your CNIC has expired. Please update your documents.'
    //   };
    // }
    //
    // if (licenseExpiry.isBefore(now)) {
    //   return {
    //     'isValid': false,
    //     'needsSetup': false,
    //     'message': 'Your driving license has expired. Please update your documents.'
    //   };
    // }

    bool cnicExpired = cnicExpiry.isBefore(now);
    bool licenseExpired = licenseExpiry.isBefore(now);

    if (cnicExpired || licenseExpired) {
      return {
        'isValid': false,
        'needsSetup': false,
        'cnicExpired': cnicExpired,
        'licenseExpired': licenseExpired,
        'currentData': {
          'cnic': driverData['cnic'],
          'cnicExpiry': cnicExpiry,
          'drivingLicense': driverData['drivingLicense'],
          'licenseExpiry': licenseExpiry,
        },
        'message': 'Documents need to be updated'
      };
    }

    return {'isValid': true};
  }

  Future<Map<String, dynamic>> getDriverVehicles(String driverId) async {
    final validation = await validateDriverDocuments(driverId);
    if (!validation['isValid']) {
      throw validation;
    }

    final vehiclesSnapshot = await _firestore
        .collection('users')
        .doc(driverId)
        .collection('vehicles')
        .get();
    if (vehiclesSnapshot.docs.isEmpty) {
      throw Exception(
          'No vehicles found. Please set up your vehicle information first.');
    }

    final vehicles = vehiclesSnapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();

    return {
      'vehicles': vehicles,
      'needsSelection': vehicles.length > 1,
    };
  }

  Future<void> acceptRide(String rideId, Map<String, dynamic> driverInfo,
      Map<String, dynamic>? selectedVehicle) async {
    try {
      // First validate driver documents
      final validation = await validateDriverDocuments(driverInfo['uid']);
      if (!validation['isValid']) {
        throw validation;
      }
      if (selectedVehicle == null) {
        throw Exception('Vehicle information is required');
      }

      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      final controlsDoc = await _firestore.collection('controls').get();

      if (!rideDoc.exists) {
        throw Exception('Ride not found');
      }

      final rideData = rideDoc.data() as Map<String, dynamic>;
      final controlData = controlsDoc.docs.first.data();
      final isPrivate = rideData['isPrivate'] as bool;

      if (isPrivate) {
        final hasActive = await hasActiveRides(driverInfo['uid']);
        if (hasActive) {
          throw Exception(
              'You cannot accept this ride as you already have an active ride. And the ride you are going to accept is private.');
        }
      }

      final hasPrivateRides = await hasPrivateRide(driverInfo['uid']);
      if (hasPrivateRides) {
        throw Exception(
            'You cannot accept this ride as you already have an private ride.');
      }

      final driverCoordinates = driverInfo['coordinates'] as List;
      final pickupCoordinates = rideData['pickupCoordinates'] as List;
      final destinationCoordinates = rideData['destinationCoordinates'] as List;

      final distanceFromPassenger = await Geolocator.distanceBetween(
          driverCoordinates[0],
          driverCoordinates[1],
          pickupCoordinates[0],
          pickupCoordinates[1]);

      final distanceFromDestination = await Geolocator.distanceBetween(
          driverCoordinates[0],
          driverCoordinates[1],
          destinationCoordinates[0],
          destinationCoordinates[1]);

      final petrolRate = controlData['petrolRate'] as double;
      final vehicleLitersPerMeter = selectedVehicle['litersPerMeter'] as double;
      int calculatedFare;

      if (isPrivate) {
        calculatedFare =
            ((vehicleLitersPerMeter * petrolRate * distanceFromDestination) *
                    2.5)
                .ceil();
      } else {
        calculatedFare =
            (vehicleLitersPerMeter * petrolRate * distanceFromDestination)
                .ceil();
      }

      await _firestore
          .collection('rides')
          .doc(rideId)
          .collection('acceptedBy')
          .doc(driverInfo['uid'])
          .set({
        'driverName': "${driverInfo['first_name']} ${driverInfo['last_name']}",
        'driverNumber': driverInfo['phone_number'],
        'driverRatings': driverInfo['overallRating'] ?? 0,
        'driverLocation': driverInfo['location_text'],
        'driverCoordinates': driverCoordinates,
        'distanceFromPassenger': distanceFromPassenger,
        'calculatedFare': calculatedFare,
        'driverDistanceFromDestination': distanceFromDestination,
        'timestamp': Timestamp.now(),
        // 'vehicleId': selectedVehicle['id'],
        'vehicleMake': selectedVehicle['make'],
        'vehicleModel': selectedVehicle['model'],
        'vehicleNumber': selectedVehicle['number'],
        'vehicleCategory': selectedVehicle['category'],
        'litersPerMeter': selectedVehicle['litersPerMeter'],
      });
    } catch (e) {
      if (e is Map) {
        throw e;
      } else {
        throw Exception(e.toString());
      }
    }
  }

  Stream<List<Map<String, dynamic>>> getAcceptedRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('status', whereIn: ['pending', 'accepted'])
        .snapshots()
        .asyncMap((querySnapshot) async {
          List<Map<String, dynamic>> acceptedRides = [];

          for (var document in querySnapshot.docs) {
            final acceptedByDoc = await _firestore
                .collection('rides')
                .doc(document.id)
                .collection('acceptedBy')
                .doc(driverId)
                .get();

            if (acceptedByDoc.exists) {
              final doc = document.data();
              final acceptedData = acceptedByDoc.data() ?? {};

              acceptedRides.add({
                'id': document.id,
                'passengerName': doc['passengerName'],
                'passengerID': doc['passengerID'],
                'passengerNumber': doc['passengerNumber'],
                'pickupLocation': doc['pickupLocation'],
                'destination': doc['destination'],
                'seats': doc['seats'],
                'offeredFare': doc['offeredFare'],
                'paymentMethod': doc['paymentMethod'],
                'isPrivate': doc['isPrivate'],
                'status': doc['status'],
                'calculatedFare': acceptedData['calculatedFare'],
                'distanceFromPassenger': acceptedData['distanceFromPassenger'],
                'acceptedAt': acceptedData['timestamp'],
              });
            }
          }

          // here it sorts by acceptance time, newest first
          acceptedRides.sort((a, b) => (b['acceptedAt'] as Timestamp)
              .compareTo(a['acceptedAt'] as Timestamp));

          return acceptedRides;
        });
  }

  Stream<List<Map<String, dynamic>>> getActiveRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('selectedDriverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  Future<void> cancelRide(String rideId, {String? reason}) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': 'cancelled',
      'cancelReason': reason ?? 'Cancelled by user',
      'cancelledAt': Timestamp.now(),
    });
  }

  Future<void> addRatingAndUpdateDriver(
      {required String rideId,
      required String driverId,
      required double rating}) async {
    try {
      final batch = _firestore.batch();

      final rideRef = _firestore.collection('rides').doc(rideId);
      batch.update(rideRef, {
        'rating': rating,
      });

      final driverRidesQuery = await _firestore
          .collection('rides')
          .where('selectedDriverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRating = rating;
      int ratingCount = 1;

      for (var doc in driverRidesQuery.docs) {
        final data = doc.data();
        if (data['rating'] != null) {
          totalRating += data['rating'];
          ratingCount++;
        }
      }

      final averageRating = totalRating / ratingCount;

      final driverRef = _firestore.collection('users').doc(driverId);
      batch.update(driverRef, {
        'overallRating': averageRating,
        // 'totalRatings': ratingCount,
      });

      await batch.commit();
    } catch (e) {
      print('Error adding rating: $e');
      throw Exception('Failed to add rating');
    }
  }
}
