
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xampus_student/Student/Project/Model/Project_Model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String enrollment;
  final String course;
  final String semester;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollment,
    required this.course,
    required this.semester,
  });

  factory UserModel.fromSnapshot(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      enrollment: json['enrollment'] ?? '',
      course: json['course'] ?? '',
      semester: json['semester'] ?? '',
    );
  }
}

class Technology {
  final String name;
  final IconData icon;
  final Color color;

  Technology({required this.name, required this.icon, required this.color});
}

final List<Technology> technologies = [
  Technology(name: 'Flutter', icon: Icons.phone_android, color: Colors.blue),
  Technology(name: 'Android Native', icon: Icons.android, color: Colors.green),
  Technology(name: 'iOS Swift', icon: Icons.apple, color: Colors.grey),
  Technology(name: 'React Native', icon: Icons.sync, color: Colors.lightBlue),
  Technology(name: 'Web', icon: Icons.web, color: Colors.orange),
  Technology(name: 'Java', icon: Icons.code, color: Colors.brown),
  Technology(name: 'Python', icon: Icons.code, color: Colors.blueGrey),
  Technology(name: 'Node.js', icon: Icons.cloud_queue, color: Colors.lightGreen),
  Technology(name: 'Other', icon: Icons.widgets_outlined, color: Colors.black),
];


