import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'Login.dart';
import 'Scanner.dart';
import 'Student_Model.dart';

class ProfilePage extends StatelessWidget {
  final StudentModel student;

  ProfilePage({required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.network(student.photourl,
              width:MediaQuery.of(context).size.width*0.2,
              height:MediaQuery.of(context).size.height*0.2,
            ),
            Text(student.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
            SizedBox(height: 20),
            _buildDetailItem('Email', student.email),
            SizedBox(height: 10),
            _buildDetailItem('Enrollment', student.enrollment),
            SizedBox(height: 10),
            _buildDetailItem('Course', student.course),
            SizedBox(height: 10),
            _buildDetailItem('Semester', student.semester),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentScanner(std: student),
                  ),
                );
              },
              child: Text("Scan Qrcode"),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_){
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()));
                });
              },
              child: Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
