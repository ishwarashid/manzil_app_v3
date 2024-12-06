import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:manzil_app_v3/screens/map_screen.dart';
import 'package:manzil_app_v3/models/location_suggestion.dart';
import 'package:manzil_app_v3/services/location/location_service.dart';
import '../providers/booking_inputs_provider.dart';

class InputPickup extends ConsumerStatefulWidget {
  const InputPickup({super.key});

  @override
  ConsumerState<InputPickup> createState() => _InputPickupState();
}

class _InputPickupState extends ConsumerState<InputPickup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pickupController;
  List<double>? _selectedCoordinates;
  Timer? _debounceTimer;
  List<LocationSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    final bookingInputs = ref.read(bookingInputsProvider);
    _pickupController = TextEditingController(
      text: bookingInputs["pickup"] as String? ?? '',
    );
    _selectedCoordinates = (bookingInputs["pickupCoordinates"] as List?)?.cast<double>();

    _pickupController.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _debounceTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _selectedCoordinates = null;
    });

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_pickupController.text.length >= 3) {
        _getSuggestions(_pickupController.text);
      } else {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    });
  }

  void _getSuggestions(String query) {
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = _locationService.getLocationSuggestions(query);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = _focusNode.hasFocus && suggestions.isNotEmpty;
      });
    } catch (e) {
      print('Error getting suggestions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    _pickupController.text = suggestion.displayName;
    _selectedCoordinates = [suggestion.lat, suggestion.lon];
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  void _savePickup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCoordinates == null) {
        setState(() => _isLoading = true);

        try {
          final location = await _locationService.getCoordinatesForAddress(
              _pickupController.text
          );

          if (location != null) {
            _selectedCoordinates = [location.lat, location.lon];
            final notifier = ref.read(bookingInputsProvider.notifier);
            notifier.setPickup(_pickupController.text);
            notifier.setPickupCoordinates(_selectedCoordinates!);

            if (mounted) Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Location Not Found'),
                content: const Text('Could not find this location. Please select from suggestions or try a different location.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        final notifier = ref.read(bookingInputsProvider.notifier);
        notifier.setPickup(_pickupController.text);
        notifier.setPickupCoordinates(_selectedCoordinates!);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100, bottom: 60, right: 30, left: 30),
      child: Stack(
        children: [
          Column(
            children: [
              const Text(
                "Enter Your Pickup Location",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(200, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 60),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextFormField(
                        controller: _pickupController,
                        focusNode: _focusNode,
                        cursorColor: const Color.fromARGB(255, 255, 170, 42),
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        decoration: InputDecoration(
                          label: const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(160, 255, 255, 255),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 255, 170, 42),
                              width: 2,
                            ),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(160, 255, 255, 255),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                          suffixIcon: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color.fromARGB(255, 255, 170, 42),
                              ),
                            ),
                          )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.trim().length <= 1 ||
                              value.trim().length > 255) {
                            return 'Must be between 1 and 255 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final result = await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => const MapScreen('pickup'),
                                ),
                              );

                              if (result != null && mounted) {
                                setState(() {
                                  _pickupController.text = result['address'];
                                  _selectedCoordinates = result['coordinates'] as List<double>;
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.map_outlined,
                              color: Color.fromARGB(255, 255, 170, 42),
                              size: 30,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _savePickup,
                            style: ElevatedButton.styleFrom(
                              elevation: 0.0,
                              backgroundColor: const Color.fromARGB(100, 255, 170, 42),
                              foregroundColor: const Color.fromARGB(255, 255, 170, 42),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: const Text("Set"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showSuggestions)
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 170, 42),
                    width: 2,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return InkWell(
                        onTap: () => _selectSuggestion(suggestion),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            suggestion.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}