// import 'package:flutter/material.dart';
// import 'package:lms_collage_admin/contents/students_add.dart';
// import '../models/studentsmodel.dart';
// import '../services/student_service.dart';
//
// class StudentsPage extends StatefulWidget {
//   const StudentsPage({super.key});
//
//   @override
//   State<StudentsPage> createState() => _StudentsPageState();
// }
//
// class _StudentsPageState extends State<StudentsPage> {
//
//   late Future<List<StudentModel>> studentsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     studentsFuture = StudentService.getStudents();
//   }
//
//   void refreshStudents() {
//     setState(() {
//       studentsFuture = StudentService.getStudents();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Students"),
//       ),
//
//       /// 🔵 Add Student Button
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const AddStudentPage(),
//             ),
//           );
//
//           /// refresh list after adding
//           refreshStudents();
//         },
//         child: const Icon(Icons.add),
//       ),
//
//       body: FutureBuilder<List<StudentModel>>(
//
//         future: studentsFuture,
//
//         builder: (context, snapshot) {
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("No Students Found"));
//           }
//
//           List<StudentModel> students = snapshot.data!;
//
//           return ListView.builder(
//             itemCount: students.length,
//             itemBuilder: (context, index) {
//
//               final student = students[index];
//
//               return Card(
//                 margin: const EdgeInsets.all(10),
//
//                 child: ListTile(
//
//                   leading: const CircleAvatar(
//                     child: Icon(Icons.person),
//                   ),
//
//                   title: Text(student.id),
//
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//
//                       Text("Branch : ${student.academic.branch}"),
//                       Text("Class : ${student.academic.className}"),
//                       Text("Roll No : ${student.academic.rollNo ?? '-'}"),
//
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:lms_collage_admin/contents/students_add.dart';
import '../models/studentsmodel.dart';
import '../services/student_service.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  late Future<List<StudentModel>> studentsFuture;

  @override
  void initState() {
    super.initState();
    studentsFuture = StudentService.getStudents();
  }

  void refreshStudents() {
    setState(() {
      studentsFuture = StudentService.getStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Management"),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentPage()),
          );
          refreshStudents();
        },
        label: const Text("Add Student"),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<StudentModel>>(
        future: studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Students Found"));
          }

          List<StudentModel> students = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: student.profile.isNotEmpty
                        ? NetworkImage(student.profile)
                        : null,
                    child: student.profile.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ID: ${student.id}", style: const TextStyle(color: Colors.blueGrey)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInfoBadge(student.academic.branch, Colors.blue),
                            const SizedBox(width: 8),
                            _buildInfoBadge("Sem ${student.academic.semester}", Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to details if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}