import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import 'Student/Model/Student_Model.dart';
import 'Student/Profile/Profile.dart';

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
  void sendEmailResetLink(String email) {
    FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((_) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Email Link Sent At:$email"),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "OK",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit app?"),
            content: const Text("Are you sure you want to close the app?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Exit"),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
          return true;
        }
        return false;
      },
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/Background.jpeg",
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(isDark ? 0.60 : 0.45)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                radius: 28,
                                child: Image.asset("assets/images/Logo.png")
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Xampus Login",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Email address",
                              hintText: "name@college.edu",
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            keyboardType: TextInputType.text,
                            obscureText: show,
                            obscuringCharacter: "•",
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    show = !show;
                                  });
                                },
                                icon: Icon(
                                  show
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                if (email.text.isNotEmpty &&
                                    EmailValidator.validate(email.text)) {
                                  sendEmailResetLink(email.text.toString());
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Enter a valid email"),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: const Text("Forgot password?"),
                            ),
                          ),
                          const SizedBox(height: 8),
                          (_isLoading)
                              ? Shimmer(
                                  color: Colors.grey,
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      "Please wait...",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (email.text.trim().isEmpty ||
                                          password.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Enter email and password",
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      } else {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        try {
                                          UserCredential userCredential =
                                              await FirebaseAuth.instance
                                                  .signInWithEmailAndPassword(
                                            email: email.text.trim(),
                                            password: password.text.trim(),
                                          );
                                          print(userCredential);

                                          DocumentSnapshot userDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('Students')
                                                  .doc(userCredential
                                                      .user
                                                      ?.uid)
                                                  .get();

                                          if (userDoc.exists) {
                                            StudentModel student =
                                                StudentModel.fromSnapshot(
                                              userDoc.id,
                                              userDoc.data()
                                                  as Map<String, dynamic>,
                                            );
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfilePage(
                                                        student: student),
                                              ),
                                            );
                                            print(
                                                "User: ${userCredential.user?.uid}");
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'User data not found.'),
                                              ),
                                            );
                                          }
                                        } on FirebaseAuthException catch (e) {
                                          String message;
                                          switch (e.code) {
                                            case 'invalid-email':
                                              message =
                                                  'The email address is not valid.';
                                              break;
                                            case 'user-disabled':
                                              message =
                                                  'The user corresponding to the given email has been disabled.';
                                              break;
                                            case 'user-not-found':
                                              message =
                                                  'No user found for that email.';
                                              break;
                                            case 'wrong-password':
                                              message =
                                                  'Wrong password provided for that user.';
                                              break;
                                            case 'operation-not-allowed':
                                              message =
                                                  'Email/password accounts are not enabled.';
                                              break;
                                            default:
                                              message =
                                                  'An undefined Error happened.';
                                          }

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                              SnackBar(content: Text(message)));
                                        } catch (e) {
                                          print(e.toString());
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'An error occurred: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        } finally {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    },
                                    child: const Text("Sign in"),
                                  ),
                                ),
                          SizedBox(height: 10,),
                          Center(child: Text("Xampus © 2025", style: TextStyle(color: Colors.white, fontSize: 15),))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
