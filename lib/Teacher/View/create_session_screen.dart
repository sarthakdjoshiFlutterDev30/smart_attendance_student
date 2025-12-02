import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  String todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

  void showQRCode(String docId) {
    int secondsLeft = 10;
    Timer? timer;

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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Scan QR",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
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
                        fontWeight: FontWeight.w600, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
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
    ).then((_) => timer?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    final darkGrey = Colors.grey[900];
    final cardGrey = Colors.grey[850];
    final colorScheme = Theme.of(context).colorScheme;

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
          // ---------- HEADER ----------
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome, Teacher 👋",
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

          // ---------- SESSION LIST ----------
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
                        child: CircularProgressIndicator(color: Colors.white));
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
                            Colors.deepPurple.withOpacity(0.1),
                            child: const Icon(Icons.book, color: Colors.deepPurple),
                          ),
                          title: Text(
                            data['lecName'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Lecture No: ${data['lecNo']}",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white70),
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection("sessions")
                                  .doc(docId)
                                  .update({
                                'createdAtMillis':
                                DateTime.now().millisecondsSinceEpoch,
                              }).then((_) {
                                showQRCode(docId);
                              });
                            },
                            icon: const Icon(Icons.qr_code, color: Colors.white),
                            label: const Text("Scan",
                                style: TextStyle(color: Colors.white)),
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
