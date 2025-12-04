import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreateSessionScreen extends StatefulWidget {
  final String Name;
  const CreateSessionScreen({super.key, required this.Name});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String locationMessage = "";
  double lat = 0.0;
  double log = 0.0;
  Map<String, bool> switchStates = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // ================= GET LOCATION =================
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        locationMessage = "Location permission denied";
      });
      return;
    }

    Position position =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      lat = position.latitude;
      log = position.longitude;
      locationMessage = "Latitude: $lat , Longitude: $log";
    });

    print("Teacher Location => $locationMessage");
  }

  // ================= SHOW QR =================
  void showQRCode(String docId,String Name,String course,String semester) {
    int secondsLeft = 10;
    Timer? timer;
    FirebaseFirestore.instance
        .collection("notification")
        .doc(docId)
        .set({
      'docId': docId,
      'lat':lat,
      'log':log,
      'course':course,
      'semester':semester});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (secondsLeft > 1) {
              setState(() {
                secondsLeft--;
              });
            } else {
              t.cancel();
              Navigator.pop(context);
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.grey[900],
            title:  Column(
              children: [
                Text(
                  "Lec Name=$Name",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 10,),
                Text(
                  "Lec ID : $docId",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            content: SizedBox(
              width: 250,
              height: 270,
              child: Column(
                children: [
                  QrImageView(
                    data: docId,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Expires in $secondsLeft seconds",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
            if (mounted) {
              this.setState(() {
                switchStates[docId] = false;
              });
            }
            FirebaseFirestore.instance
                .collection("sessions")
                .doc(docId)
                .update({'isActive': false});
                 timer?.cancel();
            FirebaseFirestore.instance.collection("notification").doc(docId).delete();

            Navigator.pop(context);

                },
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    ).then((_){
      if (mounted) {
        this.setState(() {
          switchStates[docId] = false;
        });
      }
      FirebaseFirestore.instance.collection("notification").doc(docId).delete();
      FirebaseFirestore.instance
          .collection("sessions")
          .doc(docId)
          .update({'isActive': false});
      timer?.cancel();

    });
  }

  @override
  Widget build(BuildContext context) {
    final darkGrey = Colors.grey[900];
    final cardGrey = Colors.grey[850];

    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        elevation: 0,
        title: const Text("Smart Attendance"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // ---------------- HEADER ----------------
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.deepPurple.shade400
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.Name} 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Today : $todayDate",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---------------- SESSION LIST ----------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sessions')
                    .orderBy('lecNo')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  final todaySessions = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['lecDate'] == todayDate;
                  }).toList();

                  if (todaySessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.event_busy,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            "No Sessions For Today",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: todaySessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final doc = todaySessions[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;

                      return Container(
                        decoration: BoxDecoration(
                          color: cardGrey,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor:
                            Colors.deepPurple.withOpacity(0.2),
                            child: const Icon(Icons.book,
                                color: Colors.deepPurple),
                          ),
                          title: Text(
                            data['lecName'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Lecture No: ${data['lecNo']}",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white70),
                            ),
                          ),

                          trailing: Switch(
                            value: switchStates[docId] ?? false,
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            onChanged: (value) {
                              setState(() {
                                switchStates[docId] = value;
                              });

                              if (value == true) {
                                print("Latitude : $lat");
                                print("Longitude : $log");

                                FirebaseFirestore.instance
                                    .collection("sessions")
                                    .doc(docId)
                                    .update({
                                  'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
                                  'lat': lat,
                                  'log': log,
                                  'isActive': true
                                }).then((_) {
                                  showQRCode(docId,data['lecName'] ?? '',data['course'] ?? '',data['semester'] ?? '');
                                }).catchError((error) {
                                  print('Error updating session: $error');
                                });
                              } else {
                                FirebaseFirestore.instance
                                    .collection("sessions")
                                    .doc(docId)
                                    .update({'isActive': false});
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
