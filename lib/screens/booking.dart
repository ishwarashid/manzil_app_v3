import 'package:flutter/material.dart';
import 'package:manzil_app_v3/screens/chats_screen.dart';
import 'package:manzil_app_v3/screens/find_drivers.dart';
import 'package:manzil_app_v3/screens/tracking.dart';
import 'package:manzil_app_v3/widgets/main_drawer.dart';
import 'package:manzil_app_v3/widgets/main_map.dart';
import 'package:manzil_app_v3/widgets/ride_inputs.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  void _goToFindDriversScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const FindDrivers(),
      ),
    );
  }

  void _setScreen(String identifier, {bool? isDriver}) async {
    Navigator.of(context).pop();
    if (identifier == 'home') {
      Navigator.of(context).pop();
    } else if (identifier == 'chats') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const ChatsScreen(),
        ),
      );
    } else if (identifier == 'foundDrivers') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const FindDrivers(),
        ),
      );
    } else if (identifier == 'tracking') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => TrackingScreen(isDriver!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MainDrawer(
        onSelectScreen: _setScreen,
      ),
      body: SafeArea(
        child: SlidingUpPanel(
          panel: Center(
            child: RideInputs(onFindDrivers: _goToFindDriversScreen),
          ),
          collapsed: Container(
            // color: Theme.of(context).colorScheme.primary,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Text(
                "Slide up to fill the ride details",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              const MainMap(),
              Positioned(
                top: 16,
                left: 16,
                child: Builder(
                  builder: (context) => CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }
}
