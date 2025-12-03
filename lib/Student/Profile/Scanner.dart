import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../Model/Student_Model.dart';

class StudentScanner extends StatefulWidget {
  final StudentModel std;

  const StudentScanner({super.key, required this.std});

  @override
  State<StudentScanner> createState() => _StudentScannerState();
}

class _StudentScannerState extends State<StudentScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  bool isScanned = false;

  final String faceApiKey = 'BZgv-hUJyvJwdi-ISS5IxsK0IWRn3sln';
  final String faceApiSecret = 'ATjeyYZJQtdc7zeMJFtArdin09z4LOl0';

  final double ampicsLat = 23.5291733;
  final double ampicsLng = 72.4568126 ;
  final double allowedRadius = 200;

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanned) {
        isScanned = true;
        setState(() => isProcessing = true);
        await controller.pauseCamera();
        await verifyFaceAndMarkAttendance(scanData.code!);
        setState(() => isProcessing = false);
      }
    });
  }

  Future<void> verifyFaceAndMarkAttendance(String sessionId) async {
    try {
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Invalid session ID.')));
        Navigator.pop(context);
        return;
      }

      final sessionData = sessionDoc.data();
      final String subject =
          (sessionData != null && sessionData['subject'] is String)
              ? (sessionData['subject'] as String)
              : 'Unknown';

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
      print("Difference${now.difference(createdTime).inSeconds.toString()}");
      if (now.difference(createdTime).inSeconds > 10) {
        print(now.difference(createdTime).inSeconds.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⏰ QR code expired. Try again.')),
        );
        Navigator.pop(context);
        return;
      }

      bool isInsideCampus = await _isInsideCampus();
      if (!isInsideCampus) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ You are not inside AMPICS campus!')),
        );
        Navigator.pop(context);
        return;
      }
      final attendeeQuery = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('attendees')
          .where('enrollmentNo', isEqualTo: widget.std.enrollment)
          .where('subject', isEqualTo: subject)
          .get();

      if (attendeeQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Attendance already marked!')),
        );
        Navigator.pop(context);
        return;
      }
      final XFile? pickedImage = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      if (pickedImage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected.')));
        return;
      }

      final match = await compareFaces(
        widget.std.photourl,
        File(pickedImage.path),
      );
      if (match) {
        await _markAttendance(sessionId, subject);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Face matched. Attendance marked!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Face not matched!')));
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      Navigator.pop(context);
    }
  }

  Future<bool> compareFaces(String imageUrl1, File image2) async {
    final uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/compare');
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = faceApiKey
      ..fields['api_secret'] = faceApiSecret
      ..fields['image_url1'] = imageUrl1
      ..files.add(
        await http.MultipartFile.fromPath('image_file2', image2.path),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (data.containsKey('confidence')) {
      double confidence = data['confidence'];
      return confidence > 70.0;
    }
    return false;
  }

  Future<void> _markAttendance(String sessionId, String subject) async {
    final now = DateTime.now();
    String date = DateFormat('dd-MM-yyyy').format(now);
    String time = DateFormat('HH:mm:ss').format(now);

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('attendees')
        .add({
          'name': widget.std.name,
          'enrollmentNo': widget.std.enrollment,
          'course': widget.std.course,
          'semester': widget.std.semester,
          'photourl': widget.std.photourl,
          'subject': subject,
          'timestamp': date,
          'time': time,
        });
  }

  Future<bool> _isInsideCampus() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double distance = Geolocator.distanceBetween(
      ampicsLat,
      ampicsLng,
      position.latitude,
      position.longitude,
    );

    return distance <= allowedRadius;
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
      body: Stack(
        children: [
          Column(
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
          if (isProcessing)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
