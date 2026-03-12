import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../strings/colors.dart';
import 'SemesterDetailsPage.dart';

class SemesterControlPage extends StatefulWidget {
  const SemesterControlPage({super.key});

  @override
  State<SemesterControlPage> createState() => _SemesterControlPageState();
}

class _SemesterControlPageState extends State<SemesterControlPage> {
  String? collegeCode;

  final List<String> allowedSemesters = [
    'S1',
    'S2',
    'S3',
    'S4',
    'S5',
    'S6',
  ];

  @override
  void initState() {
    super.initState();
    _loadCollege();
  }

  Future<void> _loadCollege() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      collegeCode = prefs.getString("collegeCode");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (collegeCode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          "Semester Control",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collegeCode!)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔥 Filter only S1–S6
          final semesters = snapshot.data!.docs
              .where((doc) => allowedSemesters.contains(doc.id))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: semesters.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {

                final semId = semesters[index].id;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SemesterDetailsPage(
                          collegeCode: collegeCode!,
                          semesterId: semId,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            semId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}