import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Login.dart';
import '../../Student/Model/Student_Model.dart';
import 'attendance_list_screen.dart';
import 'create_session_screen.dart';

import '../Controller/ApiService.dart';
import '../View/Add_Student.dart';
import '../View/Show All Student.dart';
import '../View/Show_Profile.dart';

class HomeScreen extends StatefulWidget {
    final StudentModel student;

    const HomeScreen({super.key, required this.student});

    @override
    State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final api = ApiService();
    final String faceApiKey = 'BZgv-hUJyvJwdi-ISS5IxsK0IWRn3sln';
    final String faceApiSecret = 'ATjeyYZJQtdc7zeMJFtArdin09z4LOl0';
    CameraController? _cameraController;
    bool _isCameraInitialized = false;
    bool _isCapturing = false;
    bool _faceVerified = false;
    String name="";
    String url="";
    @override
    void initState() {
        // TODO: implement initState
        super.initState();
        print(widget.student.role);
        WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.student.role == 'teacher') {
                    verifyFace();
                }
            });
        name=widget.student.name;
        url=widget.student.photourl;
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
                (camera) => camera.lensDirection == CameraLensDirection.front
            );

            _cameraController = CameraController(
                frontCamera,
                ResolutionPreset.medium,
                enableAudio: false
            );

            await _cameraController!.initialize();

            bool faceFound = false;
            final XFile image = await _cameraController!.takePicture();
            File capturedImage = File(image.path);

            final isMatch = await compareFaces(
                widget.student.photourl,
                capturedImage
            );

            if (isMatch) {
                faceFound = true;
            }

            if (faceFound) {
                _faceVerified = true;

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('✅ Face matched successfully'),
                        backgroundColor: Colors.green
                    )
                );
            } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('❌ Face not matched. Try again.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1)
                    )
                );
                await      Future.delayed(Duration(seconds: 1), () => exit(0));
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
                    backgroundColor: Colors.red
                )
            );

            return false;
        }
    }

    int getCrossAxisCount(double width) {
        if (width < 600) return 2;
        if (width < 900) return 3;
        if (width < 1200) return 4;
        return 5;
    }

    @override
    Widget build(BuildContext context) {
        final todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
        final width = MediaQuery.of(context).size.width;
        final darkGrey = Colors.grey[900];
        final cardGrey = Colors.grey[850];
        final theme = Theme.of(context);

        final List<_DashboardItem> items = [
            _DashboardItem(
                icon: Icons.add_circle_outline,
                label: "Create Session",
                onTap: () => _navigateTo(context,  CreateSessionScreen(Name: widget.student.name,))),
            _DashboardItem(
                icon: Icons.fact_check_outlined,
                label: "Attendance",
                onTap: () => _navigateTo(context, const AttendanceListScreen())),
            _DashboardItem(
                icon: Icons.person_add_alt_rounded,
                label: "Add Student",
                onTap: () => _navigateTo(context, const AddStudent())),
            _DashboardItem(
                icon: Icons.groups_rounded,
                label: "Show Students",
                onTap: () => _navigateTo(context, const ShowAllStudent())),
            _DashboardItem(
                icon: Icons.notifications_active_outlined,
                label: "Notify Students",
                onTap: _showNotificationDialog),
            _DashboardItem(
                icon: Icons.assignment_ind_outlined,
                label: "Student Profile",
                onTap: () => _navigateTo(context, const StudentProfileScreen()))
        ];

        return Scaffold(
            backgroundColor: darkGrey,
            appBar: AppBar(
                title: const Text("Xampus"),
                centerTitle: true,
                elevation: 8,
                backgroundColor: Colors.black,
                actions: [
                    IconButton(
                        tooltip: "Logout",
                        icon: const Icon(Icons.logout),
                        onPressed: _confirmLogout
                    )
                ]
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    children: [
                        // ---------- HEADER ----------
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                    colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400]
                                ),
                                boxShadow: [
                                    BoxShadow(
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                        color: Colors.black.withOpacity(0.4))
                                ]
                            ),
                            child: Row(
                                children: [
                                     CircleAvatar(
                                        radius: 28,
                                        backgroundImage: NetworkImage(
                                            widget.student.photourl)
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                 Text(
                                                    "Welcome ${widget.student.name} 👋",
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white)
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                    "Today : $todayDate",
                                                    style: const TextStyle(
                                                        fontSize: 14, color: Colors.white70)
                                                )
                                            ]
                                        )
                                    )
                                ]
                            )
                        ),
                        const SizedBox(height: 25),

                        // ---------- DASHBOARD GRID ----------
                        GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: items.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: getCrossAxisCount(width),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1
                            ),
                            itemBuilder: (context, index) {
                                final item = items[index];
                                return _buildDashboardCard(item, cardGrey!);
                            }
                        ),
                        const SizedBox(height: 30),

                        // ---------- TODAY SESSIONS ----------
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: cardGrey
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        children: [
                                            const Icon(Icons.event_available, color: Colors.white70),
                                            const SizedBox(width: 10),
                                            const Text(
                                                "Today's Sessions",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)
                                            ),
                                            const Spacer(),
                                            Text(todayDate, style: const TextStyle(color: Colors.white70))
                                        ]
                                    ),
                                    const SizedBox(height: 15),
                                    StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection("sessions")
                                            .where("lecDate", isEqualTo: todayDate)
                                        .orderBy("lecNo")
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                                return const Center(
                                                    child: Padding(
                                                        padding: EdgeInsets.all(20),
                                                        child: CircularProgressIndicator(color: Colors.white)
                                                    ));
                                            }
                                            if (snapshot.data!.docs.isEmpty) {
                                                return const Padding(
                                                    padding: EdgeInsets.all(16),
                                                    child: Text("No sessions today.",
                                                        style: TextStyle(color: Colors.white70))
                                                );
                                            }

                                            return ListView.separated(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemBuilder: (context, index) {
                                                    var data = snapshot.data!.docs[index].data()
                                                    as Map<String, dynamic>;
                                                    return ListTile(
                                                        tileColor: Colors.grey[800],
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12)),
                                                        leading: CircleAvatar(
                                                            backgroundColor: Colors.deepPurple,
                                                            child: Text(
                                                                data['lecNo'] ?? "-",
                                                                style: const TextStyle(color: Colors.white)
                                                            )
                                                        ),
                                                        title: Text(
                                                            data['lecName'] ?? "No Name",
                                                            style: const TextStyle(color: Colors.white)
                                                        )
                                                    );
                                                },
                                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                                itemCount: snapshot.data!.docs.length
                                            );
                                        }
                                    )
                                ]
                            )
                        )
                    ]
                )
            )
        );
    }

    Widget _buildDashboardCard(_DashboardItem item, Color cardGrey) {
        return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: item.onTap,
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400]
                    ),
                    boxShadow: [
                        BoxShadow(
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                            color: Colors.black.withOpacity(0.3))
                    ]
                ),
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.deepPurple,
                                child: Icon(item.icon, color: Colors.white, size: 28)
                            ),
                            const SizedBox(height: 12),
                            Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white)
                            )
                        ]
                    )
                )
            )
        );
    }

    void _navigateTo(BuildContext context, Widget page) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    Future<void> _confirmLogout() async {
        showDialog(
            context: context,
            builder: (_) {
                return AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text("Logout", style: TextStyle(color: Colors.white)),
                    content: const Text("Are you sure you want to logout?",
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel", style: TextStyle(color: Colors.white))),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                            onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('isLoggedIn', false);
                                await FirebaseAuth.instance.signOut();
                                if (!mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const Login()),
                                    (route) => false);
                            },
                            child: const Text("Logout")
                        )
                    ]
                );
            }
        );
    }

    void _showNotificationDialog() {
        showDialog(
            context: context,
            builder: (_) {
                return
                  AlertDialog(
                    backgroundColor: Colors.grey[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: const [
                        Icon(Icons.notifications_active, color: Colors.deepPurple),
                        SizedBox(width: 10),
                        Text("Send Notification", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter title",
                            prefixIcon: const Icon(Icons.title, color: Colors.white),
                            filled: true,
                            fillColor: Colors.black54,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: bodyController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter message",
                            prefixIcon:
                            const Icon(Icons.message, color: Colors.white),
                            filled: true,
                            fillColor: Colors.black54,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty ||
                              bodyController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          await api.sendNotification(
                              titleController.text.trim(), bodyController.text.trim());

                          titleController.clear();
                          bodyController.clear();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Notification sent ✅")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Send"),
                      ),
                    ],
                  );
            });
    }
}

class _DashboardItem {
    final IconData icon;
    final String label;
    final VoidCallback onTap;

    _DashboardItem({
        required this.icon,
        required this.label,
        required this.onTap
    });
}
