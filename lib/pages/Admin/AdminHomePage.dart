import 'package:flutter/material.dart';
import '../../utils/logoutuser.dart';
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard"),
      actions: [
      IconButton(
        icon: const Icon(Icons.logout,color: Colors.blue,),
        onPressed: () => logoutUser(context),
      )
    ],),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _menuCard(context, "Add Doctor", Icons.medical_information, '/add_doctor'),
          _menuCard(context, "Add Nurse", Icons.local_hospital, '/add_nurse'),
          _menuCard(context, "Add Vaccination", Icons.vaccines, '/add_vaccine'),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.purple),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
