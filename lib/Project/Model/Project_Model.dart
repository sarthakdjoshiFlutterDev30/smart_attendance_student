class ProjectModel {
  final String id;
  final String name;
  final String email;
  final String enrollment;
  final String course;
  final String semester;
  final String technology;
  final String docUrl;
  final String prjUrl;
  final String pptUrl;

  ProjectModel({
    required this.id,
    required this.name,
    required this.email,
    required this.enrollment,
    required this.course,
    required this.semester,
    required this.technology,
    required this.docUrl,
    required this.prjUrl,
    required this.pptUrl,
  });

  factory ProjectModel.fromSnapshot(String id, Map<String, dynamic> json) {
    return ProjectModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      enrollment: json['enrollment'] ?? '',
      course: json['course'] ?? '',
      semester: json['semester'] ?? '',
      technology: json['technology'] ?? '',
      docUrl: json['docUrl'] ?? '',
      prjUrl: json['prjUrl'] ?? '',
      pptUrl: json['pptUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'enrollment': enrollment,
      'course': course,
      'semester': semester,
      'technology': technology,
      'docUrl': docUrl,
      'prjUrl': prjUrl,
      'pptUrl': pptUrl,
    };
  }
}
