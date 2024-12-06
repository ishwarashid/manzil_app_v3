import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/booking_inputs_provider.dart';

class InputSeats extends ConsumerStatefulWidget {
  const InputSeats({super.key});

  @override
  ConsumerState<InputSeats> createState() => _InputSeatsState();
}

class _InputSeatsState extends ConsumerState<InputSeats> {
  final _formKey = GlobalKey<FormState>();
  var _enteredSeats = 0;
  final _maxNoOfSeats = 12;

  @override
  void initState() {
    super.initState();
    final bookingInputs = ref.read(bookingInputsProvider);
    _enteredSeats = bookingInputs["seats"] as int? ?? 0;
  }

  void _saveSeats() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ref.read(bookingInputsProvider.notifier).setSeats(_enteredSeats);
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
              "No of Seats",
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
                children: [
                  TextFormField(
                    keyboardType: TextInputType.number,
                    initialValue: _enteredSeats.toString(),
                    cursorColor: const Color.fromARGB(255, 255, 170, 42),
                    style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.onPrimary),
                    decoration: InputDecoration(
                      label: const Text(
                        'Seats',
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
                            color: Color.fromARGB(160, 255, 255, 255),
                            width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 2),
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
                      if (int.tryParse(value)! == 0) {
                        return 'Number of seats can\'t be zero';
                      }
                      if (int.tryParse(value)! > _maxNoOfSeats) {
                        return 'You can only select seats from 1 to $_maxNoOfSeats';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _enteredSeats = int.parse(value!);
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveSeats,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color.fromARGB(255, 255, 170, 42),
                        foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
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
