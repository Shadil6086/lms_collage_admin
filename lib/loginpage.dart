import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms_collage_admin/strings/colors.dart';
import 'homepage.dart';

class CollegeLoginPage extends StatefulWidget {
  const CollegeLoginPage({super.key});

  @override
  State<CollegeLoginPage> createState() => _CollegeLoginPageState();
}

class _CollegeLoginPageState extends State<CollegeLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  List<Map<String, dynamic>> _colleges = [];
  String? _selectedCollegeCode;
  bool _loading = true;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('colleges') // Ensure this doc exists
          .get();

      if (doc.exists && doc.data() != null) {
        // Since your Firestore has keys "0", "1", etc., doc.data() is a Map.
        // We convert the Map values into a List.
        final Map<String, dynamic> data = doc.data()!;

        List<Map<String, dynamic>> tempList = [];

        // This iterates through keys "0", "1" and adds the inner maps to our list
        data.forEach((key, value) {
          if (value is Map) {
            tempList.add(Map<String, dynamic>.from(value));
          }
        });

        setState(() {
          _colleges = tempList;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Firestore Error: $e");
      setState(() => _loading = false);
    }
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    // Find the college by its code
    final college = _colleges.firstWhere(
      (c) => c['code'] == _selectedCollegeCode,
      orElse: () => {},
    );

    if (college.isNotEmpty && _passwordController.text == college['password']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome ${college['name']}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CollegeHomePage(collegeName: college['name']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid password or selection',
            style: TextStyle(color: AppColors.cardBackground),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Container(
          width: 360,
          height: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'College Login',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cardBackground,
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// College Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedCollegeCode,
                        style: const TextStyle(
                          color: Colors.white,
                        ), // Text color inside dropdown
                        dropdownColor: AppColors
                            .primaryBlue, // Background of the popup menu
                        decoration: InputDecoration(
                          labelText: 'Select College',
                          labelStyle: const TextStyle(
                            color: AppColors.cardBackground,
                          ),
                          // Define the border colors here
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2.0,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        iconEnabledColor: Colors.white, // Dropdown arrow color
                        items: _colleges.map((college) {
                          return DropdownMenuItem<String>(
                            value: college['code'].toString(),
                            child: Text(
                              college['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                              ), // Items text color
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCollegeCode = value),
                        validator: (value) =>
                            value == null ? 'Select a college' : null,
                      ),

                      const SizedBox(height: 16),

                      /// Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: const TextStyle(
                          color: Colors.white,
                        ), // Input text color
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                            color: AppColors.cardBackground,
                          ),
                          // Define the border colors here
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2.0,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white, // Visibility icon color
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter password' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
