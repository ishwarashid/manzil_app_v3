import 'package:flutter/material.dart';
import 'package:manzil_app_v3/screens/manage_vehicles_screen.dart';

class VehicleSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> vehicles;

  const VehicleSelectionDialog({
    super.key,
    required this.vehicles,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Select Vehicle'),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // First close the dialog
              Navigator.of(context).pop();
              // Then navigate to vehicle management screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageVehiclesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: vehicles.map((vehicle) {
            return ListTile(
              title: Text('${vehicle['make']} ${vehicle['model']}'),
              subtitle: Text('${vehicle['number']} (${vehicle['category']})'),
              onTap: () {
                Navigator.of(context).pop(vehicle);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}