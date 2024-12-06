// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class DriverTrackingMap extends ConsumerStatefulWidget {
//   final List<Map<String, dynamic>> rides;
//   final String driverId;
//
//   const DriverTrackingMap({
//     required this.rides,
//     required this.driverId,
//     super.key,
//   });
//
//   @override
//   ConsumerState<DriverTrackingMap> createState() => _DriverTrackingMapState();
// }
//
// class _DriverTrackingMapState extends ConsumerState<DriverTrackingMap> {
//   final mapController = MapController();
//   LatLng? currentLocation;
//   Timer? _locationUpdateTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//     // Set up timer for location updates
//     _locationUpdateTimer = Timer.periodic(
//       const Duration(minutes: 2),
//           (_) => _updateDriverLocation(),
//     );
//   }
//
//   @override
//   void dispose() {
//     _locationUpdateTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _getCurrentLocation() async {
//     try {
//       final position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high
//       );
//
//       setState(() {
//         currentLocation = LatLng(position.latitude, position.longitude);
//         mapController.move(currentLocation!, 15);
//       });
//     } catch (e) {
//       print('Error getting location: $e');
//     }
//   }
//
//   Future<void> _updateDriverLocation() async {
//     try {
//       final position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high
//       );
//
//       // Get current location text using reverse geocoding
//       final locationText = await _getAddressFromCoordinates(position.latitude, position.longitude);
//
//       // Update driver location for all accepted rides
//       final batch = FirebaseFirestore.instance.batch();
//
//       for (final ride in widget.rides) {
//         if (ride['status'] == 'accepted') {
//           final acceptedByRef = FirebaseFirestore.instance
//               .collection('rides')
//               .doc(ride['id'])
//               .collection('acceptedBy')
//               .doc(widget.driverId);
//
//           batch.update(acceptedByRef, {
//             'driverLocation': locationText,
//             'driverCoordinates': [position.latitude, position.longitude],
//             'updatedAt': Timestamp.now(),
//           });
//         }
//       }
//
//       await batch.commit();
//
//       setState(() {
//         currentLocation = LatLng(position.latitude, position.longitude);
//       });
//     } catch (e) {
//       print('Error updating location: $e');
//     }
//   }
//
//   Future<String> _getAddressFromCoordinates(double lat, double lon) async {
//     final url = Uri.parse(
//         'https://nominatim.openstreetmap.org/reverse?format=json&accept-language=en-US&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
//     );
//
//     final response = await http.get(
//         url,
//         headers: {'Accept': 'application/json'}
//     );
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       return data['display_name'];
//     } else {
//       throw Exception('Failed to get address');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (currentLocation == null) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return FlutterMap(
//       mapController: mapController,
//       options: MapOptions(
//         initialCenter: currentLocation!,
//         initialZoom: 15,
//       ),
//       children: [
//         TileLayer(
//           urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//           tileProvider: CancellableNetworkTileProvider(),
//           userAgentPackageName: 'com.example.manzil_app',
//         ),
//         MarkerLayer(
//           markers: [
//             // Driver's current location marker
//             Marker(
//               point: currentLocation!,
//               width: 80,
//               height: 80,
//               child: const Column(
//                 children: [
//                   Icon(
//                     Icons.directions_car,
//                     color: Colors.blue,
//                     size: 30,
//                   ),
//                   Text(
//                     'You',
//                     style: TextStyle(
//                       color: Colors.blue,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Ride markers
//             ...widget.rides.expand((ride) {
//               final markers = <Marker>[];
//
//               // Add pickup marker if status is not 'picked'
//               if (ride['status'] != 'picked') {
//                 final pickupCoords = ride['pickupCoordinates'] as List;
//                 markers.add(
//                   Marker(
//                     point: LatLng(pickupCoords[0], pickupCoords[1]),
//                     width: 80,
//                     height: 80,
//                     child: Column(
//                       children: [
//                         const Icon(
//                           Icons.location_on,
//                           color: Colors.green,
//                           size: 30,
//                         ),
//                         Text(
//                           '${ride['passengerName']} Pickup',
//                           style: const TextStyle(
//                             color: Colors.green,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }
//
//               // Add destination marker
//               final destCoords = ride['destinationCoordinates'] as List;
//               markers.add(
//                 Marker(
//                   point: LatLng(destCoords[0], destCoords[1]),
//                   width: 80,
//                   height: 80,
//                   child: Column(
//                     children: [
//                       const Icon(
//                         Icons.flag,
//                         color: Colors.red,
//                         size: 30,
//                       ),
//                       Text(
//                         '${ride['passengerName']} Dest.',
//                         style: const TextStyle(
//                           color: Colors.red,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//
//               return markers;
//             }),
//           ],
//         ),
//       ],
//     );
//   }
// }