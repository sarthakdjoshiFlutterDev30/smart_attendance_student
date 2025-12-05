import 'dart:ui';
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
    print(widget.enrollmentNo);
  }

  Future<void> fetchAttendanceData() async {
    try {
      // Fetch all sessions
      final sessionSnapshot =
      await FirebaseFirestore.instance.collection('sessions').get();

      Map<String, int> tempTotalLectures = {};
      Map<String, int> tempAttendedLectures = {};

      for (var session in sessionSnapshot.docs) {
        final data = session.data();

        // Use lecName or fallback to 'Unknown'
        String subject = (data['lecName'] ?? 'Unknown').toString().trim();
        String lecNo = (data['lecNo'] ?? session.id).toString();

        // Count total lectures per subject
        tempTotalLectures[subject] = (tempTotalLectures[subject] ?? 0) + 1;

        // Check if this student attended this session
        final attendeeSnapshot = await FirebaseFirestore.instance
            .collection('sessions')
            .doc(session.id)
            .collection('attendees')
            .where('enrollmentNo', isEqualTo: widget.enrollmentNo)
            .get();

        if (attendeeSnapshot.docs.isNotEmpty) {
          tempAttendedLectures[subject] =
              (tempAttendedLectures[subject] ?? 0) + 1;
        }
      }

      // Calculate overall percentage
      int totalAllLectures =
      tempTotalLectures.values.fold(0, (sum, val) => sum + val);
      int totalAttended =
      tempAttendedLectures.values.fold(0, (sum, val) => sum + val);

      double overall = totalAllLectures == 0
          ? 0
          : (totalAttended / totalAllLectures) * 100;

      setState(() {
        totalLectures = tempTotalLectures;
        attendedLectures = tempAttendedLectures;
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

  int _crossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 1000) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final isGoodOverall = overallPercentage >= 75;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Attendance Summary",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SafeArea(
        child: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: Colors.white))
            : totalLectures.isEmpty
            ? const Center(
            child: Text(
              "No attendance data available",
              style: TextStyle(color: Colors.white70),
            ))
            : LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// --------- OVERALL HEADER ------------
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(
                              color: Colors.white10),
                        ),

                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CircularProgressIndicator(
                                    value: overallPercentage / 100,
                                    strokeWidth: 10,
                                    backgroundColor:
                                    Colors.white12,
                                    valueColor:
                                    AlwaysStoppedAnimation(
                                      isGoodOverall
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${overallPercentage.toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Enrollment No",
                                    style: TextStyle(
                                        color: Colors.white54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.enrollmentNo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _legendDot(
                                          color: Colors.greenAccent),
                                      const SizedBox(width: 5),
                                      const Text(
                                        ">= 75%",
                                        style: TextStyle(
                                            color: Colors.white70),
                                      ),
                                      const SizedBox(width: 14),
                                      _legendDot(
                                          color: Colors.redAccent),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "< 75%",
                                        style: TextStyle(
                                            color: Colors.white70),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Subject-wise Report",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// -------- GRID VIEW PREMIUM ----------
                  Expanded(
                    child: GridView.builder(
                      itemCount: totalLectures.length,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                        _crossAxisCount(constraints.maxWidth),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (context, index) {
                        final subject =
                        totalLectures.keys.elementAt(index);
                        final total =
                            totalLectures[subject] ?? 0;
                        final attended =
                            attendedLectures[subject] ?? 0;
                        final percentage = total == 0
                            ? 0
                            : (attended / total) * 100;
                        final isGood = percentage >= 75;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(18),
                            color: const Color(0xff121212),
                            border:
                            Border.all(color: Colors.white10),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black54,
                              )
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              /// SUBJECT HEADER
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isGood
                                        ? Colors.greenAccent
                                        .withOpacity(0.15)
                                        : Colors.redAccent
                                        .withOpacity(0.15),
                                    child: Icon(
                                      isGood
                                          ? Icons.check_circle
                                          : Icons.warning,
                                      size: 18,
                                      color: isGood
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      subject,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              Text(
                                "${percentage.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isGood
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Attended: $attended",
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),
                                  Text(
                                    "Total: $total",
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              ClipRRect(
                                borderRadius:
                                BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  minHeight: 10,
                                  value: total == 0
                                      ? 0
                                      : attended / total,
                                  backgroundColor:
                                  Colors.white12,
                                  valueColor:
                                  AlwaysStoppedAnimation(
                                    isGood
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _legendDot({required Color color}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
