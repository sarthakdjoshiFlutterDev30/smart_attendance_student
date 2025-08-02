import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_attendance_student/Profile/Profile.dart';

import 'Login.dart';
import 'Model/Student_Model.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late StudentModel std;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (FirebaseAuth.instance.currentUser != null) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Students')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          std = StudentModel.fromSnapshot(
            userDoc.id,
            userDoc.data() as Map<String, dynamic>,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage(student: std)),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Image.asset('assets/images/Logo.png')));
  }
}
