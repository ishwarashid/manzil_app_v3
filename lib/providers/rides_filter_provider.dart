import 'package:flutter_riverpod/flutter_riverpod.dart';

class RidesFilterNotifier extends StateNotifier<Map<String, Object>> {
  RidesFilterNotifier()
      : super({
    "destination": '',
    "coordinates": <double>[],
  });

  void setDestination(String destination) {
    state = {
      ...state,
      "destination": destination,
    };
  }

  void setDestinationCoordinates(List<double> coordinates) {
    state = {
      ...state,
      "coordinates": coordinates,
    };
  }

  void clearFilter() {
    state = {
      "destination": '',
      "coordinates": [],
    };
  }
}

final ridesFilterProvider =
StateNotifierProvider<RidesFilterNotifier, Map<String, Object>>((ref) {
  return RidesFilterNotifier();
});
