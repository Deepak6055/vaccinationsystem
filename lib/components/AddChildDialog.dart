
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class AddChildDialog extends StatefulWidget {
  const AddChildDialog({super.key});

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final _childNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPasswordController = TextEditingController();

  bool _creating = false;

  Future<void> _addChild() async {
    setState(() => _creating = true);

    try {
      // Check if parent exists in Firestore
      final parentSnap = await FirebaseFirestore.instance
          .collection("parents")
          .where("email", isEqualTo: _parentEmailController.text.trim())
          .get();

      String parentId;

      if (parentSnap.docs.isEmpty) {
        // Create parent in FirebaseAuth
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _parentEmailController.text.trim(),
          password: _parentPasswordController.text.trim(),
        );

        parentId = cred.user!.uid;

        // Save parent in Firestore
        await FirebaseFirestore.instance.collection("parents").doc(parentId).set({
          "uuid": parentId,
          "email": _parentEmailController.text.trim(),
          "role": "parent",
          "created_at": DateTime.now().toIso8601String(),
        });
      } else {
        parentId = parentSnap.docs.first.id;
      }

      // Add child
      final childRef = FirebaseFirestore.instance.collection("children").doc();
      await childRef.set({
        "uuid": childRef.id,
        "name": _childNameController.text,
        "dob": _dobController.text,
        "parent_id": parentId,
        "created_at": DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Child"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: _childNameController, decoration: const InputDecoration(labelText: "Child Name")),
            TextField(controller: _dobController, decoration: const InputDecoration(labelText: "Date of Birth")),
            const Divider(),
            TextField(controller: _parentEmailController, decoration: const InputDecoration(labelText: "Parent Email")),
            TextField(controller: _parentPasswordController, decoration: const InputDecoration(labelText: "Parent Password")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _creating ? null : _addChild,
          child: _creating ? const CircularProgressIndicator() : const Text("Add Child"),
        )
      ],
    );
  }
}
