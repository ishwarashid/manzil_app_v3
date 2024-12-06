import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v3/main.dart';
import 'package:manzil_app_v3/providers/booking_inputs_provider.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';
import 'package:manzil_app_v3/providers/rides_filter_provider.dart';
import 'package:manzil_app_v3/providers/user_ride_providers.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key, required this.onSelectScreen});

  final void Function(String identifier, {bool? isDriver}) onSelectScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = GetStorage();
    final currentUser = ref.watch(currentUserProvider);
    final userRideStatus = ref.watch(userRideStatusProvider(currentUser['uid']));
    final hasRating = currentUser.containsKey('overallRating');
    final rating = hasRating ? (currentUser['overallRating'] as num).toDouble() : null;

    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                color: Theme.of(context).colorScheme.primary,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(255, 255, 170, 42),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (currentUser['first_name'] as String).isEmpty
                                ? "Unknown"
                                : currentUser['first_name'] as String,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (hasRating) const SizedBox(height: 4),
                          if (hasRating)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color.fromARGB(255, 255, 170, 42),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
                child: ListTile(
                  title: Text(
                    "Home",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20),
                  ),
                  leading: Icon(
                    Icons.home_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  onTap: () {
                    onSelectScreen('home');
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: ListTile(
                  title: Text(
                    "Chats",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20),
                  ),
                  leading: Icon(
                    Icons.message_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  onTap: () {
                    onSelectScreen('chats');
                  },
                ),
              ),
              userRideStatus.when(
                data: (status) {

                  if (!status.isDriver &&
                      status.activeRides
                          .any((ride) => ride['status'] == 'pending')) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: ListTile(
                        title: Text(
                          "Found Drivers",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20),
                        ),
                        leading: Icon(
                          Icons.directions_car_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                        onTap: () {
                          onSelectScreen('foundDrivers');
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              userRideStatus.when(
                data: (status) {
                  final hasAcceptedRide = status.activeRides
                      .any((ride) => (ride['status'] == 'accepted' || ride['status'] == 'picked' || ride['status'] == 'paying'));
                  if (hasAcceptedRide) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: ListTile(
                        title: Text(
                          "Tracking",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20),
                        ),
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                        onTap: () {
                          onSelectScreen('tracking', isDriver: status.isDriver);
                        },
                        // onTap: () {
                        //   // onSelectScreen('tracking');
                        //   // Navigator.push(
                        //   //   context,
                        //   //   MaterialPageRoute(
                        //   //     builder: (ctx) => TrackingScreen(status.isDriver),
                        //   //   ),
                        //   // );
                        // },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: ListTile(
              title: Text(
                "Logout",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary, fontSize: 20),
              ),
              leading: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              onTap: () {
                box.erase();
                ref.read(currentUserProvider.notifier).clearUser();
                ref.read(ridesFilterProvider.notifier).clearFilter();
                ref.read(bookingInputsProvider.notifier).resetBookingInputs();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyApp(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
