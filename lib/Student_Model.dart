class StudentModel {
  final String id; // Firestore document ID
  final String name;
  final String email;
  final String enrollment;
  final String course;
  final String semester;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollment,
    required this.course,
    required this.semester,
  });

  factory StudentModel.fromSnapshot(String id, Map<String, dynamic> json) {
    return StudentModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      enrollment: json['enrollment'] ?? '',
      course: json['course'] ?? '',
      semester: json['semester'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'enrollment': enrollment,
      'course': course,
      'semester': semester,
    };
  }
}
