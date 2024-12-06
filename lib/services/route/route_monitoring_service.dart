import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class RouteMonitoringService extends StateNotifier<Map<String, dynamic>> {
  final Function(BuildContext) showEmergencyDialog;
  BuildContext? context;

  RouteMonitoringService(this.showEmergencyDialog) : super({
    'isMonitoring': false,
    'lastDistances': <String, Map<String, dynamic>>{},
    'deviationTimers': <String, Timer>{},
    'monitoredRides': <String>{},
    'currentRideIndex': 0,
    'lastEmergencyTimes': <String, DateTime>{}, // Track when last emergency was reported for each ride
  });

  void setContext(BuildContext context) {
    this.context = context;
  }

  Timer? _monitoringTimer;
  static const deviationThreshold = Duration(seconds: 10); // 10 mins after testing
  static const distanceCheckInterval = Duration(seconds: 5); // 2 mins after testing
  static const deviationBuffer = 50.0;
  static const emergencyCooldown = Duration(seconds: 10); // 5 mins after testing

  void startMonitoring(List<Map<String, dynamic>> rides, Position currentPosition) {

    final currentDeviationTimers = Map<String, Timer>.from(state['deviationTimers'] as Map);
    currentDeviationTimers.forEach((_, timer) => timer.cancel());

    state = {
      ...state,
      'isMonitoring': true,
      'deviationTimers': <String, Timer>{},
    };

    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      distanceCheckInterval,
          (_) => checkRouteDeviation(rides, currentPosition),
    );

    checkRouteDeviation(rides, currentPosition);
  }

  void stopMonitoring() {
    print('Stopping route monitoring...');
    _monitoringTimer?.cancel();
    (state['deviationTimers'] as Map<String, Timer>).forEach((_, timer) => timer.cancel());

    state = {
      'isMonitoring': false,
      'lastDistances': <String, Map<String, dynamic>>{},
      'deviationTimers': <String, Timer>{},
      'monitoredRides': <String>{},
      'currentRideIndex': 0,
      'lastEmergencyTimes': <String, DateTime>{},
    };
  }

  Future<void> checkRouteDeviation(
      List<Map<String, dynamic>> rides,
      Position currentPosition
      ) async {
    final pickedRides = rides.where((ride) => ride['status'] == 'picked').toList();

    print('Checking route deviation - Picked rides: ${pickedRides.length}/${rides.length}');

    if (pickedRides.isEmpty || pickedRides.length != rides.length) {
      print('Not all rides are picked, skipping route check');
      return;
    }

    final currentRideIndex = state['currentRideIndex'] as int;
    if (currentRideIndex >= pickedRides.length) {
      print('All rides monitored, resetting to first ride');
      state = {...state, 'currentRideIndex': 0};
      return;
    }

    final currentRide = pickedRides[currentRideIndex];
    final rideId = currentRide['id'] as String;
    final destCoords = currentRide['destinationCoordinates'] as List;
    final passengerId = currentRide['passengerID'] as String;

    print('Monitoring ride $rideId (index: $currentRideIndex)');

    final lastDistances = Map<String, Map<String, dynamic>>.from(state['lastDistances'] as Map);
    final deviationTimers = Map<String, Timer>.from(state['deviationTimers'] as Map);
    final monitoredRides = Set<String>.from(state['monitoredRides'] as Set);
    final lastEmergencyTimes = Map<String, DateTime>.from(state['lastEmergencyTimes'] as Map);

    final currentDistance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      destCoords[0],
      destCoords[1],
    );

    print('Current distance to destination: $currentDistance meters');

    if (!monitoredRides.contains(rideId)) {
      print('First time monitoring ride: $rideId');
      monitoredRides.add(rideId);
      lastDistances[rideId] = {
        'distance': currentDistance,
        'timestamp': DateTime.now(),
      };
    } else {
      final lastDistance = lastDistances[rideId]?['distance'] as double?;
      if (lastDistance != null) {
        final distanceIncrease = currentDistance - lastDistance;
        print('Distance change for ride $rideId: $distanceIncrease meters');

        if (distanceIncrease > deviationBuffer) {
          print('Route deviation detected! Starting/checking timer');

          final lastEmergencyTime = lastEmergencyTimes[rideId];
          final canReportEmergency = lastEmergencyTime == null ||
              DateTime.now().difference(lastEmergencyTime) > emergencyCooldown;

          if (canReportEmergency && deviationTimers[rideId] == null) {
            print('Starting new deviation timer');
            deviationTimers[rideId] = Timer(deviationThreshold, () {
              print('Timer completed - reporting deviation');
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await _reportRouteDeviation(rideId, passengerId);
                if (mounted) {

                  final updatedEmergencyTimes = Map<String, DateTime>.from(state['lastEmergencyTimes'] as Map);
                  updatedEmergencyTimes[rideId] = DateTime.now();
                  state = {...state, 'lastEmergencyTimes': updatedEmergencyTimes};
                }
              });
              deviationTimers.remove(rideId);
            });
          } else {
            print('Skipping emergency report - cooldown period active or timer already running');
          }
        } else if (distanceIncrease < 0) {
          print('Distance decreasing, canceling timer if exists');
          deviationTimers[rideId]?.cancel();
          deviationTimers.remove(rideId);
        }
      }

      lastDistances[rideId] = {
        'distance': currentDistance,
        'timestamp': DateTime.now(),
      };
    }

    state = {
      ...state,
      'lastDistances': lastDistances,
      'deviationTimers': deviationTimers,
      'monitoredRides': monitoredRides,
      'lastEmergencyTimes': lastEmergencyTimes,
    };
  }

  Future<void> _reportRouteDeviation(String rideId, String passengerId) async {
    if (!mounted) return;

    try {
      print('REPORTING EMERGENCY - Ride: $rideId, Passenger: $passengerId');

      if (context != null && mounted) {
        showEmergencyDialog(context!);
      }

      await FirebaseFirestore.instance.collection('emergencies').add({
        'pushedBy': passengerId,
        'rideId': rideId,
        'reason': 'route deviation',
        'timestamp': Timestamp.now(),
      });

    } catch (e) {
      print('Error reporting route deviation: $e');
    }
  }
}

final routeMonitoringProvider = StateNotifierProvider<RouteMonitoringService, Map<String, dynamic>>((ref) {
  return RouteMonitoringService((context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });

        return const AlertDialog(
          title: Text(
            "Emergency Alert Sent!",
            style: TextStyle(fontSize: 20),
          ),
          icon: Icon(
            Icons.emergency_share_rounded,
            size: 30,
          ),
          iconColor: Colors.redAccent,
        );
      },
    );
  });
});