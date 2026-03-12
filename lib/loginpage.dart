import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// FETCH COLLEGES FROM FIRESTORE
  Future<void> _fetchColleges() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('colleges')
          .get();

      if (doc.exists && doc.data() != null) {
        final Map<String, dynamic> data = doc.data()!;

        List<Map<String, dynamic>> temp = [];

        data.forEach((key, value) {
          if (value is Map) {
            temp.add(Map<String, dynamic>.from(value));
          }
        });

        setState(() {
          _colleges = temp;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Firestore error: $e");
      setState(() => _loading = false);
    }
  }

  /// LOGIN FUNCTION
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final college = _colleges.firstWhere(
          (c) => c['code'] == _selectedCollegeCode,
      orElse: () => {},
    );

    if (college.isNotEmpty && _passwordController.text == college['password']) {
      /// SAVE LOGIN DATA
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString("collegeCode", college['code']);
      await prefs.setString("collegeName", college['name']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome ${college['name']}"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CollegeHomePage(collegeName: college['name']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Invalid password or college",
            style: TextStyle(color: Colors.white),
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black12,
              )
            ],
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
                  "College Login",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cardBackground,
                  ),
                ),

                const SizedBox(height: 24),

                /// COLLEGE DROPDOWN
                DropdownButtonFormField<String>(
                  value: _selectedCollegeCode,
                  isExpanded: true,
                  dropdownColor: AppColors.primaryBlue,
                  style: const TextStyle(color: Colors.white),

                  decoration: const InputDecoration(
                    labelText: "Select College",
                    labelStyle:
                    TextStyle(color: AppColors.cardBackground),

                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderSide:
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),

                  iconEnabledColor: Colors.white,

                  items: _colleges.map((college) {
                    return DropdownMenuItem<String>(
                      value: college['code'].toString(),
                      child: Text(
                        college['name'] ?? "Unknown",
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      _selectedCollegeCode = value;
                    });
                  },

                  validator: (value) =>
                  value == null ? "Select a college" : null,
                ),

                const SizedBox(height: 16),

                /// PASSWORD FIELD
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),

                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(
                      color: AppColors.cardBackground,
                    ),

                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),

                    focusedBorder: const OutlineInputBorder(
                      borderSide:
                      BorderSide(color: Colors.white, width: 2),
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                  ),

                  validator: (value) =>
                  value!.isEmpty ? "Enter password" : null,
                ),

                const SizedBox(height: 24),

                /// LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text("Login"),
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