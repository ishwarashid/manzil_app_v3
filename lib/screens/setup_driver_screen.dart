import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:manzil_app_v3/providers/current_user_provider.dart';

class Vehicle {
  String number;
  String category;
  String make;
  String model;
  double? litersPerMeter;

  Vehicle({
    required this.number,
    required this.category,
    required this.make,
    required this.model,
    this.litersPerMeter,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'category': category,
        'make': make,
        'model': model,
        'litersPerMeter': litersPerMeter,
      };
}

class SetupDriverScreen extends ConsumerStatefulWidget {
  const SetupDriverScreen({super.key});

  @override
  ConsumerState<SetupDriverScreen> createState() => _SetupDriverScreenState();
}

class _SetupDriverScreenState extends ConsumerState<SetupDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  late TextEditingController _licenseController;
  late TextEditingController _cnicController;
  DateTime? _licenseExpiry;
  DateTime? _cnicExpiry;
  late TextEditingController _makeController;
  bool _isLoadingModels = false;
  bool _hasExistingVehicles = false;

  // Vehicle related controllers and variables
  List<Vehicle> vehicles = [];
  List<String> makes = [];
  Map<String, List<String>> modelsByMake = {};
  final vehicleCategories = ['Car', 'Bike', 'Rickshaw'];

  @override
  void initState() {
    super.initState();
    _licenseController = TextEditingController();
    _cnicController = TextEditingController();
    _makeController = TextEditingController();
    _checkExistingVehicles();  // Add this line
    _addNewVehicle();
  }
  @override
  void dispose() {
    _licenseController.dispose();
    _cnicController.dispose();
    _makeController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingVehicles() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser['uid'])
          .collection('vehicles')
          .get();

      setState(() {
        _hasExistingVehicles = vehiclesSnapshot.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error checking vehicles: $e');
    }
  }

