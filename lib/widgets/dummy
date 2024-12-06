import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// here i also wanna add some route deviation logic
// when driver has picked up all the passengers (when status of all rides is picked)
// the distance of driver from destination of passenger(one by one) should be monitored after every 2 min
// its should be compared to distance 2 min ago
// if the distance increases a timer should start which after 10 mins should issue emergeny by making an entry
// inside emergencies collection (pushed by field will be the passenger's id, and reason  will be route deviation)
// but timer will be stopped if we check the distance again after 2 mins and it is decreasing.
// then same things will happen to other rides as well after current ride completes.

class DriverTrackingMap extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> rides;
  final String driverId;

  const DriverTrackingMap({
    required this.rides,
    required this.driverId,
    super.key,
  });

  @override
  ConsumerState<DriverTrackingMap> createState() => _DriverTrackingMapState();
}

class _DriverTrackingMapState extends ConsumerState<DriverTrackingMap> {
  final mapController = MapController();
  LatLng? currentLocation;
  Timer? _databaseUpdateTimer;
  StreamSubscription<Position>? _locationStreamSubscription;

  Timer? _routeMonitoringTimer;
  Map<String, double> _lastDistances = {};
  Map<String, Timer?> _deviationTimers = {};
  static const deviationThreshold = Duration(seconds: 20); // make it 10

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    _databaseUpdateTimer?.cancel();
    _routeMonitoringTimer?.cancel();
    // Cancel all deviation timers
    for (var timer in _deviationTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  void _startRouteMonitoring() {
    _routeMonitoringTimer = Timer.periodic(
      const Duration(seconds: 10),// make it minute: 2
          (_) => _checkRouteDeviation(),
    );
  }

  Future<void> _checkRouteDeviation() async {
    if (currentLocation == null) return;

    // Only monitor if all rides are picked
    final pickedRides = widget.rides.where((ride) => ride['status'] == 'picked').toList();
    if (pickedRides.length != widget.rides.length) return;

    for (final ride in pickedRides) {
      final rideId = ride['id'] as String;
      final destCoords = ride['destinationCoordinates'] as List;
      final passengerId = ride['passengerID'] as String;

      // Calculate current distance to destination
      final currentDistance = await Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        destCoords[0],
        destCoords[1],
      );

      // Get last recorded distance
      final lastDistance = _lastDistances[rideId];

      if (lastDistance != null) {
        // Check if distance is increasing (with small buffer for GPS accuracy)
        if (currentDistance > lastDistance + 50) { // 50 meters buffer
          // Start deviation timer if not already started
          _deviationTimers[rideId] ??= Timer(deviationThreshold, () {
            _reportRouteDeviation(rideId, passengerId);
          });
        } else if (currentDistance < lastDistance) {
          // Distance is decreasing, cancel deviation timer if exists
          _deviationTimers[rideId]?.cancel();
          _deviationTimers[rideId] = null;
        }
      }

      // Update last distance
      _lastDistances[rideId] = currentDistance;
    }
  }

  Future<void> _reportRouteDeviation(String rideId, String passengerId) async {
    try {
      await FirebaseFirestore.instance.collection('emergencies').add({
        'pushedBy': passengerId,
        'rideId': rideId,
        'reason': 'route deviation',
        'timestamp': Timestamp.now(),
      });

      // Clear timer after reporting
      _deviationTimers[rideId]?.cancel();
      _deviationTimers[rideId] = null;

      print('Route deviation emergency reported for ride: $rideId');
    } catch (e) {
      print('Error reporting route deviation: $e');
    }
  }

  void _startDatabaseUpdates() {
    _databaseUpdateTimer = Timer.periodic(
      const Duration(minutes: 2),
          (_) {
        _updateDriverLocationInDatabase();
        // Start route monitoring after location is updated
        _startRouteMonitoring();
      },
    );
  }

  Future<void> _checkAndRequestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    // Once we have permissions, initialize everything
    _initializeLocation();
    _startLocationStream();
    _startDatabaseUpdates();
  }

  Future<void> _initializeLocation() async {
    print('Initializing location...');
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      print('Got initial position: ${position.latitude}, ${position.longitude}');

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        print('Setting current location: $currentLocation');
        mapController.move(currentLocation!, 15);
      });
    } catch (e) {
      print('Error getting initial location: $e');
    }
  }

  void _startLocationStream() {
    print('Starting location stream...');
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
            (Position position) {
          print('New position from stream: ${position.latitude}, ${position.longitude}');
          setState(() {
            currentLocation = LatLng(position.latitude, position.longitude);
          });
        },
        onError: (e) {
          print('Error in location stream: $e');
        }
    );
  }

  Future<void> _updateDriverLocationInDatabase() async {
    if (currentLocation == null) return;

    try {
      // Only proceed with updates if there are accepted rides
      final acceptedRides = widget.rides.where((ride) => ride['status'] == 'accepted').toList();
      if (acceptedRides.isEmpty) return;

      final locationText = await _getAddressFromCoordinates(
          currentLocation!.latitude,
          currentLocation!.longitude
      );

      final batch = FirebaseFirestore.instance.batch();

      for (final ride in acceptedRides) {
        final acceptedByRef = FirebaseFirestore.instance
            .collection('rides')
            .doc(ride['id'])
            .collection('acceptedBy')
            .doc(widget.driverId);

        batch.update(acceptedByRef, {
          'driverLocation': locationText,
          'driverCoordinates': [currentLocation!.latitude, currentLocation!.longitude],
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error updating location in database: $e');
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&accept-language=en-US&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
    );

    final response = await http.get(
        url,
        headers: {'Accept': 'application/json'}
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'];
    } else {
      throw Exception('Failed to get address');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building map with current location: $currentLocation');
    print('Number of rides: ${widget.rides.length}');

    // Default to a specific location if no current location yet
    final center = currentLocation ?? const LatLng(24.8607, 67.0011);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: CancellableNetworkTileProvider(),
          userAgentPackageName: 'com.example.manzil_app',
        ),
        if (currentLocation != null || widget.rides.isNotEmpty)  // Only show MarkerLayer if we have markers
          MarkerLayer(
            markers: [
              // Current location marker
              if (currentLocation != null)
                Marker(
                  point: currentLocation!,
                  width: 80,
                  height: 80,
                  child: const Column(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: Colors.blue,
                        size: 30,
                      ),
                      Text(
                        'You',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // Ride markers
              ...widget.rides.expand((ride) {
                final markers = <Marker>[];
                print('Processing ride: ${ride['id']}');

                if (ride['status'] != 'picked' &&
                    ride['pickupCoordinates'] != null &&
                    (ride['pickupCoordinates'] as List).length >= 2) {
                  final pickupCoords = ride['pickupCoordinates'] as List;
                  markers.add(
                    Marker(
                      point: LatLng(pickupCoords[0], pickupCoords[1]),
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 30,
                          ),
                          Text(
                            '${ride['passengerName']} Pickup',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 10
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (ride['destinationCoordinates'] != null &&
                    (ride['destinationCoordinates'] as List).length >= 2) {
                  final destCoords = ride['destinationCoordinates'] as List;
                  markers.add(
                    Marker(
                      point: LatLng(destCoords[0], destCoords[1]),
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 30,
                          ),
                          Text(
                            '${ride['passengerName']} Dest.',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return markers;
              }),
            ],
          ),
      ],
    );
  }
}