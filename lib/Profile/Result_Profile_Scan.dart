import 'package:flutter/material.dart';
import 'package:smart_attendance_student/Model/Student_Model.dart';

class ResultProfileScan extends StatefulWidget {
  final StudentModel student;
  const ResultProfileScan({super.key, required this.student});

  @override
  State<ResultProfileScan> createState() => _ResultProfileScanState();
}

class _ResultProfileScanState extends State<ResultProfileScan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Result Profile Scan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(widget.student.photourl),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    widget.student.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                _buildDetailItem('Email', widget.student.email),
                _buildDetailItem('Enrollment', widget.student.enrollment),
                _buildDetailItem('Course', widget.student.course),
                _buildDetailItem('Semester', widget.student.semester),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildDetailItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    ),
  );
}
