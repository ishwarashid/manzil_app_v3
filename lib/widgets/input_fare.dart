import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/booking_inputs_provider.dart';

class InputFare extends ConsumerStatefulWidget {
  const InputFare({super.key});

  @override
  ConsumerState<InputFare> createState() => _InputFareState();
}

class _InputFareState extends ConsumerState<InputFare> {
  final _formKey = GlobalKey<FormState>();
  var _enteredFare = 0;
  final _minFare = 50;
  String _selectedPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    final bookingInputs = ref.read(bookingInputsProvider);
    _enteredFare = bookingInputs["fare"] as int? ?? 0;
    _selectedPaymentMethod = bookingInputs["paymentMethod"] as String? ?? 'cash';
  }

  void _saveFare() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final notifier = ref.read(bookingInputsProvider.notifier);
      notifier.setFare(_enteredFare);
      notifier.setPaymentMethod(_selectedPaymentMethod);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 30,
          bottom: MediaQuery.of(context).viewInsets.bottom + 60,
          right: 30,
          left: 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Offer Your Fare",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(200, 255, 255, 255),
              ),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    keyboardType: TextInputType.number,
                    initialValue: _enteredFare.toString(),
                    cursorColor: const Color.fromARGB(255, 255, 170, 42),
                    style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.onPrimary),
                    decoration: InputDecoration(
                      label: const Text(
                        'PKR',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color.fromARGB(160, 255, 255, 255),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 255, 170, 42), width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(160, 255, 255, 255), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error, width: 2),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null ||
                          int.tryParse(value)! <= 0) {
                        return 'Must be a valid, positive number.';
                      }

                      if (int.tryParse(value)! < _minFare) {
                        return 'Fare can\'t go lower than $_minFare';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _enteredFare = int.parse(value!);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(200, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      RadioListTile(
                        title: Text(
                          'Cash',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        value: 'cash',
                        groupValue: _selectedPaymentMethod,
                        activeColor: const Color.fromARGB(255, 255, 170, 42),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value.toString();
                          });
                        },
                      ),
                      RadioListTile(
                        title: Text(
                          'JazzCash',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        value: 'jazzcash',
                        groupValue: _selectedPaymentMethod,
                        activeColor: const Color.fromARGB(255, 255, 170, 42),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value.toString();
                          });
                        },
                      ),
                      RadioListTile(
                        title: Text(
                          'EasyPaisa',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        value: 'easypaisa',
                        groupValue: _selectedPaymentMethod,
                        activeColor: const Color.fromARGB(255, 255, 170, 42),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value.toString();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveFare,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 170, 42),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      child: const Text("Done"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
