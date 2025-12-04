import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Model/student_model.dart';
import 'update_profile_screen.dart';

class ShowAllStudent extends StatefulWidget {
  const ShowAllStudent({super.key});

  @override
  State<ShowAllStudent> createState() => _ShowAllStudentState();
}

class _ShowAllStudentState extends State<ShowAllStudent> {
  String? selectedCourse;
  String? selectedSemester;

  final Map<String, List<String>> courseSemesters = {
    'MCA': ['1', '2', '3', '4'],
    'BCA': ['1', '2', '3', '4', '5', '6'],
  };

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

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.cyanAccent),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.cyanAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("All Students"),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 10,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xff0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  /// ---------- FILTER CARD ----------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                dropdownColor: Colors.black,
                                decoration: _inputStyle("Select Course", Icons.school),
                                style: const TextStyle(color: Colors.white),
                                initialValue: selectedCourse,
                                items: courseSemesters.keys.map((course) {
                                  return DropdownMenuItem(
                                    value: course,
                                    child: Text(course,
                                        style: const TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCourse = value;
                                    selectedSemester = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                dropdownColor: Colors.black,
                                decoration:
                                _inputStyle("Select Semester", Icons.calendar_month),
                                style: const TextStyle(color: Colors.white),
                                initialValue: selectedSemester,
                                items: selectedCourse == null
                                    ? []
                                    : courseSemesters[selectedCourse]!.map((sem) {
                                  return DropdownMenuItem(
                                    value: sem,
                                    child: Text(sem,
                                        style: const TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedSemester = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                          _inputStyle("Search name or enrollment", Icons.search),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// ---------- STUDENT LIST ----------
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: selectedCourse == null || selectedSemester == null
                          ? null
                          : FirebaseFirestore.instance
                          .collection('Students')
                          .where("course", isEqualTo: selectedCourse)
                          .where("semester", isEqualTo: selectedSemester)
                          .where('role',isEqualTo: 'student')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.cyanAccent,
                              ));
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No student found",
                              style:
                              TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          );
                        }

                        final students = snapshot.data!.docs
                            .map((doc) => StudentModel.fromSnapshot(
                            doc.id, doc.data() as Map<String, dynamic>))
                            .where((s) {
                          if (_searchQuery.isEmpty) return true;
                          final name = (s.name ?? "").toLowerCase();
                          final enr =
                          (s.enrollment ?? "").toLowerCase();
                          return name.contains(_searchQuery) ||
                              enr.contains(_searchQuery);
                        })
                            .toList();

                        if (students.isEmpty) {
                          return const Center(
                            child: Text(
                              "No matching student",
                              style:
                              TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: students.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final s = students[index];

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: Colors.cyanAccent.withOpacity(0.2),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundImage:
                                  NetworkImage(s.photourl ?? ""),
                                  backgroundColor: Colors.white12,
                                ),
                                title: Text(
                                  s.name ?? "No Name",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Padding(
                                  padding:
                                  const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 10,
                                    children: [
                                      _chip(Icons.badge,
                                          s.enrollment ?? 'N/A'),
                                      _chip(Icons.school,
                                          s.course ?? 'N/A'),
                                      _chip(Icons.calendar_today,
                                          "Sem ${s.semester}"),
                                    ],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.cyanAccent),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                UpdateProfileScreen(
                                                    student: s),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () {
                                        FirebaseFirestore.instance
                                            .collection('Students')
                                            .doc(s.id)
                                            .delete();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.cyanAccent),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black.withOpacity(0.6),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.cyanAccent.withOpacity(.4)),
      ),
    );
  }
}
