import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import 'package:manzil_app_v3/providers/booking_inputs_provider.dart';
import 'package:manzil_app_v3/providers/rides_filter_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen(this.origin, {super.key});
  final String origin;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? currentLocation;
  LatLng? markerPosition;
  String? selectedAddress;
  final mapController = MapController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeFromProvider();
  }

  void _initializeFromProvider() {
    List<double>? coordinates;
    String? address;

    switch (widget.origin) {
      case 'pickup':
        final bookingData = ref.read(bookingInputsProvider);
        final pickupCoords = bookingData['pickupCoordinates'] as List?;
        if (pickupCoords != null && pickupCoords.isNotEmpty) {
          coordinates = [
            pickupCoords[0].toDouble(),
            pickupCoords[1].toDouble()
          ];
          address = bookingData['pickup'] as String?;
        }
        break;

      case 'passengerDestination':
        final bookingData = ref.read(bookingInputsProvider);
        final destCoords = bookingData['destinationCoordinates'] as List?;
        if (destCoords != null && destCoords.isNotEmpty) {
          coordinates = [
            destCoords[0].toDouble(),
            destCoords[1].toDouble()
          ];
          address = bookingData['destination'] as String?;
        }
        break;

      case 'driverDestination':
        final filterData = ref.read(ridesFilterProvider);
        final coords = filterData['coordinates'] as List?;
        if (coords != null && coords.isNotEmpty) {
          coordinates = [
            coords[0].toDouble(),
            coords[1].toDouble()
          ];
          address = filterData['destination'] as String?;
        }
        break;
    }

    if (coordinates != null) {
      setState(() {
        markerPosition = LatLng(coordinates![0], coordinates[1]);
        selectedAddress = address;

        // if user places a marker move to that marker
        Future.microtask(() {
          mapController.move(markerPosition!, 15);
        });
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);

        if (markerPosition == null) {
          mapController.move(currentLocation!, 15); // will go to current location
        }
      });
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting location: $e'))
        );
      }
    }
  }

  Future<String> _getAddressFromCoordinates(LatLng coordinates) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&accept-language=en-US&lat=${coordinates.latitude}&lon=${coordinates.longitude}&zoom=18&addressdetails=1'
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

  String get _screenTitle {
    switch (widget.origin) {
      case 'pickup':
        return 'Select Pickup Location';
      case 'passengerDestination':
      case 'driverDestination':
        return 'Select Destination';
      default:
        return 'Select Location';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
        actions: [
          if (markerPosition != null && selectedAddress != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'address': selectedAddress,
                  'coordinates': [
                    markerPosition!.latitude,
                    markerPosition!.longitude,
                  ],
                });
              },
              child: const Text('Done'),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLocation ?? const LatLng(0, 0),
              initialZoom: 15,
              onTap: (tapPosition, point) async {
                setState(() {
                  markerPosition = point;
                  _isLoading = true;
                });

                try {
                  final address = await _getAddressFromCoordinates(point);
                  setState(() {
                    selectedAddress = address;
                    _isLoading = false;
                  });
                } catch (e) {
                  setState(() {
                    _isLoading = false;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error getting address: $e'))
                    );
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileProvider: CancellableNetworkTileProvider(),
                userAgentPackageName: 'com.example.manzil_app',
              ),
              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.my_location,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              if (markerPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: markerPosition!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Color.fromARGB(255, 255, 107, 74),
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 40,
            child: FloatingActionButton(
              child: const Icon(Icons.gps_fixed),
              onPressed: () {
                if (currentLocation != null) {
                  mapController.move(currentLocation!, 15);
                }
              },
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (selectedAddress != null && !_isLoading)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    selectedAddress!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}