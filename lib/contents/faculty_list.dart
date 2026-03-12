import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../strings/colors.dart';
import 'facultyadd.dart';

class FacultyListPage extends StatefulWidget {
  const FacultyListPage({super.key});

  @override
  State<FacultyListPage> createState() => _FacultyListPageState();
}

class _FacultyListPageState extends State<FacultyListPage> {
  String? collegeCode;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollege();
  }

  Future<void> _loadCollege() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString("collegeCode");

    // Debug: print(code); // Check if this is actually the unique college ID

    setState(() {
      collegeCode = code;
      _isInitialLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Safety check: If no college code is found in SharedPreferences
    if (collegeCode == null || collegeCode!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("No College Code found. Please log in again.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Faculties',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFacultyPage()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 This path ensures we ONLY get faculties inside THIS specific college document
        stream: FirebaseFirestore.instance
            .collection(collegeCode!)
            .doc('users')
            .collection('faculty')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No faculties found for $collegeCode',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    backgroundImage: (data['profile'] != null && data['profile'].toString().isNotEmpty)
                        ? NetworkImage(data['profile'])
                        : null,
                    child: (data['profile'] == null || data['profile'].toString().isEmpty)
                        ? const Icon(Icons.person, color: AppColors.primaryBlue)
                        : null,
                  ),
                  title: Text(
                    data['name'] ?? 'Unknown Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(),
                    child: Text(
                      '${data['department'] ?? 'No Dept'} • ${data['role'] ?? 'Faculty'}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  trailing: Text(
                    doc.id,
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}