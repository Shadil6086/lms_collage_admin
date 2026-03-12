import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../strings/colors.dart';

class SemesterDetailsPage extends StatelessWidget {
  final String collegeCode;
  final String semesterId;

  const SemesterDetailsPage({
    super.key,
    required this.collegeCode,
    required this.semesterId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          semesterId,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collegeCode)
            .doc(semesterId)
            .collection(semesterId) // 👈 read documents inside semester
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final departments = snapshot.data!.docs;

          if (departments.isEmpty) {
            return const Center(child: Text("No Data Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: departments.length,
            itemBuilder: (context, index) {

              final deptName = departments[index].id;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: ListTile(
                  leading: const Icon(Icons.school, color: Colors.blue),
                  title: Text(
                    deptName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),

                  onTap: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}