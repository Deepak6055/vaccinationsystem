import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChildDetailsPage extends StatefulWidget {
  final String parentUuid;
  const ChildDetailsPage({super.key, required this.parentUuid});

  @override
  State<ChildDetailsPage> createState() => _ChildDetailsPageState();
}

class _ChildDetailsPageState extends State<ChildDetailsPage> {
  final _nameController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  final List<String> _allergies = [];

  /// Calculates age from date of birth
  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _saveChild() async {
    if (_dob == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields!")),
      );
      return;
    }

    final int calculatedAge = _calculateAge(_dob!);

    final childRef = FirebaseFirestore.instance.collection('children').doc();
    await childRef.set({
      'uuid': childRef.id,
      'name': _nameController.text,
      'dob': Timestamp.fromDate(_dob!),
      'age': calculatedAge,
      'gender': _gender ?? '',
      'guardians': [widget.parentUuid],
      'appointments': [],
      'allergies': _allergies,
      'contraindications': [],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('parents')
        .doc(widget.parentUuid)
        .update({
      'children': FieldValue.arrayUnion([childRef.id])
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Child added successfully!")),
      );
    }

    Navigator.pushReplacementNamed(context, '/parent_home');
  }

  void _showAllergyDialog() {
    final commonAllergies = [
      'Peanuts',
      'Eggs',
      'Milk',
      'Wheat',
      'Soy',
      'Fish',
      'Tree nuts',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) {
        final tempSelected = <String>{};
        String existingOtherText = '';

        for (var a in _allergies) {
          if (a.startsWith('Other: ')) {
            tempSelected.add('Other');
            existingOtherText = a.substring('Other: '.length);
          } else if (commonAllergies.contains(a)) {
            tempSelected.add(a);
          }
        }

        final otherController = TextEditingController(text: existingOtherText);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Allergies"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: commonAllergies.map((allergy) {
                    final checked = tempSelected.contains(allergy);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: Text(allergy),
                          value: checked,
                          onChanged: (bool? value) {
                            setStateDialog(() {
                              if (value == true) {
                                tempSelected.add(allergy);
                              } else {
                                tempSelected.remove(allergy);
                              }
                            });
                          },
                        ),
                        if (allergy == 'Other' && tempSelected.contains('Other'))
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: TextField(
                              controller: otherController,
                              decoration: const InputDecoration(
                                labelText: 'Describe other allergy',
                                hintText: 'e.g. Pollen, Latex...',
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final newList = <String>[];
                    for (var sel in tempSelected) {
                      if (sel == 'Other') {
                        final desc = otherController.text.trim();
                        if (desc.isNotEmpty) {
                          newList.add('Other: $desc');
                        } else {
                          newList.add('Other');
                        }
                      } else {
                        newList.add(sel);
                      }
                    }

                    setState(() {
                      _allergies
                        ..clear()
                        ..addAll(newList);
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dobText = _dob != null
        ? DateFormat('yyyy-MM-dd').format(_dob!)
        : "Select Date of Birth";

    final ageText =
        _dob != null ? "Age: ${_calculateAge(_dob!)} years" : "Age not set";

    return Scaffold(
      appBar: AppBar(title: const Text("Child Details")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "Child's Name",
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
                hint: const Text("Select Gender"),
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Date of Birth",
                  ),
                  child: Text(dobText),
                ),
              ),
              const SizedBox(height: 10),
              if (_dob != null)
                Text(
                  ageText,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _showAllergyDialog,
                child: const Text("Add Allergies"),
              ),
              if (_allergies.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  children: _allergies
                      .map((allergy) => Chip(
                            label: Text(allergy),
                            onDeleted: () =>
                                setState(() => _allergies.remove(allergy)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _saveChild,
                child: const Text("Save Child"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
