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
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    // Static semesters S1 to S8 for typical 4-year programs
    final List<String> staticSemesters = List.generate(8, (index) => 'S${index + 1}');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Semester Control",
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Premium Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2557), Color(0xFF1A4FCE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Academic Roadmap', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Select a semester to initialize or manage connected departments.', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: staticSemesters.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (context, index) {
                final semId = staticSemesters[index];

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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                         BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_outlined,
                            color: Color(0xFF3B82F6),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          semId,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage Depts',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}