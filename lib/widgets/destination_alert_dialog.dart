import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/rides_filter_provider.dart';
import 'package:manzil_app_v3/screens/map_screen.dart';

class DestinationAlertDialog extends ConsumerStatefulWidget {
  const DestinationAlertDialog({super.key});

  @override
  ConsumerState<DestinationAlertDialog> createState() => _DestinationAlertDialogState();
}

class _DestinationAlertDialogState extends ConsumerState<DestinationAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _destinationController;
  List<double>? _selectedCoordinates;

  @override
  void initState() {
    super.initState();
    final filterData = ref.read(ridesFilterProvider);
    _destinationController = TextEditingController(
        text: (filterData["destination"] ?? '') as String
    );
    _selectedCoordinates = (filterData["coordinates"] as List?)?.cast<double>();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _filterRides() {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(ridesFilterProvider.notifier);
      notifier.setDestination(_destinationController.text);
      if (_selectedCoordinates != null) {
        notifier.setDestinationCoordinates(_selectedCoordinates!);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = ref.watch(ridesFilterProvider)["destination"] as String? ?? '';

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: const Text(
        'Where are you going?',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(200, 255, 255, 255),
        ),
      ),
      content: SizedBox(
        height: 142,
        child: Container(
          margin: const EdgeInsets.only(top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _destinationController,
                  style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onPrimary
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a destination';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    label: Text(
                      'To',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(160, 255, 255, 255),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 255, 170, 42),
                          width: 2
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(160, 255, 255, 255),
                          width: 2
                      ),
                    ),
                    contentPadding: EdgeInsets.fromLTRB(12, 16, 12, 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapScreen("driverDestination"),
                    ),
                  );

                  if (result != null && mounted) {
                    setState(() {
                      _destinationController.text = result['address'];
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (destination.isNotEmpty) {
              ref.read(ridesFilterProvider.notifier).clearFilter();
              _destinationController.clear();
              setState(() {
                _selectedCoordinates = null;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            destination.isNotEmpty ? 'Reset' : 'Cancel',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _filterRides,
          style: ElevatedButton.styleFrom(
              elevation: 0.0,
              backgroundColor: const Color.fromARGB(100, 255, 170, 42),
              foregroundColor: const Color.fromARGB(255, 255, 170, 42)
          ),
          child: const Text(
            'Submit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}