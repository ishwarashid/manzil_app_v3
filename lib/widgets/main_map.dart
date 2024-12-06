import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/booking_inputs_provider.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';

class MainMap extends ConsumerStatefulWidget {
  const MainMap({super.key});

  @override
  ConsumerState<MainMap> createState() => _MainMapState();
}

class _MainMapState extends ConsumerState<MainMap> {

  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;

  @override
  void initState() {
    _alignPositionOnUpdate = AlignOnUpdate.always;
    _alignPositionStreamController = StreamController<double?>();
    super.initState();
  }

  @override
  void dispose() {
    _alignPositionStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final bookingInputs = ref.watch(bookingInputsProvider);

    final userCoordinates = currentUser['coordinates'] as List?;
    LatLng? currentLocation;
    if (userCoordinates != null && userCoordinates.length == 2) {
      currentLocation = LatLng(
        userCoordinates[0].toDouble(),
        userCoordinates[1].toDouble(),
      );
    }

    final pickupCoordinates = bookingInputs['pickupCoordinates'] as List?;
    LatLng? pickupLocation;
    if (pickupCoordinates != null && pickupCoordinates.length == 2) {
      pickupLocation = LatLng(
        pickupCoordinates[0].toDouble(),
        pickupCoordinates[1].toDouble(),
      );
    }

    final destinationCoordinates = bookingInputs['destinationCoordinates'] as List?;
    LatLng? destinationLocation;
    if (destinationCoordinates != null && destinationCoordinates.length == 2) {
      destinationLocation = LatLng(
        destinationCoordinates[0].toDouble(),
        destinationCoordinates[1].toDouble(),
      );
    }

    return currentLocation == null
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: CancellableNetworkTileProvider(),
          userAgentPackageName: 'com.example.manzil_app',
        ),
        CurrentLocationLayer(
          rotateAnimationCurve: Curves.easeInOut,
          alignPositionStream: _alignPositionStreamController.stream,
          alignPositionOnUpdate: _alignPositionOnUpdate,
          style: LocationMarkerStyle(
            headingSectorColor: Theme.of(context).primaryColor,
            marker: DefaultLocationMarker(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        MarkerLayer(
          markers: [
            if (pickupLocation != null &&
                (pickupLocation.latitude != currentLocation.latitude ||
                    pickupLocation.longitude != currentLocation.longitude))
              Marker(
                point: pickupLocation,
                width: 80,
                height: 80,
                child: const Column(
                  children: [
                    Icon(
                      Icons.trip_origin,
                      color: Colors.green,
                      size: 30,
                    ),
                    Text(
                      'Pickup',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            if (destinationLocation != null)
              Marker(
                point: destinationLocation,
                width: 80,
                height: 80,
                child: const Column(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Color.fromARGB(255, 255, 107, 74),
                      size: 30,
                    ),
                    Text(
                      'Destination',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 107, 74),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Positioned(
          top: 8,
          right: 20,
          width: 42,
          child: FloatingActionButton(
            shape: const CircleBorder(),
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () {

              setState(
                    () => _alignPositionOnUpdate = AlignOnUpdate.always,
              );

              _alignPositionStreamController.add(18);
            },
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}