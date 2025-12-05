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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xff0F172A), // Premium dark
      appBar: AppBar(
        title: const Text(
          "Created Sessions",
          style: TextStyle(color: Colors.white,   fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff020617),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .orderBy('createdAtMillis', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );
          }

          final allSessions = snapshot.data!.docs;

          final today = DateTime.now();
          final todayString =
              "${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}";

          final todaySessions = allSessions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final lecDate = data['lecDate']?.toString().trim() ?? '';
            return lecDate == todayString;
          }).toList();

          if (todaySessions.isEmpty) {
            return const Center(
              child: Text(
                "No sessions for today",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: todaySessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = todaySessions[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['lecName'] ?? doc.id;
              final date = data['lecDate'] ?? 'N/A';

              return InkWell(
                borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),

                    // 🔥 Premium Gradient
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xff1E293B),
                        const Color(0xff0F172A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),

                    // Soft border
                    border: Border.all(
                      color: Colors.white10,
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo,
                              Colors.blueAccent.shade200
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.event_note,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toString(),
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14, color: Colors.white54),
                                const SizedBox(width: 6),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.white70,
                        ),
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
