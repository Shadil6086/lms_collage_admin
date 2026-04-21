import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../strings/colors.dart';

class SemesterDetailsPage extends StatefulWidget {
  final String collegeCode;
  final String semesterId;

  const SemesterDetailsPage({
    super.key,
    required this.collegeCode,
    required this.semesterId,
  });

  @override
  State<SemesterDetailsPage> createState() => _SemesterDetailsPageState();
}

class _SemesterDetailsPageState extends State<SemesterDetailsPage> {
  Future<void> _addDepartment() async {
    final TextEditingController deptController = TextEditingController();

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Department'),
        content: TextField(
          controller: deptController,
          decoration: const InputDecoration(
            hintText: 'e.g. Computer Science',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (deptController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deptName = deptController.text.trim();
      final docRef = FirebaseFirestore.instance.collection(widget.collegeCode).doc(widget.semesterId);

      // 1. Add to the array so we can list it dynamically on the screen
      await docRef.set({
        'departments': FieldValue.arrayUnion([deptName])
      }, SetOptions(merge: true));

      // 2. Initialize the Sub-Collection so it exists physically in the database hierarchy
      await docRef.collection(deptName).doc('settings').set({
        'initialized': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$deptName Registered Successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteDepartment(String deptName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Department?'),
        content: Text('Are you sure you want to unregister "$deptName"? \n\nNote: This only removes it from the list. It does not delete existing sub-collection data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final docRef = FirebaseFirestore.instance.collection(widget.collegeCode).doc(widget.semesterId);
      await docRef.update({
        'departments': FieldValue.arrayRemove([deptName])
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$deptName removed!'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.semesterId} Departments', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDepartment,
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Dept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(widget.collegeCode)
            .doc(widget.semesterId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final List departments = (data != null && data.containsKey('departments')) 
              ? data['departments'] as List 
              : [];

          if (departments.isEmpty) {
             return Center(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Icon(Icons.business_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                   const SizedBox(height: 16),
                   const Text('No Departments Registered', style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500)),
                   const SizedBox(height: 8),
                   const Text('Tap the + button to add the first department.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                 ],
               )
             );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final String deptName = departments[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business, color: Color(0xFF3B82F6), size: 24),
                  ),
                  title: Text(
                    deptName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  subtitle: const Text('Manage Timetable, Students...', style: TextStyle(color: Color(0xFF64748B))),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Edit Name')]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete')]),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'delete') {
                        _deleteDepartment(deptName);
                      } else if (val == 'edit') {
                        // Firebase doesn't support easy "rename collection", so renaming the array item effectively abandons the old collection.
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('To rename, please delete and create a new department.')));
                      }
                    },
                  ),
                  onTap: () {
                    // Navigate into specific department if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}