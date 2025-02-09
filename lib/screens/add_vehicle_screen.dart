import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:manzil_app_v3/providers/current_user_provider.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String _category = 'Car';
  final vehicleCategories = ['Car', 'Bike', 'Rickshaw'];
  final _numberController = TextEditingController();
  String _make = '';
  String _model = '';
  Map<String, List<String>> modelsByMake = {};

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  String? _validateVehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required';
    }
    final RegExp vehicleRegex = RegExp(r'^[A-Z]{3}\d{1,4}$');
    if (!vehicleRegex.hasMatch(value)) {
      return 'Invalid format. Use XXX1234';
    }
    return null;
  }

  Future<void> _fetchModels(String make) async {
    try {
      final isCarCategory = _category == 'Car';
      final apiEndpoint = isCarCategory
          ? 'https://api.api-ninjas.com/v1/cars'
          : 'https://api.api-ninjas.com/v1/motorcycles';

      final response = await http.get(
        Uri.parse('$apiEndpoint?make=${Uri.encodeComponent(make.toLowerCase())}&limit=50'),
        headers: {'X-Api-Key': '1DqqP0MLwcDiTF2KUZQ6pw==W0GZ6se8Q3K4fTou'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(data);
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
        print(uniqueModels);

        setState(() {
          modelsByMake[make] = uniqueModels.toList()..sort();
          _model = '';
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
    }
  }

  Future<double?> _fetchFuelConsumption(String make, String model) async {
    try {
      final isCarCategory = _category == 'Car';

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
            return _getDefaultMileage(_category); // Use default values for bikes/rickshaws
          }
        }
      }

      return _getDefaultMileage(_category);
    } catch (e) {
      return _getDefaultMileage(_category);
    }
  }

  double _convertMpgToLitersPerMeter(double mpg) {
    final litersPer100Km = 235.215 / mpg;
    return litersPer100Km / 100000;
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
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_make.isEmpty || _model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both make and model'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final litersPerMeter = await _fetchFuelConsumption(_make, _model);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser['uid'])
          .collection('vehicles')
          .add({
        'number': _numberController.text,
        'category': _category,
        'make': _make,
        'model': _model,
        'litersPerMeter': litersPerMeter,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding vehicle: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number',
                      hintText: 'XXX1234',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateVehicleNumber,
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
                    value: _category,
                    items: vehicleCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value!;
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
                      if (value == null || value.isEmpty) {
                        return 'Make is required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _make = value;
                      _fetchModels(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  if (modelsByMake[_make]?.isNotEmpty ?? false)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                      value: _model.isEmpty ? null : _model,
                      items: modelsByMake[_make]?.map((model) {
                        return DropdownMenuItem(
                          value: model,
                          child: Text(model),
                        );
                      }).toList() ?? [],
                      onChanged: (value) {
                        setState(() {
                          _model = value!;
                        });
                      },
                    ),
                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('Add Vehicle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}