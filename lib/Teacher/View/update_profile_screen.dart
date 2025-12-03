import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../Model/student_model.dart';

class UpdateProfileScreen extends StatefulWidget {
  final StudentModel student;
  const UpdateProfileScreen({super.key, required this.student});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController enrollmentController;
  String? selectedCourse;
  String? selectedSemester;
  bool _isLoading = true;
  File? profilepic;
  XFile? selectedImage;

  final Map<String, List<String>> courseSemesters = {
    'MCA': ['1', '2', '3', '4'],
    'BCA': ['1', '2', '3', '4', '5', '6'],
  };

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.student.name);
    enrollmentController = TextEditingController(text: widget.student.enrollment);
    selectedCourse = widget.student.course;
    selectedSemester = widget.student.semester;
  }

  Future<void> updateStudent() async {
    setState(() => _isLoading = false);
    String photourl = widget.student.photourl ?? "";

    try {
      if ((kIsWeb && selectedImage != null) || (!kIsWeb && profilepic != null)) {
        final String filename = const Uuid().v4();
        final ref = FirebaseStorage.instance.ref().child('student_profiles/$filename');

        UploadTask uploadTask;
        if (kIsWeb && selectedImage != null) {
          final bytes = await selectedImage!.readAsBytes();
          if (bytes.length > 50 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Image must be below 50 KB")),
            );
            setState(() => _isLoading = true);
            return;
          }
          uploadTask = ref.putData(bytes);
        } else {
          final fileSize = await profilepic!.length();
          if (fileSize > 50 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Image must be below 50 KB")),
            );
            setState(() => _isLoading = true);
            return;
          }
          uploadTask = ref.putFile(profilepic!);
        }

        final snapshot = await uploadTask;
        photourl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection("Students").doc(widget.student.id).update({
        'name': nameController.text.trim(),
        'enrollment': enrollmentController.text.trim(),
        'course': selectedCourse,
        'semester': selectedSemester,
        'photourl': photourl,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      setState(() => _isLoading = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkGrey = Colors.grey[900];
    final fieldGrey = Colors.grey[850];

    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        title: const Text("Update Profile"),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                try {
                  XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedImage != null) {
                    final imageSize = await pickedImage.length();
                    if (imageSize > 50 * 1024) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Image must be below 50 KB")),
                      );
                      return;
                    }
                    setState(() {
                      if (kIsWeb) {
                        selectedImage = pickedImage;
                      } else {
                        profilepic = File(pickedImage.path);
                      }
                    });
                  }
                } catch (e) {
                  print("Image Picker Error: $e");
                }
              },
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[800],
                backgroundImage: kIsWeb
                    ? (selectedImage != null
                    ? NetworkImage(selectedImage!.path)
                    : (widget.student.photourl != null
                    ? NetworkImage(widget.student.photourl!)
                    : null))
                    : (profilepic != null
                    ? FileImage(profilepic!)
                    : (widget.student.photourl != null
                    ? NetworkImage(widget.student.photourl!) as ImageProvider
                    : null)),
                child: ((kIsWeb && selectedImage == null) || (!kIsWeb && profilepic == null))
                    ? const Icon(Icons.add_a_photo, color: Colors.white, size: 30)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField("Name", nameController, fieldGrey),
            const SizedBox(height: 12),
            _buildTextField("Enrollment", enrollmentController, fieldGrey),
            const SizedBox(height: 12),
            _buildDropdown("Select Course", selectedCourse, courseSemesters.keys.toList(), (value) {
              setState(() {
                selectedCourse = value;
                selectedSemester = null;
              });
            }, fieldGrey),
            const SizedBox(height: 12),
            _buildDropdown(
              "Select Semester",
              selectedSemester,
              selectedCourse == null ? [] : courseSemesters[selectedCourse]!,
                  (value) => setState(() => selectedSemester = value),
              fieldGrey,
            ),
            const SizedBox(height: 25),
            (_isLoading)
                ? SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.update),
                label: const Text(
                  "Update Profile",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: updateStudent,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            )
                : const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, Color? bgColor) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      String? currentValue,
      List<String> items,
      ValueChanged<String?> onChanged,
      Color? bgColor,
      ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      initialValue: currentValue,
      dropdownColor: Colors.grey[850],
      style: const TextStyle(color: Colors.white),
      items: items
          .map((value) => DropdownMenuItem(
        value: value,
        child: Text(value),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
