import 'package:cloud_firestore/cloud_firestore.dart';
import 'academic_model.dart';

class StudentModel {
  final String id;
  final String name;
  final Timestamp? dob; // Firestore Timestamps must be handled as Timestamp objects
  final String address1;
  final String address2;
  final String contact;
  final String email;
  final String gender;
  final bool isHostel;
  final String role;
  final String profile;
  final String password;
  final String? messageId;
  final AcademicModel academic;

  StudentModel({
    required this.id,
    required this.name,
    this.dob,
    required this.address1,
    required this.address2,
    required this.contact,
    required this.email,
    required this.gender,
    required this.isHostel,
    required this.role,
    required this.profile,
    required this.password,
    this.messageId,
    required this.academic,
  });

  factory StudentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return StudentModel(
      id: id,
      name: data["name"] ?? "",
      dob: data["DOB"] is Timestamp ? data["DOB"] : null,
      address1: data["address1"] ?? "",
      address2: data["address2"] ?? "",
      contact: data["contact"] ?? "",
      email: data["email"] ?? "",
      gender: data["gender"] ?? "",
      isHostel: data["isHostel"] ?? false,
      role: data["role"] ?? "student",
      profile: data["profile"] ?? "",
      password: data["password"] ?? "",
      messageId: data["messageId"],
      // Note: "Academic" starts with Uppercase 'A' in your screenshot
      academic: AcademicModel.fromMap(data["Academic"] ?? data["academic"] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "DOB": dob,
      "address1": address1,
      "address2": address2,
      "contact": contact,
      "email": email,
      "gender": gender,
      "isHostel": isHostel,
      "role": role,
      "profile": profile,
      "password": password,
      "messageId": messageId,
      "Academic": academic.toMap(),
    };
  }
}