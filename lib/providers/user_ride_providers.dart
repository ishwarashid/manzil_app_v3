import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRideStatus {
  final bool isDriver;
  final bool hasPrivateRide;
  final List<Map<String, dynamic>> activeRides;
  final List<Map<String, dynamic>> activeRidesWithCompleted;

  UserRideStatus({
    required this.isDriver,
    required this.hasPrivateRide,
    required this.activeRides,
    required this.activeRidesWithCompleted,
  });
}

final userRideStatusProvider =
    StreamProvider.autoDispose.family<UserRideStatus, String>((ref, userId) {
  final firestore = FirebaseFirestore.instance;
  return firestore.collection('rides').snapshots().map((snapshot) {

    // this checks if user is a driver (has any accepted rides as driver)
    final driverRides = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['selectedDriverId'] == userId &&
          (data['status'] == 'accepted' || data['status'] == 'picked');
    }).toList();

    final isDriver = driverRides.isNotEmpty;

    // this checks for private rides if user is a driver
    final hasPrivateRide = isDriver &&
        snapshot.docs.any((doc) {
          final data = doc.data();
          return data['selectedDriverId'] == userId &&
              data['status'] == 'accepted' &&
              data['isPrivate'] == true;
        });

    // this gets active rides based on user type
    final activeRides = snapshot.docs
        .where((doc) {
          final data = doc.data();
          if (isDriver) {
            return data['selectedDriverId'] == userId &&
                (data['status'] == 'accepted' ||
                    data['status'] == 'picked' ||
                    data['status'] == 'paying');
          } else {

            return data['passengerID'] == userId &&
                (data['status'] == 'pending' ||
                    data['status'] == 'accepted' ||
                    data['status'] == 'picked' ||
                    data['status'] == 'paying');
          }
        })
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();

    final activeRidesWithCompleted = snapshot.docs
        .where((doc) {
          final data = doc.data();
          if (isDriver) {
            return data['selectedDriverId'] == userId &&
                (data['status'] == 'accepted' ||
                    data['status'] == 'picked' ||
                    data['status'] == 'paying' ||
                    data['status'] == 'completed');
          } else {
            return data['passengerID'] == userId &&
                (data['status'] == 'pending' ||
                    data['status'] == 'accepted' ||
                    data['status'] == 'picked' ||
                    data['status'] == 'paying' ||
                    data['status'] == 'completed');
          }
        })
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();

    return UserRideStatus(
        isDriver: isDriver,
        hasPrivateRide: hasPrivateRide,
        activeRides: activeRides,
        activeRidesWithCompleted: activeRidesWithCompleted);
  });
});

// provider to expose just the user type
final isDriverProvider =
    Provider.autoDispose.family<AsyncValue<bool>, String>((ref, userId) {
  final userRideStatus = ref.watch(userRideStatusProvider(userId));
  return userRideStatus.when(
    data: (status) => AsyncData(status.isDriver),
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

// provider to expose private ride status
final hasPrivateRideProvider =
    Provider.autoDispose.family<AsyncValue<bool>, String>((ref, userId) {
  final userRideStatus = ref.watch(userRideStatusProvider(userId));
  return userRideStatus.when(
    data: (status) => AsyncData(status.hasPrivateRide),
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

// provider to expose active rides
final activeRidesProvider = Provider.autoDispose
    .family<AsyncValue<List<Map<String, dynamic>>>, String>((ref, userId) {
  final userRideStatus = ref.watch(userRideStatusProvider(userId));
  return userRideStatus.when(
    data: (status) => AsyncData(status.activeRides),
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

// provider to expose active rides with completed rides also
final activeRidesWithCompletedProvider = Provider.autoDispose
    .family<AsyncValue<List<Map<String, dynamic>>>, String>((ref, userId) {
  final userRideStatus = ref.watch(userRideStatusProvider(userId));
  return userRideStatus.when(
    data: (status) => AsyncData(status.activeRides),
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});
