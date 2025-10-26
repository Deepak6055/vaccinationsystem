import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/vaccination_schedule.dart';

class ParentCreateAppointmentPage extends StatefulWidget {
  const ParentCreateAppointmentPage({super.key});

  @override
  State<ParentCreateAppointmentPage> createState() => _ParentCreateAppointmentPageState();
}

class _ParentCreateAppointmentPageState extends State<ParentCreateAppointmentPage> {
  String? _selectedChild;
  String? _selectedDoctor;
  String? _selectedVaccineId;
  String? _selectedVaccineName;
  DateTime? _selectedDate;
  int? _childAgeMonths;
  List<Map<String, dynamic>> _childData = [];
  List<Map<String, dynamic>> _doctorData = [];
  List<VaccineScheduleItem> _recommendedVaccines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchChildren(),
      _fetchDoctors(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchChildren() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final parentDoc = await FirebaseFirestore.instance.collection("parents").doc(uid).get();
    if (!parentDoc.exists) return;

    List<dynamic> childIds = parentDoc.data()?['children'] ?? [];
    _childData = [];

    for (var childId in childIds) {
      var childDoc = await FirebaseFirestore.instance.collection('children').doc(childId).get();
      if (childDoc.exists) {
        var data = childDoc.data() as Map<String, dynamic>;
        _childData.add({
          'id': childDoc.id,
          'name': data['name'] ?? 'Unknown',
          'dob': (data['dob'] as Timestamp?)?.toDate(),
        });
      }
    }
    setState(() {});
  }

  Future<void> _fetchDoctors() async {
    final snap = await FirebaseFirestore.instance.collection("doctors").get();
    _doctorData = snap.docs.map((d) => {
      "id": d.id,
      "name": d.data()["name"] ?? "Unknown Doctor"
    }).toList();
    setState(() {});
  }

  void _onChildSelected(String? childId) {
    setState(() {
      _selectedChild = childId;
      _selectedVaccineId = null;
      _selectedVaccineName = null;
      _recommendedVaccines = [];
      
      if (childId != null) {
        var child = _childData.firstWhere((c) => c['id'] == childId);
        var dob = child['dob'] as DateTime?;
        print("Child $childId DOB: $dob");
        if (dob != null) {
          _childAgeMonths = VaccinationSchedule.calculateAgeInMonths(dob);
          _recommendedVaccines = VaccinationSchedule.getVaccinationsForAge(_childAgeMonths!);
        }
      }
    });
  }

