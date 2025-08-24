import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  final String enrollmentNo;
  const AttendanceSummaryScreen({super.key, required this.enrollmentNo});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  Map<String, int> totalLectures = {};
  Map<String, int> attendedLectures = {};
  bool _isLoading = true;
  double overallPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final sessionSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .get();

      Map<String, Set<String>> uniqueLectures = {};
      Map<String, int> tempAttended = {};

      for (var session in sessionSnapshot.docs) {
        final data = session.data();
        String subject = (data['lecName'] ?? 'Unknown').toString().trim();
        String lecNo = (data['lecNo'] ?? session.id).toString();

        uniqueLectures.putIfAbsent(subject, () => {});
        uniqueLectures[subject]!.add(lecNo);
        final attendeeSnapshot = await FirebaseFirestore.instance
            .collection('sessions')
            .doc(session.id)
            .collection('attendees')
            .where('enrollmentNo', isEqualTo: widget.enrollmentNo)
            .get();

        if (attendeeSnapshot.docs.isNotEmpty) {
          tempAttended[subject] = (tempAttended[subject] ?? 0) + 1;
        }
      }

      Map<String, int> tempTotal = {};
      uniqueLectures.forEach((subject, lecSet) {
        tempTotal[subject] = lecSet.length;
      });

      int totalAllLectures = tempTotal.values.fold(0, (sum, val) => sum + val);
      int totalAttended = tempAttended.values.fold(0, (sum, val) => sum + val);
      double overall = totalAllLectures == 0
          ? 0
          : (totalAttended / totalAllLectures) * 100;

      setState(() {
        totalLectures = tempTotal;
        attendedLectures = tempAttended;
        overallPercentage = overall;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching attendance: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Summary"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : totalLectures.isEmpty
          ? const Center(
              child: Text(
                "No attendance data available",
                style: TextStyle(fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.blue.shade50,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Overall Attendance",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${overallPercentage.toStringAsFixed(2)}%",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: overallPercentage >= 75
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    "Subject-wise Attendance",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: totalLectures.keys.map((subject) {
                        int total = totalLectures[subject] ?? 0;
                        int attended = attendedLectures[subject] ?? 0;
                        double percentage = total == 0
                            ? 0
                            : (attended / total) * 100;

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      subject,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${percentage.toStringAsFixed(1)}%",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: percentage >= 75
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Attended: $attended / Total: $total lectures",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: total == 0 ? 0 : attended / total,
                                  color: percentage >= 75
                                      ? Colors.green
                                      : Colors.red,
                                  backgroundColor: Colors.grey.shade300,
                                  minHeight: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
