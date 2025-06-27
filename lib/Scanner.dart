import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'Student_Model.dart'; // keep your model

class StudentScanner extends StatefulWidget {
  final StudentModel std;

  const StudentScanner({super.key, required this.std});

  @override
  State<StudentScanner> createState() => _StudentScannerState();
}

class _StudentScannerState extends State<StudentScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;

  // Replace with your actual Face++ API credentials
  final String faceApiKey = 'BZgv-hUJyvJwdi-ISS5IxsK0IWRn3sln';
  final String faceApiSecret = 'ATjeyYZJQtdc7zeMJFtArdin09z4LOl0';

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanned) {
        isScanned = true;
        await controller.pauseCamera();
        await verifyFaceAndMarkAttendance(scanData.code!);
      }
    });
  }

  Future<void> verifyFaceAndMarkAttendance(String sessionId) async {
    final sessionDoc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .get();

    if (!sessionDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Invalid session ID.')),
      );
      Navigator.pop(context);
      return;
    }

    final createdAtMillis = sessionDoc.data()?['createdAtMillis'];
    if (createdAtMillis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Invalid session data.')),
      );
      Navigator.pop(context);
      return;
    }

    final createdTime = DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
    final now = DateTime.now();
    final difference = now.difference(createdTime).inSeconds;
    print("Difference=${difference.toString()}");
    if (difference > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏰ QR code expired. Try again.')),
      );
      Navigator.pop(context);
      return;
    }

    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
      return;
    }

    final match = await compareFaces(widget.std.photourl, File(pickedImage.path));
    if (match) {
      await _markAttendance(sessionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Face matched. Attendance marked!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Face not matched!')),
      );
    }
    Navigator.pop(context);
  }

  Future<bool> compareFaces(String imageUrl1, File image2) async {
    final uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/compare');
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = faceApiKey
      ..fields['api_secret'] = faceApiSecret
      ..fields['image_url1'] = imageUrl1
      ..files.add(await http.MultipartFile.fromPath('image_file2', image2.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (data.containsKey('confidence')) {
      double confidence = data['confidence'];
      return confidence > 70.0; // Adjust threshold as needed
    } else {
      return false;
    }
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
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('attendees')
        .add({
      'name': widget.std.name,
      'enrollmentNo': widget.std.enrollment,
      'course': widget.std.course,
      'semester': widget.std.semester,
      'photourl': widget.std.photourl,
      'timestamp': date,
      'time': time,
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR & Verify Face')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
          ),
          const SizedBox(height: 16),
          const Text('Scan QR Code to Mark Attendance'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
