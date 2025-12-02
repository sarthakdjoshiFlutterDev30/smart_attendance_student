import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

          final today = DateTime.now();
          final todayString =
              "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";

          final todaySessions = allSessions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final lecDate = data['lecDate']?.toString().trim() ?? '';
            return lecDate == todayString;
          }).toList();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (todaySessions.isEmpty) {
            return const Center(child: Text("No sessions for today"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: todaySessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = todaySessions[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['lecName'] ?? doc.id;
              final date = data['lecDate'] ?? 'N/A';

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
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
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
