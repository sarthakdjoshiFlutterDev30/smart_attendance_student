import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class AttendanceHistory extends StatefulWidget {
  final String sessionId;
  final String enrollmentNumber;

  const AttendanceHistory({
    super.key,
    required this.sessionId,
    required this.enrollmentNumber,
  });

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  @override
  Widget build(BuildContext context) {
    final attendeesRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .collection('attendees')
        .where('enrollmentNo', isEqualTo: widget.enrollmentNumber);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark background
      appBar: AppBar(
        centerTitle: true,
        elevation: 8,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E293B),
                Color(0xFF020617),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Recent Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: attendeesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading attendees',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Shimmer(
                color: Colors.white10,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      "Loading Attendance...",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No attendees yet.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final enrollment = data['enrollmentNo'] ?? '';
              final course = data['course'] ?? '';
              final semester = data['semester'] ?? '';
              final timestamp = data['timestamp'] ?? '';
              final time = data['time'] ?? '';
              final photoUrl = data['photourl'] as String? ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E293B).withOpacity(0.95),
                      const Color(0xFF020617).withOpacity(0.95),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                  border: Border.all(
                    color: Colors.white10,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar with neon border
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF22D3EE),
                            Color(0xFF3B82F6),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white60,
                        )
                            : null,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Text Data
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Enrollment: $enrollment",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "Course: $course  |  Sem: $semester",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: Colors.cyanAccent),
                              const SizedBox(width: 6),
                              Text(
                                timestamp.toString(),
                                style: const TextStyle(color: Colors.white60),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time,
                                  size: 14, color: Colors.cyanAccent),
                              const SizedBox(width: 6),
                              Text(
                                time.toString(),
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status Icon
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.greenAccent,
                      size: 32,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
