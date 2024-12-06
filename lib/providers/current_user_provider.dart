import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrentUserNotifier extends StateNotifier<Map<String, dynamic>> {
  CurrentUserNotifier()
      : super({
    "uid": '',
    "email": '',
    "first_name": '',
    "last_name": '',
    "phone_number": '',
    "overallRating": 0,
    "isBanned": false,
    "coordinates": [],
    "location_text": ''
  });

  DateTime? _lastLocationUpdate;
  static const _locationUpdateThreshold = Duration(minutes: 1);

  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  Future<void> updateLocation() async {

    // This updates location after (1 minutes)
    if (_lastLocationUpdate != null &&
        DateTime.now().difference(_lastLocationUpdate!) < _locationUpdateThreshold) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Updates coordinates inside state
      state = {
        ...state,
        "coordinates": [position.latitude, position.longitude]
      };

      // Gets location in text form
      final locationText = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      state = {
        ...state,
        "location_text": locationText
      };

      _lastLocationUpdate = DateTime.now();
    } catch (e) {
      print('Error updating location: $e');
      throw e;
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&accept-language=en-US&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Manzil App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      } else {
        throw Exception('Failed to get address: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting address: $e');

      // This returns last known location text if available, otherwise throw
      if (state['location_text'].isNotEmpty) {
        return state['location_text'];
      }
      throw Exception('Failed to get address: $e');
    }
  }

  void setUser(Map<String, dynamic> user) {
    state = {
      ...state,
      ...user
    };
  }

  void updateField(String field, dynamic value) {
    state = {
      ...state,
      field: value
    };
  }

  void clearUser() {
    state = {
      "uid": '',
      "email": '',
      "first_name": '',
      "last_name": '',
      "phone_number": '',
      "overallRating": 0,
      "isBanned": false,
      "coordinates": [],
      "location_text": ''
    };
    _lastLocationUpdate = null;
  }
}

final currentUserProvider =
StateNotifierProvider<CurrentUserNotifier, Map<String, dynamic>>((ref) {
  return CurrentUserNotifier();
});