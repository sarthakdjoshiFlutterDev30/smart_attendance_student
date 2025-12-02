import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  String? selectedSessionId;
  String? selectedSessionName;

  Future<void> _exportToCSV(List<QueryDocumentSnapshot> docs) async {
    List<List<String>> data = [
      ['Name', 'EnrollmentNo', 'Course', 'Semester', 'Date', 'Time'],
      ...docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return [
          d['name'] ?? '',
          d['enrollmentNo'] ?? '',
          d['course'] ?? '',
          d['semester'] ?? '',
          d['timestamp'] ?? '',
          d['time'] ?? '',
        ];
      }),
    ];

    final csvData = const ListToCsvConverter().convert(data);
    final bytes = utf8.encode(csvData);

    await FileSaver.instance.saveFile(
      name: "$selectedSessionName-attendance",
      bytes: bytes,
      fileExtension: "csv",
      mimeType: MimeType.csv,
    );
  }

  @override
  Widget build(BuildContext context) {
    String date = DateFormat('dd-MM-yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Reports"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              // -------- SESSION DROPDOWN ----------
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sessions')
                    .where('lecDate', isEqualTo: date)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allSessions = snapshot.data!.docs;

                  final seenNames = <String>{};
                  final uniqueSessions = allSessions.where((doc) {
                    final name =
                        (doc.data() as Map<String, dynamic>)['lecName']
                            ?.toString()
                            .trim()
                            .toLowerCase() ??
                            '';
                    if (seenNames.contains(name)) return false;
                    seenNames.add(name);
                    return true;
                  }).toList();

                  return Container(
                    width: double.infinity, // << mobile fix
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade700),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true, // << mobile fix
                        value: selectedSessionId,
                        hint: const Text(
                          "Select Session",
                          style: TextStyle(fontSize: 16),
                        ),
                        onChanged: (value) {
                          final session = uniqueSessions.firstWhere(
                                (s) => s.id == value,
                          );
                          final sessionData =
                          session.data() as Map<String, dynamic>;

                          setState(() {
                            selectedSessionId = value;
                            selectedSessionName =
                                sessionData['lecName'] ?? 'session';
                          });
                        },
                        items: uniqueSessions.map((session) {
                          final name =
                              (session.data() as Map)['lecName'] ?? '';

                          return DropdownMenuItem(
                            value: session.id,
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              // ------------ ATTENDEES LIST ------------
              if (selectedSessionId != null)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sessions')
                        .doc(selectedSessionId)
                        .collection('attendees')
                        .orderBy('enrollmentNo')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final attendees = snapshot.data!.docs;

                      if (attendees.isEmpty) {
                        return const Center(
                          child: Text(
                            "No attendance found",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: attendees.length,
                              itemBuilder: (context, index) {
                                final data = attendees[index].data()
                                as Map<String, dynamic>;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                        Colors.blue.shade200,
                                        radius: 22,
                                        child: Text(
                                          data['name']
                                              ?.toString()
                                              .substring(0, 1)
                                              .toUpperCase() ??
                                              '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        data['name'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding:
                                        const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Enrollment: ${data['enrollmentNo'] ?? 'N/A'}"
                                              "\nCourse: ${data['course'] ?? 'N/A'} | Sem: ${data['semester'] ?? 'N/A'}",
                                          style: const TextStyle(
                                              fontSize: 13),
                                        ),
                                      ),
                                      trailing: Text(
                                        "${data['timestamp'] ?? ''}\n${data['time'] ?? ''}",
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      isThreeLine: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          // -------- EXPORT BUTTON ----------
                          SizedBox(
                            width: double.infinity,
                            height: 55, // Mobile height ✅
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text(
                                "Export CSV",
                                style: TextStyle(letterSpacing: 0.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                await _exportToCSV(attendees);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
