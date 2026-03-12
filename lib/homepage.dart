import 'package:flutter/material.dart';
import 'package:lms_collage_admin/strings/colors.dart';

import 'contents/SemesterControlPage.dart';
import 'contents/faculty_list.dart';
import 'contents/students_list.dart';

class CollegeHomePage extends StatefulWidget {
  // 1. Move the variable inside the class and make it final
  final String collegeName;

  // 2. Add 'this.' to the constructor so it assigns the value correctly
  const CollegeHomePage({super.key, required this.collegeName});

  @override
  State<CollegeHomePage> createState() => _CollegeHomePageState();
}

class _CollegeHomePageState extends State<CollegeHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          widget.collegeName, // Now this correctly refers to the variable above
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.cardBackground,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Student Card
              _buildOptionCard(
                title: "Student",
                icon: Icons.school,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentsPage()),
                  );
                  debugPrint("Student tapped");
                },
              ),

              const SizedBox(height: 30),

              /// Faculty Card
              _buildOptionCard(
                title: "Faculty",
                icon: Icons.person,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FacultyListPage()),
                  );
                  debugPrint("Faculty tapped");
                },
              ),

              const SizedBox(height: 30),

              _buildOptionCard(
                title: "Sem Control",
                icon: Icons.menu_book_sharp,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SemesterControlPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}