  Future<void> _saveAppointment() async {
    if (_selectedChild == null || _selectedDoctor == null || _selectedVaccineId == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection("appointments").doc();

    try {
      await docRef.set({
        "uuid": docRef.id,
        "child_id": _selectedChild,
        "doctor_id": _selectedDoctor,
        "parent_id": uid, // Add parent_id
        "vaccination_id": _selectedVaccineId, // Store as string (document ID)
        "vaccination_name": _selectedVaccineName, // Store vaccine name
        "date": _selectedDate!.toIso8601String(),
        "status": "pending_approval", // New status for parent-created appointments
        "consent_form_signed": false,
        "created_at": DateTime.now().toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment request submitted. Awaiting nurse approval.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating appointment: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Appointment Request")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Child Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "1. Select Child",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedChild,
                            items: _childData
                                .map((c) => DropdownMenuItem<String>(
                                      value: c["id"] as String?,
                                      child: Text(c["name"]),
                                    ))
                                .toList(),
                            onChanged: _onChildSelected,
                            decoration: const InputDecoration(
                              labelText: "Select Child",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_childData.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "No children found. Please add a child first.",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Show Recommended Vaccines
                  if (_selectedChild != null && _recommendedVaccines.isNotEmpty) ...[
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  "Recommended Vaccinations (Age: $_childAgeMonths months)",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._recommendedVaccines.map((vaccine) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.check_circle, size: 20, color: Colors.green.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vaccine.vaccine,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            if (vaccine.remarks.isNotEmpty)
                                              Text(
                                                vaccine.remarks,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Vaccination Schedule Chart
                  Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text(
                        "2. View Vaccination Schedule Chart",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text("Tap to view full Indian vaccination schedule"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Table(
                            border: TableBorder.all(color: Colors.grey.shade300),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.blue.shade100),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text("Age", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text("Vaccines", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text("Remarks", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              ..._buildScheduleTableRows(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vaccine Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "3. Select Vaccine",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              labelText: "Search and select vaccine",
                              hintText: "Type vaccine name",
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                              suffixIcon: _selectedVaccineId != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _selectedVaccineId = null;
                                  _selectedVaccineName = null;
                                });
                              },
                                    )
                                  : null,
                            ),
                            onTap: () => _showVaccineSelectionDialog(),
                            controller: TextEditingController(text: _selectedVaccineName),
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Doctor Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "4. Select Doctor",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder(
                            future: Future.delayed(Duration.zero, () => _doctorData),
                            builder: (context, snapshot) {
                              if (_doctorData.isEmpty) {
                                return const Text("No doctors available");
                              }
                              return DropdownButtonFormField<String>(
                                value: _selectedDoctor,
                                items: _doctorData
                                    .map((d) => DropdownMenuItem<String>(
                                          value: d["id"] as String?,
                                          child: Text(d["name"]),
                                        ))
                                    .toList(),
                                onChanged: (String? val) => setState(() => _selectedDoctor = val),
                                decoration: const InputDecoration(
                                  labelText: "Select Doctor",
                                  border: OutlineInputBorder(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "5. Select Date",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(_selectedDate == null
                                ? "Select Date"
                                : "Selected: ${_selectedDate!.toString().split(' ')[0]}"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _saveAppointment,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "Submit Appointment Request",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showVaccineSelectionDialog() async {
    // Fetch actual vaccination documents from Firestore
    final snap = await FirebaseFirestore.instance.collection("vaccinations").get();
    final vaccineDocs = snap.docs.map((doc) => {
      "id": doc.id,
      "name": doc.data()["name"] ?? "Unknown",
      "data": doc.data(),
    }).toList();
    
    // Use vaccineDocs from Firestore
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Vaccine",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: vaccineDocs.length,
                  itemBuilder: (context, index) {
                    final vaccine = vaccineDocs[index];
                    return ListTile(
                      title: Text(vaccine["name"]),
                      onTap: () {
                        setState(() {
                          _selectedVaccineId = vaccine["id"];
                          _selectedVaccineName = vaccine["name"];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TableRow> _buildScheduleTableRows() {
    final scheduleData = [
      ["At Birth", "BCG, Hepatitis B (Birth dose), OPV-0", "As soon as possible after birth"],
      ["6 Weeks", "DTP (1st), IPV (1st), Hep B (2nd), Hib (1st), Rotavirus (1st), PCV (1st)", "Start of primary series"],
      ["10 Weeks", "DTP (2nd), IPV (2nd), Hib (2nd), Rotavirus (2nd), PCV (2nd)", "Continue primary vaccination"],
      ["14 Weeks", "DTP (3rd), IPV (3rd), Hib (3rd), Rotavirus (3rd), PCV (3rd)", "Complete primary series"],
      ["9-12 Months", "MMR (1st), PCV Booster, Hepatitis A (1st)", "Prevents measles, mumps, rubella, pneumonia"],
      ["15-18 Months", "DTP Booster-1, IPV Booster, Hib Booster, MMR (2nd), Varicella (1st)", "First booster phase"],
      ["2 Years", "Typhoid Conjugate Vaccine", "Prevents typhoid fever"],
      ["4-6 Years", "DTP Booster-2, IPV Booster, MMR (3rd), Varicella (2nd)", "School entry booster"],
      ["10-12 Years", "Tdap/Td Booster, HPV (for girls)", "Adolescent protection"],
      ["16-18 Years", "Td Booster", "Reinforcement for lifelong protection"],
    ];

    return scheduleData.map((row) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(row[0], style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(row[1]),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(row[2], style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ),
        ],
      );
    }).toList();
  }
}

