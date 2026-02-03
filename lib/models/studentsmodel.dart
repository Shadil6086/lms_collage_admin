class AcademicModel {
  final String branch;
  final String className;
  final int? rollNo; // ✅ nullable
  final int semester;

  AcademicModel({
    required this.branch,
    required this.className,
    this.rollNo, // ✅ not required
    required this.semester,
  });

  Map<String, dynamic> toMap() {
    return {
      'branch': branch,
      'class': className,
      'semester': semester,
      if (rollNo != null) 'rollNo': rollNo, // ✅ only save if exists
    };
  }
}

class StudentModel {
  final String id;
  final String name;
  final String dob;
  final String address1;
  final String address2;
  final String contact;
  final String email;
  final String gender;
  final bool isHostel;
  final String role;
  final String profile;
  final String password;
  final AcademicModel academic;

  StudentModel({
    required this.id,
    required this.name,
    required this.dob,
    required this.address1,
    required this.address2,
    required this.contact,
    required this.email,
    required this.gender,
    required this.isHostel,
    required this.role,
    required this.profile,
    required this.password,
    required this.academic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'DOB': dob,
      'address1': address1,
      'address2': address2,
      'contact': contact,
      'email': email,
      'gender': gender,
      'isHostel': isHostel,
      'role': role,
      'profile': profile,
      'password': password,
      'Academic': academic.toMap(),
    };
  }
}
