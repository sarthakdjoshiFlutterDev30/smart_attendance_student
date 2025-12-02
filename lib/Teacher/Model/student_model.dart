class StudentModel {
  final String id;
  final String name;
  final String email;
  final String enrollment;
  final String course;
  final String semester;
  final String? photourl;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollment,
    required this.course,
    required this.semester,
    required this.photourl,
  });

  factory StudentModel.fromSnapshot(String id, Map<String, dynamic> json) {
    return StudentModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      enrollment: json['enrollment'] ?? '',
      course: json['course'] ?? '',
      semester: json['semester'] ?? '',
      photourl: json['photourl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'enrollment': enrollment,
      'course': course,
      'semester': semester,
      'photourl': photourl,
    };
  }
}
