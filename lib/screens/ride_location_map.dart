import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RideLocationsMap extends ConsumerStatefulWidget {
  final List pickupCoordinates;
  final List destinationCoordinates;
  final String pickupLocation;
  final String destination;

  const RideLocationsMap({
    required this.pickupCoordinates,
    required this.destinationCoordinates,
    required this.pickupLocation,
    required this.destination,
    super.key,
  });

  @override
  ConsumerState<RideLocationsMap> createState() => _RideLocationsMapState();
}

class _RideLocationsMapState extends ConsumerState<RideLocationsMap> {
  LatLng? currentLocation;
  final mapController = MapController();
  double? distanceToPickup;
  double? pickupToDestination;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      if (!mounted) return;

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });

      _calculateDistances();

      // this center maps so that user can see all markers in one frame.
      _fitAllMarkers();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _calculateDistances() {
    if (currentLocation == null) return;

    distanceToPickup = Geolocator.distanceBetween(
      currentLocation!.latitude,
      currentLocation!.longitude,
      widget.pickupCoordinates[0],
      widget.pickupCoordinates[1],
    ) / 1000;

    pickupToDestination = Geolocator.distanceBetween(
      widget.pickupCoordinates[0],
      widget.pickupCoordinates[1],
      widget.destinationCoordinates[0],
      widget.destinationCoordinates[1],
    ) / 1000; // this convert distance from meters to km

    setState(() {});
  }

  void _fitAllMarkers() {
    if (currentLocation == null) return;

    final points = [
      currentLocation!,
      LatLng(widget.pickupCoordinates[0], widget.pickupCoordinates[1]),
      LatLng(widget.destinationCoordinates[0], widget.destinationCoordinates[1]),
    ];

    mapController.fitCamera(CameraFit.coordinates(
      coordinates: points,
      padding: const EdgeInsets.all(50),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Locations')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(
                widget.pickupCoordinates[0],
                widget.pickupCoordinates[1],
              ),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileProvider: CancellableNetworkTileProvider(),
                userAgentPackageName: 'com.example.manzil_app',
              ),
              MarkerLayer(
                markers: [
                  if (currentLocation != null)
                    Marker(
                      point: currentLocation!,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Icon(
                            Icons.my_location,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
                          Text(
                            'You',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Marker(
                    point: LatLng(
                      widget.pickupCoordinates[0],
                      widget.pickupCoordinates[1],
                    ),
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color.fromARGB(255, 255, 170, 42),
                          size: 30,
                        ),
                        Text(
                          'Pickup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 170, 42),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Marker(
                    point: LatLng(
                      widget.destinationCoordinates[0],
                      widget.destinationCoordinates[1],
                    ),
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(
                          Icons.flag,
                          color: Color.fromARGB(255, 255, 107, 74),
                          size: 30,
                        ),
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 107, 74),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (distanceToPickup != null && pickupToDestination != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Distance to pickup',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${distanceToPickup!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.map,
                            color: Color.fromARGB(255, 255, 170, 42),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trip distance',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${pickupToDestination!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fitAllMarkers,
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}