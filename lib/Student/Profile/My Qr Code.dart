import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../Model/Student_Model.dart';

class My_Qr_Code extends StatefulWidget {
  final StudentModel std;
  const My_Qr_Code({super.key, required this.std});

  @override
  State<My_Qr_Code> createState() => _My_Qr_CodeState();
}

class _My_Qr_CodeState extends State<My_Qr_Code> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Qr Code")),
      body: Center(
        child: QrImageView(
          data: widget.std.id.toString(),
          version: QrVersions.auto,
          size: 200.0,
        ),
      ),
    );
  }
}
