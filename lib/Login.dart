import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance_student/Profile.dart';
import 'Student_Model.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var email = TextEditingController();
  var password = TextEditingController();
  bool _isLoading = false;
  bool show = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage("assets/images/Background.jpeg"),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: email,
                style: const TextStyle(fontSize: 20, color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter Email Address",
                  hintStyle: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: password,
                style: const TextStyle(fontSize: 20, color: Colors.white),
                keyboardType: TextInputType.text,
                obscureText: show,
                obscuringCharacter: "*",
                decoration: InputDecoration(
                  suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {
                        show = !show;
                      });
                    },
                    child: Text(
                      (show) ? "Show" : "Hide",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  hintText: "Enter Password",
                  hintStyle: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              (_isLoading)
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () async {
                  if (email.text.trim().isEmpty ||
                      password.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Enter Email Or Password",
                          style: TextStyle(fontSize: 18),
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      UserCredential userCredential = await FirebaseAuth.instance
                          .signInWithEmailAndPassword(
                        email: email.text.trim(),
                        password: password.text.trim(),
                      );
                      print(userCredential);

                      // Fetch user data from Firestore
                      DocumentSnapshot userDoc = await FirebaseFirestore.instance
                          .collection('Students') // Adjust the collection name as needed
                          .doc(userCredential.user?.uid) // Use the user's UID
                          .get();

                      if (userDoc.exists) {
                        StudentModel student = StudentModel.fromSnapshot(
                          userDoc.id,
                          userDoc.data() as Map<String, dynamic>,
                        );

                        // Navigate to ProfilePage with the student data
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(student: student),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User  data not found.'),
                          ),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String message;
                      switch (e.code) {
                        case 'invalid-email':
                          message = 'The email address is not valid.';
                          break;
                        case 'user-disabled':
                          message = 'The user corresponding to the given email has been disabled.';
                          break;
                        case 'user-not-found':
                          message = 'No user found for that email.';
                          break;
                        case 'wrong-password':
                          message = 'Wrong password provided for that user.';
                          break;
                        case 'operation-not-allowed':
                          message = 'Email/password accounts are not enabled.';
                          break;
                        default:
                          message = 'An undefined Error happened.';
                      }

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('An error occurred: ${e.toString()}'),
                        ),
                      );
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                  "Login",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}