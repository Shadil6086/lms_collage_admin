import 'package:flutter/material.dart';

class CollegeLoginPage extends StatefulWidget {
  const CollegeLoginPage({super.key});

  @override
  State<CollegeLoginPage> createState() => _CollegeLoginPageState();
}

class _CollegeLoginPageState extends State<CollegeLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  String? _selectedCollege;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _colleges = [
    'ABC Engineering College',
    'XYZ Arts & Science College',
    'National Institute of Technology',
    'Government Polytechnic',
  ];

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate API Call/Validation
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);
      debugPrint('Logging into: $_selectedCollege');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding
                const Icon(Icons.account_balance_rounded, size: 80, color: Colors.indigo),
                const SizedBox(height: 16),
                Text(
                  'AdminPortal',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const Text('Login to your Collage'),
                const SizedBox(height: 40),

                // Form Container
                Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Select Collage'),
                        _buildCollegeDropdown(),
                        const SizedBox(height: 24),

                        _buildLabel('Password'),
                        _buildPasswordField(),

                        _buildForgotPassword(),
                        const SizedBox(height: 32),

                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildCollegeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCollege,
      isExpanded: true,
      decoration: _inputDecoration(Icons.school_outlined),
      hint: const Text('Choose your college'),
      items: _colleges.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() => _selectedCollege = val),
      validator: (val) => val == null ? 'Please select your college' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: _inputDecoration(
        Icons.lock_outline,
        hint: 'Enter Pass key',
        suffix: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        child: const Text('Forgot Password?', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
        )
            : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData prefix, {String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefix, size: 20, color: Colors.indigo[400]),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }
}