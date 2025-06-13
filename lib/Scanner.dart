import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:smart_attendance_student/Student_Model.dart';

class StudentScanner extends StatefulWidget {
  final StudentModel std;

  const StudentScanner({super.key, required this.std});

  @override
  State<StudentScanner> createState() => _StudentScannerState();
}

class _StudentScannerState extends State<StudentScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isScanned = false;
  late final Map<String, dynamic> studentInfo;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    studentInfo = {
      'name': widget.std.name,
      'enrollmentNo': widget.std.enrollment,
      'course': widget.std.course,
      'semester': widget.std.semester,
    };
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanned) {
        setState(() {
          result = scanData;
          isScanned = true;
        });
        if(scanData.code!!=widget.std.course){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not allowed to mark attendance')));
          return;
        }
        await _markAttendance(scanData.code!);
        await controller.pauseCamera();
      }
    });
  }

  Future<void> _markAttendance(String sessionId) async {
    String day = DateFormat('dd').format(DateTime.now());
    String month = DateFormat('MM').format(DateTime.now());
    String year = DateFormat('yyyy').format(DateTime.now());
    String date = '$day-$month-$year';
    String hour = DateFormat('HH').format(DateTime.now());
    String minute = DateFormat('mm').format(DateTime.now());
    String second = DateFormat('ss').format(DateTime.now());
    String time = '$hour:$minute:$second';
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('attendees')
        .add({
          'name': widget.std.name,
          'enrollmentNo': widget.std.enrollment,
          'course': widget.std.course,
          'semester': widget.std.semester,
          'timestamp': date,
          'time': time,
        })
        .then((_) {
          print(sessionId);
        });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attendance Marked')));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR to Mark Attendance')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text('Scanned: ${result!.code}')
                  : const Text('Scan a code'),
            ),
          ),
        ],
      ),
    );
  }
}
