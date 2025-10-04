import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> logoutUser(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}
