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
      appBar: AppBar(title: const Text('Recent Attendance'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: attendeesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading attendees'));
          }
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

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No attendees yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 3),
                      color: Colors.black12,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: photoUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(photoUrl),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.person, size: 32),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Enrollment: $enrollment"),
                          Text("Course: $course | Sem: $semester"),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 14),
                              const SizedBox(width: 4),
                              Text(timestamp.toString()),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time, size: 14),
                              const SizedBox(width: 4),
                              Text(time.toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Colors.green),
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
