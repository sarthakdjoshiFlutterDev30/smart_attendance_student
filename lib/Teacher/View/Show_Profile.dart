import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Model/student_model.dart';
import 'AttendanceSummaryScreen.dart';
import 'update_profile_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<StudentModel>> fetchAllStudents() async {
    final snapshot =
    await FirebaseFirestore.instance.collection("Students").get();

    return snapshot.docs
        .map((doc) => StudentModel.fromSnapshot(doc.id, doc.data()))
        .toList();
  }

  Future<void> deleteStudent(BuildContext context, String docId, String name) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff1a1a1f),
          title: Text(
            "Delete $name?",
            style: const TextStyle(color: Colors.white),
          ),
          content: const Text(
            "This action cannot be undone.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("Students")
                    .doc(docId)
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Student deleted")),
                  );
                }

                if (mounted) Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f0f14),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f0f14),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Student Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // 🔍 Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xff18181f),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search name or enrollment",
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white60),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔽 Student List
            Expanded(
              child: FutureBuilder<List<StudentModel>>(
                future: fetchAllStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Students Found",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  List<StudentModel> students = snapshot.data!;

                  if (_searchQuery.isNotEmpty) {
                    students = students.where((s) {
                      final name = s.name.toLowerCase();
                      final enr = (s.enrollment ?? '').toLowerCase();
                      return name.contains(_searchQuery) ||
                          enr.contains(_searchQuery);
                    }).toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Students: ${students.length}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Expanded(
                        child: ListView.separated(
                          itemCount: students.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final student = students[index];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xff18181f),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                    Colors.grey.shade800,
                                    backgroundImage:
                                    (student.photourl != null &&
                                        student.photourl!.isNotEmpty)
                                        ? NetworkImage(student.photourl!)
                                        : null,
                                    child: (student.photourl == null ||
                                        student.photourl!.isEmpty)
                                        ? const Icon(Icons.person,
                                        color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Enr: ${student.enrollment}",
                                          style: const TextStyle(
                                              color: Colors.white60),
                                        ),
                                        Text(
                                          "${student.course} | Sem ${student.semester}",
                                          style: const TextStyle(
                                              color: Colors.white60),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🔘 Actions
                                  Column(
                                    children: [
                                      IconButton(
                                        tooltip: "Edit",
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  UpdateProfileScreen(
                                                      student: student),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        tooltip: "Attendance",
                                        icon: const Icon(
                                            Icons.insert_chart_outlined,
                                            color: Colors.teal),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AttendanceSummaryScreen(
                                                      enrollmentNo: student
                                                          .enrollment),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        tooltip: "Delete",
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () async {
                                          await deleteStudent(context,
                                              student.id, student.name);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
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
    );
  }
}
