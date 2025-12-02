import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  var email = TextEditingController();
  var password = TextEditingController();
  var name = TextEditingController();
  var enrollment = TextEditingController();

  bool _isshow = true;
  bool _isloading = true;

  String? selectedCourse;
  String? selectedSemester;

  File? profilepic;
  XFile? selectedImage;

  final Map<String, List<String>> courseSemesters = {
    'MCA': ['1', '2', '3', '4'],
    'BCA': ['1', '2', '3', '4', '5', '6'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student"),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final maxFormWidth = isWide ? 720.0 : 520.0;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Student Details",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(60),
                            onTap: () async {
                              try {
                                XFile? pickedImage = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (pickedImage != null) {
                                  int imageSize = await pickedImage.length();
                                  if (imageSize > 50 * 1024) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Image must be below 50 KB"),
                                      ),
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
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              backgroundImage: kIsWeb
                                  ? (selectedImage != null
                                        ? NetworkImage(selectedImage!.path)
                                        : null)
                                  : (profilepic != null ? FileImage(profilepic!) : null)
                                        as ImageProvider<Object>?,
                              child: selectedImage == null && profilepic == null
                                  ? Icon(Icons.add_a_photo, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(name, "Name", Icons.person),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Select Course",
                          ),
                          initialValue: selectedCourse,
                          items: courseSemesters.keys.map((course) {
                            return DropdownMenuItem(value: course, child: Text(course));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCourse = value;
                              selectedSemester = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Select Semester",
                          ),
                          initialValue: selectedSemester,
                          items: selectedCourse == null
                              ? []
                              : courseSemesters[selectedCourse!]!.map((sem) {
                                  return DropdownMenuItem(value: sem, child: Text(sem));
                                }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSemester = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          enrollment,
                          "Enrollment No.",
                          Icons.confirmation_num,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(email, "Email", Icons.email),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: _isshow,
                          obscuringCharacter: "*",
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isshow = !_isshow;
                                });
                              },
                              child: Text(_isshow ? "Show" : "Hide"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _isloading
                            ? Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await _addStudent();
                                      },
                                      icon: const Icon(Icons.person_add_alt_1),
                                      label: const Text("Add Student"),
                                    ),
                                  ),
                                ],
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Future<void> _addStudent() async {
    if (name.text.trim().isEmpty ||
        enrollment.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        selectedCourse == null ||
        selectedSemester == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All Fields are Required")));
      return;
    }

    setState(() {
      _isloading = false;
    });

    try {
      String photoUrl = "";

      if (kIsWeb && selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        if (bytes.length > 50 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image must be below 50 KB")),
          );
          setState(() => _isloading = true);
          return;
        }
        final ref = FirebaseStorage.instance
            .ref()
            .child("Stud-profilepic")
            .child(const Uuid().v1());
        final uploadTask = await ref.putData(bytes);
        photoUrl = await uploadTask.ref.getDownloadURL();
      } else if (!kIsWeb && profilepic != null) {
        final fileSize = await profilepic!.length();
        if (fileSize > 50 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image must be below 50 KB")),
          );
          setState(() => _isloading = true);
          return;
        }
        final ref = FirebaseStorage.instance
            .ref()
            .child("Stud-profilepic")
            .child(const Uuid().v1());
        final uploadTask = await ref.putFile(profilepic!);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection("Students")
          .doc(user.user?.uid)
          .set({
            "name": name.text.trim(),
            "email": email.text.trim(),
            "password": password.text.trim(),
            "enrollment": enrollment.text.trim(),
            "course": selectedCourse!,
            "semester": selectedSemester!,
            "createdAt": Timestamp.now(),
            "photourl": photoUrl,
            "role":"student"
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Student Added")));

      email.clear();
      password.clear();
      name.clear();
      enrollment.clear();
      setState(() {
        selectedCourse = null;
        selectedSemester = null;
        profilepic = null;
        selectedImage = null;
        _isloading = true;
      });
    } catch (e) {
      print("Error adding student: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add student")));
      setState(() {
        _isloading = true;
      });
    }
  }
}
