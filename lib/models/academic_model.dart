class AcademicModel {
  final String branch;
  final String className;
  final int rollNo;
  final int semester;

  AcademicModel({
    required this.branch,
    required this.className,
    required this.rollNo,
    required this.semester,
  });

  factory AcademicModel.fromMap(Map<String, dynamic> map) {
    return AcademicModel(
      branch: map['branch'] ?? '',
      className: map['class'] ?? '', // Maps "class" from Firestore
      rollNo: map['rollNo'] is int ? map['rollNo'] : int.tryParse(map['rollNo'].toString()) ?? 0,
      semester: map['semester'] is int ? map['semester'] : int.tryParse(map['semester'].toString()) ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branch': branch,
      'class': className,
      'rollNo': rollNo,
      'semester': semester,
    };
  }
}