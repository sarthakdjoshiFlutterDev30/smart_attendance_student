import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../Model/Student_Model.dart';
import 'Result_Profile_Scan.dart';

class ScannerProfile extends StatefulWidget {
  const ScannerProfile({super.key});

  @override
  State<ScannerProfile> createState() => _ScannerProfileState();
}

class _ScannerProfileState extends State<ScannerProfile> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;
  String? id;
  late StudentModel std;
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanned) {
        isScanned = true;
        await controller.pauseCamera();
        id = scanData.code!;
        print(id);
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(id)
            .get();

        if (userDoc.exists) {
          StudentModel student = StudentModel.fromSnapshot(
            userDoc.id,
            userDoc.data() as Map<String, dynamic>,
          );
          setState(() {
            std = student;
          });
          Future.microtask(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultProfileScan(student: student),
              ),
            );
          });
        }
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner Profile'), centerTitle: true),
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
