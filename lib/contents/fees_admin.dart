import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeesAdminPage extends StatefulWidget {
  const FeesAdminPage({super.key});

  @override
  State<FeesAdminPage> createState() => _FeesAdminPageState();
}

class _FeesAdminPageState extends State<FeesAdminPage> {
  final TextEditingController _studentIdController = TextEditingController();

  // Controllers for Add Fee form
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _assignToAllStudents = false;

  String _collegeId = '';
  bool _isLoading = false;
  bool _isFetched = false;
  Map<String, dynamic> _feesData = {};

  @override
  void initState() {
    super.initState();
    _loadCollegeId();
  }

  Future<void> _loadCollegeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collegeId = prefs.getString("collegeCode") ?? "";
    });
  }

  Future<void> _fetchStudentFees() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Student ID')),
      );
      return;
    }

    if (_collegeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('College ID not found. Please log in again.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isFetched = false;
      _feesData = {};
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collegeId)
          .doc('users')
          .collection('students')
          .doc(studentId)
          .collection('fees')
          .doc('details')
          .get();

      setState(() {
        _isFetched = true;
        if (doc.exists && doc.data() != null) {
          _feesData = Map<String, dynamic>.from(doc.data()!);
        } else {
          _feesData = {};
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFee() async {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final studentId = _studentIdController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (!_assignToAllStudents && studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Student ID or toggle Apply to All'),
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be a valid number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final feeId = DateTime.now().millisecondsSinceEpoch.toString();
      final feeRecord = {
        'title': title,
        'amount': amount,
        'due': Timestamp.fromDate(_dueDate),
        'isPaid': false,
        'paymentDate': null,
        'bill': null,
      };

      if (_assignToAllStudents) {
        // Batch assignment for all students
        final studentsSnap = await FirebaseFirestore.instance
            .collection(_collegeId)
            .doc('users')
            .collection('students')
            .get();

        final batch = FirebaseFirestore.instance.batch();

        for (var doc in studentsSnap.docs) {
          final targetRef = FirebaseFirestore.instance
              .collection(_collegeId)
              .doc('users')
              .collection('students')
              .doc(doc.id)
              .collection('fees')
              .doc('details');
          batch.set(targetRef, {feeId: feeRecord}, SetOptions(merge: true));
        }

        await batch.commit();
      } else {
        // Single student assignment
        await FirebaseFirestore.instance
            .collection(_collegeId)
            .doc('users')
            .collection('students')
            .doc(studentId)
            .collection('fees')
            .doc('details')
            .set({feeId: feeRecord}, SetOptions(merge: true));

        // Only update local view if we are looking at this specific student
        if (_studentIdController.text.trim() == studentId) {
          setState(() {
            _feesData[feeId] = feeRecord;
          });
        }
      }

      setState(() {
        _titleCtrl.clear();
        _amountCtrl.clear();
        _dueDate = DateTime.now().add(const Duration(days: 30));
        _assignToAllStudents = false;
      });

      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _assignToAllStudents
                ? 'College Fee applied to all students!'
                : 'Fee added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding fee: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsPaidAndUpload(String feeId) async {
    final studentId = _studentIdController.text.trim();

    // 1. Pick File
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      return; // Cancelled
    }

    setState(() => _isLoading = true);

    try {
      String fileName = result.files.single.name;
      String? fileUrl;

      // Ensure a unique name in case of overlaps
      fileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // 2. Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
        '$_collegeId/fees/$studentId/$fileName',
      );

      // Web/Mobile universal memory upload
      final uploadTask = storageRef.putData(result.files.single.bytes!);
      final snapshot = await uploadTask;
      fileUrl = await snapshot.ref.getDownloadURL();

      // 3. Update Firestore Document
      final updatedData = Map<String, dynamic>.from(_feesData[feeId] as Map);
      updatedData['isPaid'] = true;
      updatedData['paymentDate'] = Timestamp.now();
      updatedData['bill'] = fileUrl;

      await FirebaseFirestore.instance
          .collection(_collegeId)
          .doc('users')
          .collection('students')
          .doc(studentId)
          .collection('fees')
          .doc('details')
          .set({feeId: updatedData}, SetOptions(merge: true));

      setState(() {
        _feesData[feeId] = updatedData;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fee marked as Paid and Bill uploaded!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsUnpaid(String feeId) async {
    final studentId = _studentIdController.text.trim();
    setState(() => _isLoading = true);

    try {
      final updatedData = Map<String, dynamic>.from(_feesData[feeId] as Map);
      updatedData['isPaid'] = false;
      updatedData['paymentDate'] = null;
      updatedData['bill'] = null; // optional: remove bill if unpaid

      await FirebaseFirestore.instance
          .collection(_collegeId)
          .doc('users')
          .collection('students')
          .doc(studentId)
          .collection('fees')
          .doc('details')
          .set({feeId: updatedData}, SetOptions(merge: true));

      setState(() {
        _feesData[feeId] = updatedData;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fee marked as Unpaid')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddFeeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Add Fee Record',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title (e.g. Tuition Fee)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (e.g. 5000)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Due Date:',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            setDialogState(() => _dueDate = picked);
                        },
                        child: Text(
                          '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      value: _assignToAllStudents,
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => _assignToAllStudents = val);
                      },
                      title: const Text(
                        'Apply to ALL students',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Marks this as a College Level fee',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      activeColor: const Color(0xFF3B82F6),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                ),
                onPressed: _addFee,
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manage student fees',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        shadowColor: Colors.black12,
      ),
      floatingActionButton: _isFetched
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF3B82F6),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Fee',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _showAddFeeDialog,
            )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search Student',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _studentIdController,
                          decoration: const InputDecoration(
                            hintText: 'Enter Student ID (e.g. STU-123)',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _fetchStudentFees(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF3B82F6),
                        ),
                        onPressed: _fetchStudentFees,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),

          if (!_isLoading && _isFetched)
            Expanded(
              child: _feesData.isEmpty
                  ? const Center(
                      child: Text(
                        'No fee records found for this student',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _feesData.length,
                      itemBuilder: (context, index) {
                        final feeId = _feesData.keys.elementAt(index);
                        final feeInfo =
                            _feesData[feeId] as Map<String, dynamic>;

                        final title = feeInfo['title'] ?? 'Unknown Fee';
                        final amount = feeInfo['amount']?.toString() ?? '0';
                        final isPaid = feeInfo['isPaid'] ?? false;
                        final billUrl = feeInfo['bill'];

                        DateTime dueDate = DateTime.now();
                        if (feeInfo['due'] != null) {
                          dueDate = (feeInfo['due'] as Timestamp).toDate();
                        }

                        final isOverdue =
                            !isPaid && DateTime.now().isAfter(dueDate);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  _buildStatusBadge(isPaid, isOverdue),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Amount: \$${amount}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (billUrl != null)
                                    TextButton.icon(
                                      onPressed: () {}, // Optional: open URL
                                      icon: const Icon(
                                        Icons.receipt_long,
                                        color: Color(0xFF0D9488),
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'View Bill',
                                        style: TextStyle(
                                          color: Color(0xFF0D9488),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(),

                                  if (isPaid)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFEF2F2,
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () => _markAsUnpaid(feeId),
                                      icon: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Color(0xFFDC2626),
                                      ),
                                      label: const Text(
                                        'Mark Unpaid',
                                        style: TextStyle(
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFECFDF5,
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () =>
                                          _markAsPaidAndUpload(feeId),
                                      icon: const Icon(
                                        Icons.upload_file,
                                        size: 16,
                                        color: Color(0xFF059669),
                                      ),
                                      label: const Text(
                                        'Mark Paid & Upload',
                                        style: TextStyle(
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isPaid, bool isOverdue) {
    Color bg, text;
    String label;
    if (isPaid) {
      bg = const Color(0xFFECFDF5);
      text = const Color(0xFF059669);
      label = 'Paid';
    } else if (isOverdue) {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFDC2626);
      label = 'Overdue';
    } else {
      bg = const Color(0xFFFFFBEB);
      text = const Color(0xFFD97706);
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
