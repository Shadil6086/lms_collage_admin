import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../strings/colors.dart';

class AddFacultyPage extends StatefulWidget {
  const AddFacultyPage({super.key});

  @override
  State<AddFacultyPage> createState() => _AddFacultyPageState();
}

class _AddFacultyPageState extends State<AddFacultyPage> {
  final _formKey = GlobalKey<FormState>();

  final idController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final departmentController = TextEditingController();
  final branchController = TextEditingController();
  final classController = TextEditingController();
  final semesterController = TextEditingController();
  final address1Controller = TextEditingController();
  final address2Controller = TextEditingController();
  final profileController = TextEditingController();

  bool isLoading = false;

  Future<void> addFaculty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final facultyId = idController.text.trim();

    await FirebaseFirestore.instance
        .collection('MEA')
        .doc('users')
        .collection('faculty')
        .doc(facultyId)
        .set({
      'id': facultyId,
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'contact': phoneController.text.trim(),
      'password': passwordController.text.trim(),
      'department': departmentController.text.trim(),
      // 'profile': profileController.text.trim(),
      'role': 'faculty',
      'gender': 'Male',
      'DOB': Timestamp.now(),
      'address1': address1Controller.text.trim(),
      // 'address2': address2Controller.text.trim(),
      'Academic': {
        'branch': branchController.text.trim(),
        'class': classController.text.trim(),
        'semester': int.tryParse(semesterController.text) ?? 1,
      },
      'class': ['CS1', 'CS2'],
      'messageId': '',
    });

    setState(() => isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'Add Faculty',
          style: TextStyle(
            color: AppColors.cardBackground,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildField(idController, 'Faculty ID'),
              buildField(nameController, 'Name'),
              buildField(emailController, 'Email'),
              buildField(phoneController, 'Contact'),
              buildField(passwordController, 'Password'),
              buildField(departmentController, 'Department'),
              buildField(branchController, 'Branch'),
              buildField(classController, 'Class'),
              buildField(semesterController, 'Semester'),
              buildField(address1Controller, 'Address 1'),
              // buildField(address2Controller, 'Address 2'),
              // buildField(profileController, 'Profile Image URL'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: isLoading ? null : addFaculty,
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4A00E0),
                          Color(0xFF8E2DE2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Add Faculty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}