class ProjectScreen extends StatefulWidget {
  const ProjectScreen({Key? key}) : super(key: key);

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  String? _semesterFilter;
  String? _technologyFilter;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('Students').doc(user.uid).get();
      if (mounted) {
        setState(() {
          if (doc.exists) {
            _currentUser = UserModel.fromSnapshot(doc.id, doc.data()!);
          }
          _isProfileLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (_semesterFilter != null || _technologyFilter != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                setState(() {
                  _semesterFilter = null;
                  _technologyFilter = null;
                });
              },
              tooltip: 'Clear filters',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) async {
              if (value == 'semester') {
                final selectedSemester = await _showFilterDialog('Semester');
                if (selectedSemester != null) {
                  setState(() => _semesterFilter = selectedSemester);
                }
              } else if (value == 'technology') {
                final selectedTechnology = await _showFilterDialog('Technology');
                if (selectedTechnology != null) {
                  setState(() => _technologyFilter = selectedTechnology);
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'semester',
                child: Row(
                  children: [
                    Icon(Icons.school, size: 20),
                    SizedBox(width: 8),
                    Text('Filter by Semester'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'technology',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20),
                    SizedBox(width: 8),
                    Text('Filter by Technology'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_semesterFilter != null || _technologyFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Filters: ${_semesterFilter ?? ''}${_semesterFilter != null && _technologyFilter != null ? ', ' : ''}${_technologyFilter ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getProjectsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load projects',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final projects = snapshot.data!.docs
                    .map((doc) => ProjectModel.fromSnapshot(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No projects found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_semesterFilter != null || _technologyFilter != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try changing or clearing your filters',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final tech = technologies.firstWhere(
                      (t) => t.name == project.technology,
                      orElse: () => technologies.last,
                    );

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Handle project tap
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: tech.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(tech.icon, color: tech.color, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          project.course,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Sem ${project.semester}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    context,
                                    icon: Icons.picture_as_pdf,
                                    label: 'Document',
                                    onPressed: project.docUrl.isNotEmpty
                                        ? () {
                                      _launchURL(project.docUrl);
                                    }: null,
                                  ),
                                  _buildActionButton(
                                    context,
                                    icon: Icons.slideshow,
                                    label: 'Presentation',
                                    onPressed: project.pptUrl.isNotEmpty
                                        ? () => _launchURL(project.pptUrl)
                                        : null,
                                  ),
                                  _buildActionButton(
                                    context,
                                    icon: Icons.link,
                                    label: 'Project',
                                    onPressed: project.prjUrl.isNotEmpty
                                        ? () => _launchURL(project.prjUrl)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isProfileLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _uploadProject,
              icon: const Icon(Icons.add),
              label: const Text('Add Project'),
            ),
    );
  }

  Stream<QuerySnapshot> _getProjectsStream() {
    Query query = _firestore.collection('projects');

    if (_currentUser != null && _currentUser!.course.isNotEmpty) {
      query = query.where('course', isEqualTo: _currentUser!.course);
    }

    if (_semesterFilter != null && _semesterFilter!.isNotEmpty) {
      query = query.where('semester', isEqualTo: _semesterFilter);
    }
    if (_technologyFilter != null && _technologyFilter!.isNotEmpty) {
      query = query.where('technology', isEqualTo: _technologyFilter);
    }

    return query.snapshots();
  }

  Future<String?> _showFilterDialog(String title) async {
    String? selectedValue;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (title == 'Semester' && _currentUser != null) {
          List<String> semesterOptions = [];
          if (_currentUser!.course.toLowerCase() == 'mca') {
            semesterOptions = ['3', '4'];
          } else if (_currentUser!.course.toLowerCase() == 'bca') {
            semesterOptions = ['5', '6'];
          }
          dropdownItems = semesterOptions
              .map((sem) => DropdownMenuItem(
            value: sem,
            child: Text('Semester $sem'),
          ))
              .toList();
        } else if (title == 'Technology') {
          dropdownItems = technologies
              .map((tech) => DropdownMenuItem(
            value: tech.name,
            child: Row(
              children: [
                Icon(tech.icon, color: tech.color),
                const SizedBox(width: 8),
                Text(tech.name),
              ],
            ),
          ))
              .toList();
        }

        return AlertDialog(
          title: Text('Filter by $title'),
          content: dropdownItems.isNotEmpty
              ? DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Select $title'),
            value: selectedValue,
            items: dropdownItems,
            onChanged: (value) {
              selectedValue = value;
            },
          )
              : TextField(
            onChanged: (v) => selectedValue = v,
            decoration: InputDecoration(hintText: 'Enter $title'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(selectedValue);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadProject() async {
    if (_currentUser == null) {
      await _fetchCurrentUser();
    }

    if (_currentUser != null) {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => ProjectUploadDialog(currentUser: _currentUser!),
      );

      if (result != null) {
        try {
          final docFile = result['docFile'] as File;
          final pptFile = result['pptFile'] as File;

          final docUrl = await _uploadFile(docFile, 'documents');
          final pptUrl = await _uploadFile(pptFile, 'presentations');

          final newProject = ProjectModel(
            id: '', // Firestore will generate an ID
            name: result['name'],
            email: result['email'],
            enrollment: result['enrollment'],
            course: result['course'],
            semester: result['semester'],
            technology: result['technology'],
            docUrl: docUrl,
            prjUrl: result['prjUrl'],
            pptUrl: pptUrl,
          );

          await _firestore.collection('projects').add(newProject.toJson());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project uploaded successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload project: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load user profile. Please restart the app or try again.')),
      );
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    final fileName = file.path.split('/').last;
    final destination = '$path/$fileName';
    final ref = _storage.ref(destination);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: onPressed != null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).disabledColor,
          tooltip: onPressed != null ? 'Open $label' : 'No $label available',
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: onPressed != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).disabledColor,
              ),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}

class ProjectUploadDialog extends StatefulWidget {
  final UserModel currentUser;
  const ProjectUploadDialog({Key? key, required this.currentUser}) : super(key: key);

  @override
  _ProjectUploadDialogState createState() => _ProjectUploadDialogState();
}

class _ProjectUploadDialogState extends State<ProjectUploadDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _name, _prjUrl;
  String? _email, _enrollment, _course, _semester;
  String? _selectedTechnology;
  File? _docFile, _pptFile;

  @override
  void initState() {
    super.initState();
    _email = widget.currentUser.email;
    _enrollment = widget.currentUser.enrollment;
    _course = widget.currentUser.course;
    _semester = widget.currentUser.semester;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a project name' : null,
                onSaved: (value) => _name = value,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _email,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _enrollment,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Enrollment'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _course,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _semester,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Semester'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Technology'),
                value: _selectedTechnology,
                items: technologies.map((Technology tech) {
                  return DropdownMenuItem<String>(
                    value: tech.name,
                    child: Row(
                      children: [
                        Icon(tech.icon, color: tech.color),
                        const SizedBox(width: 10),
                        Text(tech.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTechnology = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a technology' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Project Link'),
                validator: (value) => value!.isEmpty ? 'Please enter a project link' : null,
                onSaved: (value) => _prjUrl = value,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Document:'),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                      if (result != null) {
                        setState(() {
                          _docFile = File(result.files.single.path!);
                        });
                      }
                    },
                    child: const Text('Pick PDF'),
                  ),
                  if (_docFile != null) const Icon(Icons.check, color: Colors.green),
                ],
              ),
              Row(
                children: [
                  const Text('Presentation:'),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['ppt', 'pptx']);
                      if (result != null) {
                        setState(() {
                          _pptFile = File(result.files.single.path!);
                        });
                      }
                    },
                    child: const Text('Pick PPT'),
                  ),
                  if (_pptFile != null) const Icon(Icons.check, color: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Upload'),
          onPressed: () {
            if (_formKey.currentState!.validate() && _docFile != null && _pptFile != null) {
              _formKey.currentState!.save();
              Navigator.of(context).pop({
                'name': _name,
                'email': _email,
                'enrollment': _enrollment,
                'course': _course,
                'semester': _semester,
                'technology': _selectedTechnology,
                'prjUrl': _prjUrl,
                'docFile': _docFile,
                'pptFile': _pptFile,
              });
            }
          },
        ),
      ],
    );
  }
}
