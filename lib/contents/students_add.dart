// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../models/academic_model.dart';
// import '../models/studentsmodel.dart';
// import '../strings/colors.dart';
//
// class AddStudentPage extends StatefulWidget {
//   const AddStudentPage({super.key});
//
//   @override
//   State<AddStudentPage> createState() => _AddStudentPageState();
// }
//
// class _AddStudentPageState extends State<AddStudentPage> {
//   final _formKey = GlobalKey<FormState>();
//
//   String? collegeCode;
//
//   final nameCtrl = TextEditingController();
//   final idCtrl = TextEditingController();
//   final rollCtrl = TextEditingController();
//   final semesterCtrl = TextEditingController();
//   final branchCtrl = TextEditingController();
//   final classCtrl = TextEditingController();
//   final dobCtrl = TextEditingController();
//   final address1Ctrl = TextEditingController();
//   final address2Ctrl = TextEditingController();
//   final contactCtrl = TextEditingController();
//   final emailCtrl = TextEditingController();
//   final passwordCtrl = TextEditingController();
//
//   bool isHostel = false;
//   String gender = 'Male';
//
//   @override
//   void initState() {
//     super.initState();
//     loadCollege();
//   }
//
//   Future<void> loadCollege() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       collegeCode = prefs.getString("collegeCode");
//     });
//   }
//
//   /// -------- AUTO CREATE PARENT --------
//   Future<void> _addParentIfNotExists({
//     required String phone,
//     required String studentId,
//     required String dob,
//   }) async {
//     final parentRef = FirebaseFirestore.instance
//         .collection(collegeCode!)
//         .doc('users')
//         .collection('parents')
//         .doc(phone);
//
//     final doc = await parentRef.get();
//
//     if (!doc.exists) {
//       await parentRef.set({
//         'role': 'parent',
//         'password': dob,
//         'studentID': studentId,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//     }
//   }
//
//   /// -------- DATE PICKER --------
//   Future<void> _pickDob() async {
//     final date = await showDatePicker(
//       context: context,
//       firstDate: DateTime(1990),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: AppColors.primaryBlue,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (date != null) {
//       dobCtrl.text = "${date.day}/${date.month}/${date.year}";
//     }
//   }
//
//   /// -------- ADD STUDENT --------
//   Future<void> addStudent() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     final student = StudentModel(
//       id: idCtrl.text.trim(),
//       name: nameCtrl.text.trim(),
//       // dob: dobCtrl.text.trim(),
//       address1: address1Ctrl.text.trim(),
//       address2: address2Ctrl.text.trim(),
//       contact: contactCtrl.text.trim(),
//       email: emailCtrl.text.trim(),
//       gender: gender,
//       isHostel: isHostel,
//       role: 'student',
//       profile:
//       'https://static.wikimedia.org/download-android-profile.png',
//       password: passwordCtrl.text.trim(),
//       academic: AcademicModel(
//         branch: branchCtrl.text.trim(),
//         className: classCtrl.text.trim(),
//         rollNo:
//         rollCtrl.text.isEmpty ? null : int.tryParse(rollCtrl.text),
//         semester: int.parse(semesterCtrl.text),
//       ),
//     );
//
//     /// Save Student
//     await FirebaseFirestore.instance
//         .collection(collegeCode!)
//         .doc('users')
//         .collection('students')
//         .doc(student.id)
//         .set(student.toMap());
//
//     /// Create Parent Automatically
//     await _addParentIfNotExists(
//       phone: contactCtrl.text.trim(),
//       studentId: student.id,
//       dob: dobCtrl.text.trim(),
//     );
//
//     Navigator.pop(context);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (collegeCode == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: AppColors.pageBackground,
//       appBar: AppBar(
//         backgroundColor: AppColors.primaryBlue,
//         title: const Text(
//           'Add Student',
//           style: TextStyle(
//             color: AppColors.cardBackground,
//             fontSize: 25,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Card(
//           color: AppColors.cardBackground,
//           elevation: 3,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//
//                   _sectionTitle('Personal Information'),
//
//                   _field(nameCtrl, 'Student Name', Icons.person),
//                   _field(idCtrl, 'Enrollment ID', Icons.badge),
//                   _field(contactCtrl, 'Contact', Icons.phone, isNumber: true),
//                   _field(emailCtrl, 'Email', Icons.email),
//
//                   _dobField(),
//
//                   Row(
//                     children: [
//                       Expanded(
//                         child: DropdownButtonFormField<String>(
//                           value: gender,
//                           dropdownColor: AppColors.cardBackground,
//                           decoration:
//                           _inputDecoration('Gender', Icons.people),
//                           items: const [
//                             DropdownMenuItem(
//                                 value: 'Male', child: Text('Male')),
//                             DropdownMenuItem(
//                                 value: 'Female', child: Text('Female')),
//                           ],
//                           onChanged: (v) =>
//                               setState(() => gender = v!),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   _sectionTitle('Academic Information'),
//
//                   _optionalField(
//                       rollCtrl, 'Roll No (Optional)', Icons.confirmation_number),
//
//                   _field(semesterCtrl, 'Semester', Icons.school,
//                       isNumber: true),
//
//                   _field(classCtrl, 'Class', Icons.class_),
//
//                   _field(branchCtrl, 'Branch', Icons.account_tree),
//
//                   const SizedBox(height: 24),
//
//                   _sectionTitle('Address'),
//
//                   _field(address1Ctrl, 'Address Line 1', Icons.home),
//                   _field(address2Ctrl, 'Address Line 2', Icons.location_city),
//
//                   const SizedBox(height: 24),
//
//                   _sectionTitle('Security'),
//
//                   _field(passwordCtrl, 'Password', Icons.lock, obscure: true),
//
//                   const SizedBox(height: 30),
//
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.accentCoral,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       onPressed: addStudent,
//                       child: const Text(
//                         'Save Student',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// ---------------- UI HELPERS ----------------
//
//   Widget _sectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: AppColors.primaryText,
//         ),
//       ),
//     );
//   }
//
//   Widget _dobField() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: dobCtrl,
//         readOnly: true,
//         onTap: _pickDob,
//         validator: (v) => v!.isEmpty ? 'Required' : null,
//         decoration:
//         _inputDecoration('Date of Birth', Icons.calendar_today),
//       ),
//     );
//   }
//
//   Widget _field(
//       TextEditingController controller,
//       String label,
//       IconData icon, {
//         bool isNumber = false,
//         bool obscure = false,
//       }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         obscureText: obscure,
//         keyboardType:
//         isNumber ? TextInputType.number : TextInputType.text,
//         validator: (v) => v!.isEmpty ? 'Required' : null,
//         decoration: _inputDecoration(label, icon),
//       ),
//     );
//   }
//
//   Widget _optionalField(
//       TextEditingController controller,
//       String label,
//       IconData icon,
//       ) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: TextInputType.number,
//         decoration: _inputDecoration(label, icon),
//       ),
//     );
//   }
//
//   InputDecoration _inputDecoration(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       labelStyle: const TextStyle(color: AppColors.secondaryText),
//       prefixIcon: Icon(icon, color: AppColors.darkTeal),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(10),
//         borderSide: const BorderSide(
//           color: AppColors.primaryBlue,
//           width: 1.5,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/academic_model.dart';
import '../models/studentsmodel.dart';
import '../strings/colors.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? collegeCode;

  // Controllers
  final nameCtrl = TextEditingController();
  final idCtrl = TextEditingController();
  final rollCtrl = TextEditingController();
  final semesterCtrl = TextEditingController();
  final branchCtrl = TextEditingController();
  final classCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final address1Ctrl = TextEditingController();
  final address2Ctrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  DateTime? _selectedDate; // Store the actual DateTime object
  bool isHostel = false;
  String gender = 'Male';

  @override
  void initState() {
    super.initState();
    loadCollege();
  }

  Future<void> loadCollege() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      collegeCode = prefs.getString("collegeCode");
    });
  }

  /// -------- AUTO CREATE PARENT --------
  Future<void> _addParentIfNotExists({
    required String phone,
    required String studentId,
    required String password,
  }) async {
    final parentRef = FirebaseFirestore.instance
        .collection(collegeCode!)
        .doc('users')
        .collection('parents')
        .doc(phone);

    final doc = await parentRef.get();

    if (!doc.exists) {
      await parentRef.set({
        'role': 'parent',
        'password': password,
        'studentID': studentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// -------- DATE PICKER --------
  Future<void> _pickDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        dobCtrl.text = "${date.day}/${date.month}/${date.year}";
      });
    }
  }

  /// -------- ADD STUDENT --------
  Future<void> addStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (collegeCode == null) return;

    setState(() => _isLoading = true);

    try {
      final student = StudentModel(
        id: idCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        // Convert selected DateTime to Firestore Timestamp
        dob: _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        address1: address1Ctrl.text.trim(),
        address2: address2Ctrl.text.trim(),
        contact: contactCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        gender: gender,
        isHostel: isHostel,
        role: 'student',
        profile: 'https://static.wikimedia.org/download-android-profile.png',
        password: passwordCtrl.text.trim(),
        academic: AcademicModel(
          branch: branchCtrl.text.trim(),
          className: classCtrl.text.trim(),
          rollNo: int.tryParse(rollCtrl.text.trim()) ?? 0,
          semester: int.tryParse(semesterCtrl.text.trim()) ?? 1,
        ),
      );

      // Save Student to Firestore
      await FirebaseFirestore.instance
          .collection(collegeCode!)
          .doc('users')
          .collection('students')
          .doc(student.id)
          .set(student.toMap());

      // Create Parent Account
      await _addParentIfNotExists(
        phone: contactCtrl.text.trim(),
        studentId: student.id,
        password: passwordCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (collegeCode == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Add Student', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _sectionTitle('Personal Details'),
                          _field(nameCtrl, 'Full Name', Icons.person),
                          _field(idCtrl, 'Student ID (Unique)', Icons.tag),
                          _dobField(),
                          _genderDropdown(),
                          const SizedBox(height: 10),
                          _field(contactCtrl, 'Phone Number', Icons.phone, isNumber: true),
                          _field(emailCtrl, 'Email Address', Icons.email),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _sectionTitle('Academic & Security'),
                          Row(
                            children: [
                              Expanded(child: _field(classCtrl, 'Class', Icons.class_)),
                              const SizedBox(width: 10),
                              Expanded(child: _field(semesterCtrl, 'Sem', Icons.numbers, isNumber: true)),
                            ],
                          ),
                          _field(branchCtrl, 'Branch', Icons.account_tree),
                          _field(rollCtrl, 'Roll No', Icons.format_list_numbered, isNumber: true),
                          const Divider(),
                          _field(passwordCtrl, 'Login Password', Icons.lock, obscure: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : addStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SAVE STUDENT', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (v) => v!.isEmpty ? 'Field required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _dobField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: dobCtrl,
        readOnly: true,
        onTap: _pickDob,
        validator: (v) => v!.isEmpty ? 'Select DOB' : null,
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: const Icon(Icons.calendar_month),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      value: gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.wc),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => setState(() => gender = v!),
    );
  }
}