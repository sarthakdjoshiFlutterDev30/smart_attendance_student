import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../Model/Student_Model.dart';
import 'Attendance_History.dart';

class CreatedSession extends StatefulWidget {
  final StudentModel student;

  const CreatedSession({super.key, required this.student});

  @override
  State<CreatedSession> createState() => _CreatedSessionState();
}

class _CreatedSessionState extends State<CreatedSession> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Created Sessions"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .orderBy('createdAtMillis', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final allSessions = snapshot.data!.docs;

          final seenNames = <String>{};
          final uniqueSessions = allSessions.where((doc) {
            final name =
                (doc.data() as Map<String, dynamic>)['name']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';
            if (seenNames.contains(name)) {
              return false;
            } else {
              seenNames.add(name);
              return true;
            }
          }).toList();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Shimmer(
                color: Colors.grey,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    textAlign: TextAlign.center,
                    "Please Wait ...",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }
          final docs = uniqueSessions;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['name'] ?? doc.id;
              final timestamp = data['timestamp'] ?? '';
              final createdAtMillis = data['createdAtMillis'];

              String subtitle = "ID: ${doc.id}";
              if (timestamp != '') {
                subtitle = timestamp.toString();
              } else if (createdAtMillis != null) {
                final dt = DateTime.fromMillisecondsSinceEpoch(
                  int.tryParse(createdAtMillis.toString()) ?? 0,
                );
                subtitle =
                    "Recent Session:  ${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceHistory(
                        sessionId: doc.id,
                        enrollmentNumber: widget.student.enrollment,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        offset: Offset(0, 2),
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_note,
                        size: 32,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(subtitle),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
