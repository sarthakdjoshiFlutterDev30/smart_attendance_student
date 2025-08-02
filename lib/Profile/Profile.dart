import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_attendance_student/Profile/Created_Session.dart';

import '../Login.dart';
import '../Model/Student_Model.dart';
import 'Scanner.dart';

class ProfilePage extends StatefulWidget {
  final StudentModel student;

  const ProfilePage({super.key, required this.student});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController oldPass = TextEditingController();
  final TextEditingController newPass = TextEditingController();
  bool pass1 = true;
  bool pass2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Student Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: Colors.deepPurple,
        child: Drawer(
          child: Container(
            color: Colors.deepPurple,
            child: Column(
              children: [
                DrawerHeader(
                  child: Text(
                    "Welcome\n${widget.student.name}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreatedSession(student: widget.student),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Icon(Icons.history, color: Colors.white),
                    title: Text(
                      "History",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.white),
                  title: Text(
                    "Settings",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    FirebaseAuth.instance.signOut().then((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    });
                  },
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      "Logout",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(widget.student.photourl),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    widget.student.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                _buildDetailItem('Email', widget.student.email),
                _buildDetailItem('Enrollment', widget.student.enrollment),
                _buildDetailItem('Course', widget.student.course),
                _buildDetailItem('Semester', widget.student.semester),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 10),
                _buildActionButton(
                  Icons.qr_code_scanner,
                  "Scan QR Code",
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentScanner(std: widget.student),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  Icons.lock,
                  "Change Password",
                  Colors.deepPurple,
                  _showPasswordDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPass,
                    obscureText: pass1,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          pass1 ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            pass1 = !pass1;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPass,
                    obscureText: pass2,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          pass2 ? Icons.visibility_off : Icons.visibility,
                        ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent,
                  ),
                  child: const Text(
                    "Update",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword() async {
    if (oldPass.text.isEmpty || newPass.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fields cannot be empty")));
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
            .update({"password": newPass.text});

        Navigator.pop(context);
        oldPass.clear();
        newPass.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully")),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String msg = switch (e.code) {
        'wrong-password' => "Current password is incorrect.",
        'requires-recent-login' => "Please sign in again and try.",
        'invalid-credential' => "Entered Old Password Is Incorrect",
        _ => "Error: ${e.code}",
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      oldPass.clear();
      newPass.clear();
    }
  }
}
