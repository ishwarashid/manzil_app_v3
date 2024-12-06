import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:manzil_app_v3/services/route/route_monitoring_service.dart';

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
  StreamSubscription<Position>? _locationStreamSubscription;
  Timer? _databaseUpdateTimer;
  late bool _navigationMode;
  late int _pointerCount;
  late AlignOnUpdate _alignPositionOnUpdate;
  late AlignOnUpdate _alignDirectionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;
  late final StreamController<void> _alignDirectionStreamController;

  @override
  void initState() {
    super.initState();
    ref.read(routeMonitoringProvider.notifier).setContext(context);
    _checkAndRequestPermissions();
    _navigationMode = false;
    _pointerCount = 0;
    _alignPositionOnUpdate = AlignOnUpdate.never;
    _alignDirectionOnUpdate = AlignOnUpdate.never;
    _alignPositionStreamController = StreamController<double?>();
    _alignDirectionStreamController = StreamController<void>();
  }

  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    _databaseUpdateTimer?.cancel();
    _alignPositionStreamController.close();
    _alignDirectionStreamController.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(DriverTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (currentLocation != null && widget.rides != oldWidget.rides) {

      Future.microtask(() {
        if (!mounted) return;
        final position = Position(
          latitude: currentLocation!.latitude,
          longitude: currentLocation!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        ref.read(routeMonitoringProvider.notifier).startMonitoring(
          widget.rides,
          position,
        );
      });
    }
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

    _initializeLocation();
    _startLocationStream();
    _startDatabaseUpdates();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        mapController.move(currentLocation!, 15);
      });

      if (widget.rides.isNotEmpty) {
        ref.read(routeMonitoringProvider.notifier).startMonitoring(
          widget.rides,
          position,
        );
      }
    } catch (e) {
      print('Error getting initial location: $e');
    }
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) {
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
        });

        if (widget.rides.isNotEmpty) {
          ref.read(routeMonitoringProvider.notifier).startMonitoring(
            widget.rides,
            position,
          );
        }
      },
      onError: (e) => print('Location stream error: $e'),
    );
  }

  void _startDatabaseUpdates() {
    _databaseUpdateTimer = Timer.periodic(
      const Duration(seconds: 5), // 10 secs before testing  // 2 mins after testing
          (_) => _updateDriverLocationInDatabase(),
    );
  }

  Future<void> _updateDriverLocationInDatabase() async {
    if (currentLocation == null) return;

    try {

      final acceptedRides = widget.rides.where((ride) => ride['status'] == 'accepted').toList();
      if (acceptedRides.isEmpty) return;

      final locationText = await _getAddressFromCoordinates(
          currentLocation!.latitude,
          currentLocation!.longitude
      );

      final batch = FirebaseFirestore.instance.batch();

      for (final ride in acceptedRides) {
        final rideRef = FirebaseFirestore.instance
            .collection('rides')
            .doc(ride['id']);

        batch.update(rideRef, {
          'driverLocation': locationText,
          'driverCoordinates': [currentLocation!.latitude, currentLocation!.longitude],
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      print('Successfully updated driver location for ${acceptedRides.length} rides');
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

    final center = currentLocation ?? const LatLng(24.8607, 67.0011);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        minZoom: 0,
        maxZoom: 19,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: CancellableNetworkTileProvider(),
          userAgentPackageName: 'com.example.manzil_app',
        ),
        CurrentLocationLayer(
          focalPoint: const FocalPoint(
            ratio: Point(0.0, 0.0),
            offset: Point(0.0, 0.0),
          ),
          alignPositionStream: _alignPositionStreamController.stream,
          alignDirectionStream: _alignDirectionStreamController.stream,
          alignPositionOnUpdate: _alignPositionOnUpdate,
          alignDirectionOnUpdate: _alignDirectionOnUpdate,
          style: LocationMarkerStyle(
            headingSectorColor: Theme.of(context).primaryColor,
            marker: DefaultLocationMarker(
              color: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.navigation,
                color: Colors.white,
              ),
            ),
            markerSize: const Size(40, 40),
            markerDirection: MarkerDirection.heading,
          ),
        ),
        if (widget.rides.isNotEmpty)
          MarkerLayer(
            markers: [
              ...widget.rides.expand((ride) {
                final markers = <Marker>[];
                print('Processing ride: ${ride['id']}');

                if (ride['status'] != 'picked' &&
                    ride['pickupCoordinates'] != null &&
                    (ride['pickupCoordinates'] as List).length >= 2) {
                  print(ride['status']);
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
                            color: Color.fromARGB(255, 255, 170, 42),
                            size: 30,
                          ),
                          Text(
                            '${ride['passengerName']} Pickup',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 170, 42),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
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
                            color: Color.fromARGB(255, 255, 107, 74),
                            size: 30,
                          ),
                          Text(
                            '${ride['passengerName']} Dest.',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color.fromARGB(255, 255, 107, 74),
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
        Positioned(
          bottom: 260,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: _navigationMode ? Theme.of(context).primaryColor : Colors.grey,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: () {
              setState(
                    () {
                  _navigationMode = !_navigationMode;
                  _alignPositionOnUpdate = _navigationMode
                      ? AlignOnUpdate.always
                      : AlignOnUpdate.never;
                  _alignDirectionOnUpdate = _navigationMode
                      ? AlignOnUpdate.always
                      : AlignOnUpdate.never;
                },
              );
              if (_navigationMode) {
                _alignPositionStreamController.add(18);
                _alignDirectionStreamController.add(null);
              }
            },
            child: const Icon(
              Icons.navigation_outlined,
            ),
          ),
        ),
      ],
    );
  }

  void _onPointerDown(e, l) {
    _pointerCount++;
    setState(() {
      _alignPositionOnUpdate = AlignOnUpdate.never;
      _alignDirectionOnUpdate = AlignOnUpdate.never;
    });
  }

  void _onPointerUp(e, l) {
    if (--_pointerCount == 0 && _navigationMode) {
      setState(() {
        _alignPositionOnUpdate = AlignOnUpdate.always;
        _alignDirectionOnUpdate = AlignOnUpdate.always;
      });
      _alignPositionStreamController.add(18);
      _alignDirectionStreamController.add(null);
    }
  }
}


