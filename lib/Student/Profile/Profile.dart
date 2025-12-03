import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:xampus_student/Student/Profile/Created_Session.dart';
import 'package:xampus_student/Teacher/View/Home.dart';

import '../../Login.dart';
import '../Model/Student_Model.dart';
import '../Project/project_screen.dart';
import '../Provider.dart';
import 'AttendanceSummaryScreen.dart';
import 'My Qr Code.dart';
import 'Scanner.dart';
import 'Scanner_Profile.dart';

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
    String locationMessage = "";
    final String faceApiKey = 'BZgv-hUJyvJwdi-ISS5IxsK0IWRn3sln';
    final String faceApiSecret = 'ATjeyYZJQtdc7zeMJFtArdin09z4LOl0';
    CameraController? _cameraController;
    bool _isCameraInitialized = false;
    bool _isCapturing = false;
    bool _faceVerified = false;

    @override
    void initState() {
        // TODO: implement initState
        super.initState();
        _getCurrentLocation();
         WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.student.role == 'teacher') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are a teacher')),
        );
      }
    });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.student.role == 'student') {
            verifyFace();
          }
        });
        Timer.periodic(const Duration(minutes: 10), (timer) {
          if (mounted) verifyFace();
        });

    }

    Future<bool> compareFaces(String imageUrl1, File image2) async {
      try {
        final uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/compare');

        final request = http.MultipartRequest('POST', uri)
          ..fields['api_key'] = faceApiKey
          ..fields['api_secret'] = faceApiSecret
          ..fields['image_url1'] = imageUrl1
          ..files.add(await http.MultipartFile.fromPath('image_file2', image2.path));

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);

        if (data.containsKey('confidence')) {
          double confidence = (data['confidence'] as num).toDouble();
          print("Face Match Confidence: $confidence");

          return confidence >= 70.0;
        }

        return false;
      } catch (e) {
        print("Compare Face Error: $e");
        return false;
      }
    }

    Future<bool> verifyFace() async {
      if (_faceVerified || _isCapturing) return false;
      _isCapturing = true;

      try {
        final cameras = await availableCameras();

        final frontCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        bool faceFound = false;

          final XFile image = await _cameraController!.takePicture();
          File capturedImage = File(image.path);

          final isMatch = await compareFaces(
            widget.student.photourl,
            capturedImage,
          );

          if (isMatch) {
            faceFound = true;
          }


        if (faceFound) {
          _faceVerified = true;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Face matched successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Face not matched. Try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
         await Future.delayed(Duration(seconds: 1),() => exit(0));
        }

        await _cameraController!.dispose();
        _cameraController = null;
        _isCapturing = false;

        return faceFound;
      } catch (e) {
        print("Verify Face Error: $e");

        if (_cameraController != null) {
          await _cameraController!.dispose();
          _cameraController = null;
        }

        _isCapturing = false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face verification failed'),
            backgroundColor: Colors.red,
          ),
        );

        return false;
      }
    }



    Future<void> _getCurrentLocation() async {
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
            setState(() {
                    locationMessage = "Location permission denied";
                });
            return;
        }

        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high

        );

        setState(() {
                locationMessage =
                "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
            });
        print(locationMessage);
    }

    @override
    Widget build(BuildContext context) {
        if (widget.student.role == 'student') {
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
                                child: const Text("Cancel")
                            ),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Exit")
                            )
                        ]
                    )
                );
                if (shouldExit == true) {
                    Navigator.of(context).pop(true);
                }
                return shouldExit ?? false;
            },
            child: Scaffold(
                appBar: AppBar(
                    title: const Text('Student Profile')
                ),
                drawer: Drawer(
                    child: Container(
                        color: Theme.of(context).colorScheme.primary,
                        child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                                UserAccountsDrawerHeader(
                                    accountName: Text(widget.student.name, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                                    accountEmail: Text(widget.student.email, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                                    currentAccountPicture: CircleAvatar(
                                        backgroundImage: NetworkImage(widget.student.photourl),
                                    ),
                                    decoration: BoxDecoration(
                                        color: Colors.transparent,
                                    ),
                                ),
                                ExpansionTile(
                                    collapsedIconColor: Theme.of(context).colorScheme.onPrimary,
                                    iconColor: Theme.of(context).colorScheme.onPrimary,
                                    leading: Icon(Icons.school,
                                        color: Theme.of(context).colorScheme.onPrimary),
                                    title: Text(
                                        "Attendance",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Theme.of(context).colorScheme.onPrimary
                                        )
                                    ),
                                    children: [

                                        // History
                                        ListTile(
                                            leading: Icon(Icons.history,
                                                color: Theme.of(context).colorScheme.onPrimary),
                                            title: Text(
                                                "History",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context).colorScheme.onPrimary
                                                )
                                            ),
                                            onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                        CreatedSession(student: widget.student)
                                                    )
                                                );
                                            }
                                        ),

                                        // Attendance Summary
                                        ListTile(
                                            leading: Icon(Icons.bar_chart,
                                                color: Theme.of(context).colorScheme.onPrimary),
                                            title: Text(
                                                "Attendance Summary",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context).colorScheme.onPrimary
                                                )
                                            ),
                                            onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) => AttendanceSummaryScreen(
                                                            enrollmentNo: widget.student.enrollment
                                                        )
                                                    )
                                                );
                                            }
                                        ),


                                        // Scan Profile QR
                                        ListTile(
                                            leading: Icon(Icons.qr_code,
                                                color: Theme.of(context).colorScheme.onPrimary),
                                            title: Text(
                                                "Scan Profile QR Code",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context).colorScheme.onPrimary
                                                )
                                            ),
                                            onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) => ScannerProfile()
                                                    )
                                                );
                                            }
                                        )
                                    ]
                                ),
                                ExpansionTile(
                                    collapsedIconColor: Theme.of(context).colorScheme.onPrimary,
                                    iconColor: Theme.of(context).colorScheme.onPrimary,
                                    leading: FaIcon(FontAwesomeIcons.vault,
                                        color: Theme.of(context).colorScheme.onPrimary),
                                    title: Text(
                                        "Project Vault",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Theme.of(context).colorScheme.onPrimary
                                        )
                                    ),
                                    children: [
                                        ListTile(
                                            leading: FaIcon(FontAwesomeIcons.filePdf,
                                                color: Theme.of(context).colorScheme.onPrimary),
                                            title: Text(
                                                "View/Upload Projects",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context).colorScheme.onPrimary
                                                )
                                            ),
                                            onTap: () {
                                               Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectScreen(),));
                                            }
                                        ),
                                    ]
                                ),
                                Divider(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)),
                              // Change Theme
                              ListTile(
                                  leading: Icon(Icons.nightlight_sharp,
                                      color: Theme.of(context).colorScheme.onPrimary),
                                  title: Text(
                                      "Change Your Theme",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onPrimary
                                      )
                                  ),
                                  onTap: () {
                                    Provider.of<ThemeProvider>(
                                        context,
                                        listen: false
                                    ).toggleTheme(context);
                                  }
                              ),

                              ListTile(
                                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                                    title: const Text(
                                        "Logout",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Colors.redAccent
                                        )
                                    ),
                                    onTap: () {
                                        FirebaseAuth.instance.signOut().then((_) {
                                                Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => Login())
                                                );
                                            });
                                    }
                                ),
                              SizedBox(height: 10,),
                              Center(child: Text("Xampus © 2025", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold, fontSize: 15),))

                            ]
                        )

                    )
                ),
                body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)
                        ),
                        child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ListView(
                                children: [
                                    Center(
                                        child: CircleAvatar(
                                            radius: 60,
                                            backgroundImage: NetworkImage(widget.student.photourl)
                                        )
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                        child: Text(
                                            widget.student.name,
                                            style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold
                                            )
                                        )
                                    ),
                                    const SizedBox(height: 20),
                                    _buildActionButton(
                                        Icons.qr_code,
                                        "View QR Code",
                                        Colors.green,
                                        () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) => My_Qr_Code(std: widget.student)
                                                )
                                            );
                                        }
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
                                                    StudentScanner(std: widget.student)
                                                )
                                            );
                                        }
                                    ),
                                    _buildActionButton(
                                        Icons.lock,
                                        "Change Password",
                                        Colors.deepPurple,
                                        _showPasswordDialog
                                    )
                                ]
                            )
                        )
                    )
                )
            )
        );
    } else {
      return Scaffold(
        body: Center(
          child: HomeScreen(student: widget.student,)
        ),
      );
    }
    }

    Widget _buildDetailItem(String label, String value) {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        '$label: ',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                    ),
                    Expanded(child: Text(value, style: const TextStyle(fontSize: 16)))
                ]
            )
        );
    }

    Widget _buildActionButton(
        IconData icon,
        String label,
        Color color,
        VoidCallback onPressed
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
                        borderRadius: BorderRadius.circular(12)
                    )
                ),
                onPressed: onPressed
            )
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
                                                    pass1 ? Icons.visibility_off : Icons.visibility
                                                ),
                                                onPressed: () {
                                                    setState(() {
                                                            pass1 = !pass1;
                                                        });
                                                }
                                            )
                                        )
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                        controller: newPass,
                                        obscureText: pass2,
                                        decoration: InputDecoration(
                                            labelText: "New Password",
                                            suffixIcon: IconButton(
                                                icon: Icon(
                                                    pass2 ? Icons.visibility_off : Icons.visibility
                                                ),
                                                onPressed: () {
                                                    setState(() {
                                                            pass2 = !pass2;
                                                        });
                                                }
                                            )
                                        )
                                    )
                                ]
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
                                        style: TextStyle(color: Colors.black)
                                    )
                                ),
                                ElevatedButton(
                                    onPressed: _changePassword,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.lightGreenAccent
                                    ),
                                    child: const Text(
                                        "Update",
                                        style: TextStyle(color: Colors.black)
                                    )
                                )
                            ]
                        );
                    }
                );
            }
        );
    }

    Future<void> _changePassword() async {
        if (oldPass.text.isEmpty || newPass.text.isEmpty) {
            ScaffoldMessenger.of(
                context
            ).showSnackBar(const SnackBar(content: Text("Fields cannot be empty")));
            return;
        }

        try {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null && user.email != null) {
                AuthCredential credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPass.text
                );

                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPass.text);

                await FirebaseFirestore.instance
                    .collection("Users")
                    .doc(widget.student.id)
                    .update({"password": newPass.text});

                Navigator.pop(context);
                oldPass.clear();
                newPass.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password changed successfully"))
                );
            }
        } on FirebaseAuthException catch (e) {
            Navigator.pop(context);
            String msg = switch (e.code) {
                'wrong-password' => "Current password is incorrect.",
                'requires-recent-login' => "Please sign in again and try.",
                'invalid-credential' => "Entered Old Password Is Incorrect",
                _ => "Error: ${e.code}"
            };
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            oldPass.clear();
            newPass.clear();
        }
    }
}