  Future<void> _fetchModels(String make, int vehicleIndex) async {
    if (make.isEmpty) return;

    setState(() => _isLoadingModels = true);

    try {
      final isCarCategory = vehicles[vehicleIndex].category == 'Car';
      final apiEndpoint = isCarCategory
          ? 'https://api.api-ninjas.com/v1/cars'
          : 'https://api.api-ninjas.com/v1/motorcycles';

      final response = await http.get(
        Uri.parse('$apiEndpoint?make=${Uri.encodeComponent(make.toLowerCase())}&limit=100'),
        headers: {'X-Api-Key': '1DqqP0MLwcDiTF2KUZQ6pw==W0GZ6se8Q3K4fTou'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        Set<String> uniqueModels = {};

        for (var vehicle in data) {
          if (vehicle['model'] != null) {
            uniqueModels.add(vehicle['model']);
          }
          // if (isCarCategory) {
          //   if (vehicle['model'] != null) {
          //     uniqueModels.add(vehicle['model']);
          //   }
          // } else {
          //   if (vehicle['name'] != null) {
          //     final name = vehicle['name'] as String;
          //     if (name.toLowerCase().startsWith(make.toLowerCase())) {
          //       final model = name.substring(make.length).trim();
          //       if (model.isNotEmpty) {
          //         uniqueModels.add(model);
          //       }
          //     }
          //   }
          // }
        }

        setState(() {
          modelsByMake[make] = uniqueModels.toList()..sort();
          vehicles[vehicleIndex].model = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching models: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingModels = false);
    }
  }

  Future<double?> _fetchFuelConsumption(String make, String model, String vehicleCategory) async {
    try {
      final isCarCategory = vehicles.firstWhere(
              (v) => v.make == make && v.model == model
      ).category == 'Car';

      if (isCarCategory) {
        final response = await http.get(
          Uri.parse(
              'https://api.api-ninjas.com/v1/cars?make=${Uri.encodeComponent(make.toLowerCase())}&model=${Uri.encodeComponent(model.toLowerCase())}&limit=1'
          ),
          headers: {'X-Api-Key': '1DqqP0MLwcDiTF2KUZQ6pw==W0GZ6se8Q3K4fTou'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty && data[0]['city_mpg'] != null) {
            final mpgCity = data[0]['city_mpg'] as num;
            return _convertMpgToLitersPerMeter(mpgCity.toDouble());
          }
        }
      } else {
        final response = await http.get(
          Uri.parse(
              'https://api.api-ninjas.com/v1/motorcycles?make=${Uri.encodeComponent(make.toLowerCase())}&model=${Uri.encodeComponent(model.toLowerCase())}&limit=1'
          ),
          headers: {'X-Api-Key': '1DqqP0MLwcDiTF2KUZQ6pw==W0GZ6se8Q3K4fTou'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            return _getDefaultMileage(vehicleCategory); // Use default values for bikes
          }
        }
      }

      return _getDefaultMileage(vehicleCategory);
    } catch (e) {
      return _getDefaultMileage(vehicles.firstWhere(
              (v) => v.make == make && v.model == model
      ).category);
    }
  }

  double _getDefaultMileage(String category) {
    switch (category.toLowerCase()) {
      case 'bike':
        return _convertMpgToLitersPerMeter(50.0);
      case 'car':
        return _convertMpgToLitersPerMeter(30.0);
      case 'rickshaw':
        return _convertMpgToLitersPerMeter(35.0);
      default:
        return _convertMpgToLitersPerMeter(25.0);
    }}

  double _convertMpgToLitersPerMeter(double mpg) {
    // Convert MPG to L/100km first
    final litersPer100Km = 235.215 / mpg;
    // Convert L/100km to L/m
    return litersPer100Km / 100000;
  }


  void _addNewVehicle() {
    setState(() {
      vehicles.add(Vehicle(
        number: '',
        category: vehicleCategories[0],
        make: '',
        model: '',
      ));
    });
  }

  String? _validateVehicleNumber(String? value, int index) {
    // Skip validation if has existing vehicles and field is empty
    if (_hasExistingVehicles && (value == null || value.isEmpty)) {
      return null;
    }

    // Regular validation
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required';
    }
    final RegExp vehicleRegex = RegExp(r'^[A-Z]{3}\d{1,4}$');
    if (!vehicleRegex.hasMatch(value)) {
      return 'Invalid format. Use XXX1234';
    }
    return null;
  }

  String? _validateMake(String? value, int index) {
    // Skip validation if has existing vehicles and field is empty
    if (_hasExistingVehicles && (value == null || value.isEmpty)) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Make is required';
    }
    return null;
  }

  Widget _buildVehicleForm(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vehicle ${index + 1}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Vehicle Number',
            hintText: 'XXX1234',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value){
            return _validateVehicleNumber(value, index);
          },
          onChanged: (value) => vehicles[index].number = value,
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              final newText = newValue.text.toUpperCase();
              return newValue.copyWith(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
              );
            }),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            LengthLimitingTextInputFormatter(7),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Vehicle Category',
            border: OutlineInputBorder(),
          ),
          value: vehicles[index].category,
          items: vehicleCategories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              vehicles[index].category = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Make',
            hintText: 'e.g., Toyota, Honda',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            return _validateMake(value, index);
          },
          onChanged: (value) {
            vehicles[index].make = value;
            _fetchModels(value, index);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Model',
            border: const OutlineInputBorder(),
            suffixIcon: _isLoadingModels
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 2,
                        height: 2,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          value: vehicles[index].model.isEmpty ? null : vehicles[index].model,
          items: modelsByMake[vehicles[index].make]?.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model),
                );
              }).toList() ??
              [],
          onChanged: (value) {
            setState(() {
              vehicles[index].model = value!;
            });
          },
        ),
        const SizedBox(height: 24),
        if (index > 0)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                vehicles.removeAt(index);
              });
            },
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            label: const Text(
              'Remove Vehicle',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  bool _isVehicleValid(Vehicle vehicle) {
    return vehicle.number.isNotEmpty &&
        vehicle.make.isNotEmpty &&
        vehicle.model.isNotEmpty;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseExpiry == null || _cnicExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select expiry dates for both documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final validVehicles = _hasExistingVehicles
        ? vehicles.where(_isVehicleValid).toList()
        : vehicles;

    // Only check for vehicles if user doesn't have existing ones
    if (!_hasExistingVehicles && validVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one vehicle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser['uid']);

      // First, update user document with license and CNIC info
      await userRef.update({
        'drivingLicense': _licenseController.text,
        'licenseExpiry': Timestamp.fromDate(_licenseExpiry!),
        'cnic': _cnicController.text,
        'cnicExpiry': Timestamp.fromDate(_cnicExpiry!),
      });

      // Only add vehicles if there are any new ones to add
      if (validVehicles.isNotEmpty) {
        print("Vehicles are not empty");
        final batch = FirebaseFirestore.instance.batch();

        for (var vehicle in validVehicles) {
          vehicle.litersPerMeter = await _fetchFuelConsumption(
              vehicle.make,
              vehicle.model,
              vehicle.category
          );

          final vehicleRef = userRef.collection('vehicles').doc();
          batch.set(vehicleRef, vehicle.toJson());
        }

        await batch.commit();
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver setup completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = (MediaQuery.of(context).viewInsets.bottom / 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Setup'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                EdgeInsets.only(left: 30, right: 30, bottom: keyboardSpace),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Please provide your driver details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 45, 45, 45),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Original license and CNIC fields...
                  TextFormField(
                    controller: _licenseController,
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                      hintText: 'XX-XX-XXX',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateLicense,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final newText = newValue.text.toUpperCase();
                        return newValue.copyWith(
                          text: newText,
                          selection:
                              TextSelection.collapsed(offset: newText.length),
                        );
                      }),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                      LengthLimitingTextInputFormatter(9),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text('License Expiry Date'),
                    subtitle: Text(
                      _licenseExpiry == null
                          ? 'Not selected'
                          : '${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    onTap: () => _selectDate(context, true),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _cnicController,
                    decoration: const InputDecoration(
                      labelText: 'CNIC Number',
                      hintText: 'XXXXX-XXXXXXX-X',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateCNIC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: const Text('CNIC Expiry Date'),
                    subtitle: Text(
                      _cnicExpiry == null
                          ? 'Not selected'
                          : '${_cnicExpiry!.day}/${_cnicExpiry!.month}/${_cnicExpiry!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    onTap: () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 32),
                  if (_hasExistingVehicles) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'You already have vehicles registered. Adding more vehicles is optional.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  ...List.generate(
                      vehicles.length, (index) => _buildVehicleForm(index)),

                  OutlinedButton.icon(
                    onPressed: _addNewVehicle,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Vehicle'),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateLicense(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    // XX-XX-XXX
    final RegExp licenseRegex = RegExp(r'^[A-Z]{2}-\d{2}-\d{3}$');
    if (!licenseRegex.hasMatch(value)) {
      return 'Invalid format. Use XX-XX-XXX';
    }
    return null;
  }

  String? _validateCNIC(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNIC is required';
    }
    // XXXXX-XXXXXXX-X
    final RegExp cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!cnicRegex.hasMatch(value)) {
      return 'Invalid format. Use XXXXX-XXXXXXX-X';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context, bool isLicense) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        if (isLicense) {
          _licenseExpiry = picked;
        } else {
          _cnicExpiry = picked;
        }
      });
    }
  }
}
