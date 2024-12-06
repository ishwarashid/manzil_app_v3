import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:manzil_app_v3/data/swl_locations.dart';
import 'package:manzil_app_v3/models/location_suggestion.dart';

class LocationService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org';

  // only use local suggestions, no API calls
  List<LocationSuggestion> getLocationSuggestions(String query) {
    query = query.toLowerCase().trim();
    if (query.length < 3) return [];

    return locationsForSuggestions.entries
        .where((entry) => entry.key.toLowerCase().contains(query))
        .map((entry) => LocationSuggestion(
      displayName: entry.key,
      lat: entry.value[0],
      lon: entry.value[1],
    ))
        .take(5)
        .toList();
  }

  // only use API for getting coordinates of manual entries
  Future<LocationSuggestion?> getCoordinatesForAddress(String address) async {
    final localMatch = locationsForSuggestions.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase() == address.toLowerCase(),
      orElse: () => const MapEntry('', [0.0, 0.0]),
    );

    if (localMatch.key.isNotEmpty) {
      return LocationSuggestion(
        displayName: localMatch.key,
        lat: localMatch.value[0],
        lon: localMatch.value[1],
      );
    }

    final url = Uri.parse(
        '$baseUrl/search?format=json&accept-language=en-US&q=$address&limit=1&countrycodes=pk'
    );

    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isEmpty) {
          throw Exception('No location found with this name');
        }
        return LocationSuggestion.fromJson(results.first);
      }
    } catch (e) {
      throw Exception('Could not find location: ${e.toString()}');
    }

    throw Exception('Could not find location');
  }
}