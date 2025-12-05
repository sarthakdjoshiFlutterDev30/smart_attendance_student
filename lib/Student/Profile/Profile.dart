import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:xampus_student/Student/Profile/Created_Session.dart';
import 'package:xampus_student/Student/Profile/Scanner.dart';

import '../../Login.dart';
import '../../Teacher/View/Home.dart';
import '../../main.dart';
import '../Model/Student_Model.dart';
import '../Project/project_screen.dart';
import 'AttendanceSummaryScreen.dart';
import 'My Qr Code.dart';
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

  // ⚠️ Security Note: It is best practice to move these keys to a secure backend or .env file
  final String faceApiKey = 'BZgv-hUJyvJwdi-ISS5IxsK0IWRn3sln';
  final String faceApiSecret = 'ATjeyYZJQtdc7zeMJFtArdin09z4LOl0';

  CameraController? _cameraController;
  bool _isCameraInitialized = false; // Kept for future use if needed
  bool _isCapturing = false;
  bool _faceVerified = false;
  String docId2 = "";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.student.role == 'teacher') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are a teacher')),
        );
      }
    });

    requestCameraPermission();

    // Auto-verification logic for students
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.student.role == 'student') {
        verifyFace();
      }
    });

    // Periodic check every 10 minutes
    Timer.periodic(const Duration(minutes: 10), (timer) {
      if (mounted) verifyFace();
    });

    listenNotificationFromFirestore();
  }

  Future<bool> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      print("✅ Camera permission already granted");
      return true;
    }

    status = await Permission.camera.request();

    if (status.isGranted) {
      print("✅ Camera permission granted");
      return true;
    } else if (status.isDenied) {
      print("❌ Camera permission denied");
      return false;
    } else if (status.isPermanentlyDenied) {
      print("⚠️ Camera permission permanently denied");
      openAppSettings();
      return false;
    }
    return false;
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

  Future<void> listenNotificationFromFirestore() async {
    FirebaseFirestore.instance
        .collection("notification")
        .snapshots()
        .listen((snapshot) async {

      if (!mounted) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);

      double myLat = position.latitude;
      double myLng = position.longitude;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {

          final data = change.doc.data() as Map<String, dynamic>;

          String course = data['course'] ?? '';
          String semester = data['semester'] ?? '';
          double lat = double.tryParse(data['lat'].toString()) ?? 0.0;
          double lng = double.tryParse(data['log'].toString()) ?? 0.0;
          String docId = data['docId'] ?? change.doc.id;


          double distance = Geolocator.distanceBetween(
            myLat,
            myLng,
            lat,
            lng,
          );
          print("Doc ID : $docId");
          print("Distance : ${distance.toStringAsFixed(2)} meters");

          if (distance <= 200 &&
              course.toUpperCase().trim() == widget.student.course &&
              semester == widget.student.semester) {
            print("✅ CONDITIONS MET - STARTING AUTOMATIC ATTENDANCE");
            print("Doc ID : $docId");
            print("Distance : ${distance.toStringAsFixed(2)} meters");

            if (mounted) {
              setState(() {
                docId2 = docId;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Attendance Available: $docId2"))
              );
    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Attendance Available: $distance"))
              );

              verifyFaceAndMarkAttendance(docId2);
            }

            // Trigger Local Notification
            await showLocalNotification(
                "Attendance Started for $course $semester\nDocId: $docId");
          }
        }
      }
    });
  }

  Future<void> showLocalNotification(String msg) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Channel',
      channelDescription: 'Attendance Channel',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '📢 Attendance Alert',
      msg,
      details,
      payload: 'OPEN_APP',
    );
  }

  Future<void> verifyFaceAndMarkAttendance(String sessionId) async {
    if (!mounted) return;

    try {
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Invalid session ID.')));
        }
        return;
      }

      final sessionData = sessionDoc.data();
      final String subject = (sessionData != null && sessionData['subject'] is String)
          ? (sessionData['subject'] as String)
          : 'Unknown';

      final createdAtMillis = sessionDoc.data()?['createdAtMillis'];
      if (createdAtMillis == null) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Invalid session data.')));
        }
        return;
      }

      final createdTime = DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
      final now = DateTime.now();
      print("Difference: ${now.difference(createdTime).inSeconds} seconds");

      final attendeeQuery = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('attendees')
          .where('enrollmentNo', isEqualTo: widget.student.enrollment)
          .where('subject', isEqualTo: subject)
          .get();

      if (attendeeQuery.docs.isNotEmpty) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('⚠️ Attendance already marked!')));
        }
        return;
      }

      // Open Camera
      final XFile? pickedImage = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedImage == null) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No image selected.')));
        }
        return;
      }

      final match = await compareFaces(
        widget.student.photourl,
        File(pickedImage.path),
      );

      if (match) {
        await _markAttendance(sessionId, subject);
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Face matched. Attendance marked!')));
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Face not matched!')));
        }
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _markAttendance(String sessionId, String subject) async {
    final now = DateTime.now();
    String date = DateFormat('dd-MM-yyyy').format(now);
    String time = DateFormat('HH:mm:ss').format(now);

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('attendees')
        .add({
      'name': widget.student.name,
      'enrollmentNo': widget.student.enrollment,
      'course': widget.student.course,
      'semester': widget.student.semester,
      'photourl': widget.student.photourl,
      'subject': subject,
      'timestamp': date,
      'time': time,
    });
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

      if (!mounted) return false;

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
        // Exiting app on failure as per original logic
        await Future.delayed(const Duration(seconds: 1), () => exit(0));
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

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if(mounted) {
        setState(() {
          locationMessage = "Location permission denied";
        });
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    if(mounted) {
      setState(() {
        locationMessage =
        "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      });
    }
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
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Exit"),
                )
              ],
            ),
          );
          if (shouldExit == true) {
            Navigator.of(context).pop(true);
          }
          return shouldExit ?? false;
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Student Profile')),
          drawer: Drawer(
            child: Container(
              color: Theme.of(context).colorScheme.primary,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(widget.student.name,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary)),
                    accountEmail: Text(widget.student.email,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary)),
                    currentAccountPicture: CircleAvatar(
                      backgroundImage: NetworkImage(widget.student.photourl),
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                  ExpansionTile(
                    collapsedIconColor: Theme.of(context).colorScheme.onPrimary,
                    iconColor: Theme.of(context).colorScheme.onPrimary,
                    leading: Icon(Icons.school,
                        color: Theme.of(context).colorScheme.onPrimary),
                    title: Text("Attendance",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary)),
                    children: [
                      // History
                      ListTile(
                        leading: Icon(Icons.history,
                            color: Theme.of(context).colorScheme.onPrimary),
                        title: Text("History",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onPrimary)),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CreatedSession(student: widget.student)));
                        },
                      ),
                      // Attendance Summary
                      ListTile(
                        leading: Icon(Icons.bar_chart,
                            color: Theme.of(context).colorScheme.onPrimary),
                        title: Text("Attendance Summary",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onPrimary)),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AttendanceSummaryScreen(
                                      enrollmentNo: widget.student.enrollment)));
                        },
                      ),
                      // Scan Profile QR
                      ListTile(
                        leading: Icon(Icons.qr_code,
                            color: Theme.of(context).colorScheme.onPrimary),
                        title: Text("Scan Profile QR Code",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onPrimary)),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ScannerProfile()));
                        },
                      )
                    ],
                  ),
                  ExpansionTile(
                    collapsedIconColor: Theme.of(context).colorScheme.onPrimary,
                    iconColor: Theme.of(context).colorScheme.onPrimary,
                    leading: FaIcon(FontAwesomeIcons.vault,
                        color: Theme.of(context).colorScheme.onPrimary),
                    title: Text("Project Vault",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary)),
                    children: [
                      ListTile(
                        leading: FaIcon(FontAwesomeIcons.filePdf,
                            color: Theme.of(context).colorScheme.onPrimary),
                        title: Text("View/Upload Projects",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onPrimary)),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProjectScreen()));
                        },
                      ),
                    ],
                  ),
                  Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.5)),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text("Logout",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.redAccent)),
                    onTap: () {
                      FirebaseAuth.instance.signOut().then((_) {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) => Login()));
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const Center(
                      child: Text("Xampus © 2025",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)))
                ],
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    Center(
                      child: CircleAvatar(
                          radius: 60,
                          backgroundImage:
                          NetworkImage(widget.student.photourl)),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(widget.student.name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                    _buildActionButton(Icons.qr_code, "View QR Code",
                        Colors.green, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      My_Qr_Code(std: widget.student)));
                        }),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300),
                    _buildDetailItem('Email', widget.student.email),
                    _buildDetailItem('Enrollment', widget.student.enrollment),
                    _buildDetailItem('Course', widget.student.course),
                    _buildDetailItem('Semester', widget.student.semester),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    _buildActionButton(Icons.qr_code, "Scan Session Qr code ",
                        Colors.deepPurple, ()=>Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StudentScanner(std: widget.student)))),
                  const SizedBox(height: 10),
                    _buildActionButton(Icons.lock, "Change Password",
                        Colors.deepPurple, _showPasswordDialog)
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(child: HomeScreen(student: widget.student)),
      );
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16)))
      ]),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
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
                borderRadius: BorderRadius.circular(12))),
        onPressed: onPressed,
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Change Password"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: oldPass,
                obscureText: pass1,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  suffixIcon: IconButton(
                    icon: Icon(pass1 ? Icons.visibility_off : Icons.visibility),
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
                    icon: Icon(pass2 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        pass2 = !pass2;
                      });
                    },
                  ),
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  oldPass.clear();
                  newPass.clear();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child:
                const Text("Cancel", style: TextStyle(color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent),
                child:
                const Text("Update", style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _changePassword() async {
    if (oldPass.text.isEmpty || newPass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fields cannot be empty")));
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential =
        EmailAuthProvider.credential(email: user.email!, password: oldPass.text);

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPass.text);

        await FirebaseFirestore.instance
            .collection("Users")
            .doc(widget.student.id)
            .update({"password": newPass.text});

        if (mounted) Navigator.pop(context);
        oldPass.clear();
        newPass.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Password changed successfully")));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      String msg = switch (e.code) {
        'wrong-password' => "Current password is incorrect.",
        'requires-recent-login' => "Please sign in again and try.",
        'invalid-credential' => "Entered Old Password Is Incorrect",
        _ => "Error: ${e.code}"
      };
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
      oldPass.clear();
      newPass.clear();
    }
  }
}