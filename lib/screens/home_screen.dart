import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:manzil_app_v3/main.dart';
import 'package:manzil_app_v3/providers/booking_inputs_provider.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';
import 'package:manzil_app_v3/providers/rides_filter_provider.dart';
import 'package:manzil_app_v3/screens/booking.dart';
import 'package:manzil_app_v3/screens/chats_screen.dart';
import 'package:manzil_app_v3/screens/find_drivers.dart';
import 'package:manzil_app_v3/screens/ride_requests.dart';
import 'package:manzil_app_v3/screens/tracking.dart';
import 'package:manzil_app_v3/screens/user_activity.dart';
import 'package:manzil_app_v3/widgets/main_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedPageIndex = 0;
  String? phoneNumber;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    final box = GetStorage();
    phoneNumber = box.read('phoneNumber');
    // phoneNumber = '+92' + (box.read('phoneNumber'));
    print("Phone");
    print(phoneNumber);
    _fetchUserData();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final userNotifier = ref.read(currentUserProvider.notifier);
      final hasPermission = await userNotifier.requestLocationPermission();

      if (hasPermission) {
        await userNotifier.updateLocation();
      } else {
        // if user denies permission then this will execute
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for this app'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _fetchUserData() async {
    final currentUser = ref.read(currentUserProvider);

    if (currentUser['first_name'] == '') {
      try {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone_number', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          final userData = doc.data() as Map<String, dynamic>;
          print("UserData");
          print(userData);
          userData['uid'] = doc.id;
          // print(userData['isBanned'] == true);
          // logic to check if user is banned because we want to log him out then
          if (userData['isBanned'] == true) {
            // used addPostFrameCallback to ensure that the home screen first loads properly
            // this is imp beacuse we are calling _fetchUserData inside initState
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              // this will be shown on the start screen not on homescreen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account has been banned. Please contact support.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );

              final box = GetStorage();
              box.erase();
              ref.read(currentUserProvider.notifier).clearUser();
              ref.read(ridesFilterProvider.notifier).clearFilter();
              ref.read(bookingInputsProvider.notifier).resetBookingInputs();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MyApp()),
                    (route) => false,
              );
            });
            return;
          }

          // If not banned, update user data
          ref.read(currentUserProvider.notifier).setUser(userData);
        }
      } catch (e) {
        print("Error fetching user data: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error fetching user data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _setScreen(String identifier, {bool? isDriver}) async {
    Navigator.of(context).pop();
    if (identifier == 'chats') {
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
    } else if(identifier == 'tracking') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => TrackingScreen(isDriver!),
        ),
      );
    }
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = const UserActivityScreen();

    final currentUser = ref.watch(currentUserProvider);
    print(currentUser);

    if (_selectedPageIndex == 1) {
      activePage = const RideRequestsScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          _isLoadingLocation ?
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 60),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          :
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => const Booking(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                ),
              ),
              icon: const ImageIcon(
                size: 24,
                color: Color.fromARGB(255, 255, 170, 42),
                ResizeImage(
                    AssetImage('assets/icons/book_a_ride_icon.png'),
                    width: 48,
                    height: 48
                ),
              ),
              label: const Text("Book a Ride"),
            ),
          ),
        ],
      ),
      drawer: MainDrawer(onSelectScreen: _setScreen),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        currentIndex: _selectedPageIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.backup_table),
              label: "Activity"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.drive_eta_outlined),
              label: "Accept Requests"
          ),
        ],
      ),
    );
  }
}
