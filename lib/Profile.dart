import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'Login.dart';
import 'Scanner.dart';
import 'Student_Model.dart';

class ProfilePage extends StatefulWidget {
  final StudentModel student;

  ProfilePage({required this.student});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController oldPass = TextEditingController();
  TextEditingController newPass = TextEditingController();
  bool pass1 = true;
  bool pass2 = true;
  @override
  Widget build(BuildContext context) {
    var password=TextEditingController();
    bool pass=true;
    return Scaffold(
      appBar: AppBar(title: Text('Student Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.network(widget.student.photourl,
              width:MediaQuery.of(context).size.width*0.2,
              height:MediaQuery.of(context).size.height*0.2,
            ),
            Text(widget.student.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
            SizedBox(height: 20),
            _buildDetailItem('Email', widget.student.email),
            SizedBox(height: 10),
            _buildDetailItem('Enrollment', widget.student.enrollment),
            SizedBox(height: 10),
            _buildDetailItem('Course', widget.student.course),
            SizedBox(height: 10),
            _buildDetailItem('Semester', widget.student.semester),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentScanner(std: widget.student),
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
            ElevatedButton(
              onPressed: () {
                print("Email=${widget.student.email}");
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(builder: (context, setState) {
                      return AlertDialog(
                        title: Text("Change Password"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: oldPass,
                              obscureText: pass1,
                              decoration: InputDecoration(
                                labelText: "Current Password",
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      pass1 = !pass1;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: newPass,
                              obscureText: pass2,
                              decoration: InputDecoration(
                                labelText: "New Password",
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      pass2 = !pass2;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              oldPass.clear();
                              newPass.clear();
                            },
                            child: Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (oldPass.text.isEmpty || newPass.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Fields cannot be empty")));
                                return;
                              }

                              try {
                                User? user = FirebaseAuth.instance.currentUser;
                                if (user != null && user.email != null) {
                                  AuthCredential credential = EmailAuthProvider.credential(
                                    email: user.email!,
                                    password: oldPass.text,
                                  );

                                  await user.reauthenticateWithCredential(credential);

                                  await user.updatePassword(newPass.text);

                                  await FirebaseFirestore.instance
                                      .collection("Students")
                                      .doc(widget.student.id)
                                      .update({
                                    "password": newPass.text.toString(),
                                  });

                                  Navigator.pop(context);
                                  oldPass.clear();
                                  newPass.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Password changed successfully")));
                                }
                              } on FirebaseAuthException catch (e) {
                                Navigator.pop(context);
                                String msg = "Error: ${e.code}";
                                print(msg);
                                if (e.code == 'wrong-password') {
                                  msg = "Current password is incorrect.";
                                } else if (e.code == 'requires-recent-login') {
                                  msg = "Please sign in again and try.";
                                }else if (e.code == 'invalid-credential') {
                                  msg = "Entered Old Password Is Incorrect";
                                }
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(msg)));
                                oldPass.clear();
                                newPass.clear();
                              }
                            },
                            child: Text("Update"),
                          ),
                        ],
                      );
                    });
                  },
                );
              },
              child: Text("Change Password"),
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
