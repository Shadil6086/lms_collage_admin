import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusPassAdminPage extends StatefulWidget {
  const BusPassAdminPage({super.key});

  @override
  State<BusPassAdminPage> createState() => _BusPassAdminPageState();
}

class _BusPassAdminPageState extends State<BusPassAdminPage> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _routeNumberController = TextEditingController();
  final TextEditingController _routeNameController = TextEditingController();

  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 365));

  bool _isLoading = false;
  bool _isPassFetched = false;
  bool _passExists = false;
  String _currentPassId = '';
  String _collegeId = '';

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

  Future<void> _fetchStudentBusPass() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Student ID')),
      );
      return;
    }

    if (_collegeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('College ID not found. Please log in again.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isPassFetched = false;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collegeId)
          .doc('users')
          .collection('students')
          .doc(studentId)
          .collection('Transpotaion') // Using user's spelling
          .doc('BusPass')
          .get();

      setState(() {
        _isPassFetched = true;
        if (doc.exists && doc.data() != null) {
          _passExists = true;
          final data = doc.data()!;
          _currentPassId = data['passID'] ?? '';
          _routeNumberController.text = data['routeNumber'].toString();
          _routeNameController.text = data['routeName'] ?? '';
          
          if (data['validFrom'] != null) {
             _validFrom = (data['validFrom'] as Timestamp).toDate();
          }
          if (data['validUntil'] != null) {
             _validUntil = (data['validUntil'] as Timestamp).toDate();
          }
        } else {
          _passExists = false;
          _currentPassId = '';
          _routeNumberController.clear();
          _routeNameController.clear();
          _validFrom = DateTime.now();
          _validUntil = DateTime.now().add(const Duration(days: 365));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBusPass() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty || _routeNumberController.text.trim().isEmpty || _routeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String passId = _currentPassId;
      if (!_passExists) {
        final year = DateTime.now().year;
        final randomNum = Random().nextInt(9000) + 1000; 
        passId = 'BP-$year-$randomNum'; // Generate Pass ID
      }

      await FirebaseFirestore.instance
          .collection(_collegeId)
          .doc('users')
          .collection('students')
          .doc(studentId)
          .collection('Transpotaion')
          .doc('BusPass')
          .set({
        'passID': passId,
        'routeNumber': _routeNumberController.text.trim(),
        'routeName': _routeNameController.text.trim(),
        'validFrom': Timestamp.fromDate(_validFrom),
        'validUntil': Timestamp.fromDate(_validUntil),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _passExists = true;
        _currentPassId = passId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus Pass saved successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving bus pass: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final initialDate = isFrom ? _validFrom : _validUntil;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Bus Passes', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        shadowColor: Colors.black12,
      ),
      body: _isLoading && !_isPassFetched
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text('Search Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _studentIdController,
                              decoration: const InputDecoration(
                                hintText: 'Enter Student ID (e.g. STU-1234)',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _fetchStudentBusPass(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                            onPressed: _fetchStudentBusPass,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  if (_isPassFetched) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _passExists ? 'Edit Bus Pass' : 'Generate New Bus Pass',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              if (_passExists)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _validUntil.isBefore(DateTime.now()) ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _validUntil.isBefore(DateTime.now()) ? 'Expired' : 'Active',
                                    style: TextStyle(
                                      color: _validUntil.isBefore(DateTime.now()) ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          if (_passExists) ...[
                            Text('Pass ID: $_currentPassId', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            const SizedBox(height: 16),
                          ],

                          _buildTextField('Route Number', _routeNumberController),
                          const SizedBox(height: 16),
                          _buildTextField('Route Name', _routeNameController),
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Expanded(child: _buildDatePicker('Valid From', _validFrom, true)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDatePicker('Valid Until', _validUntil, false)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _saveBusPass,
                              child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _passExists ? 'Update Bus Pass' : 'Generate Bus Pass',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, bool isFrom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isFrom),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(color: Color(0xFF0F172A))),
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
