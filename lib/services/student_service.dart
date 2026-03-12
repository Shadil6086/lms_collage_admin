import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/studentsmodel.dart';

class StudentService {

  static Future<List<StudentModel>> getStudents() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? collegeCode = prefs.getString("collegeCode");

    if (collegeCode == null) return [];

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collegeCode)
        .doc("users")
        .collection("students")
        .get();

    return snapshot.docs.map((doc) {
      return StudentModel.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    }).toList();
  }
}