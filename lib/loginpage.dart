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

class _CollegeLoginPageState extends State<CollegeLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  List<Map<String, dynamic>> _colleges = [];
  String? _selectedCollegeCode;

  bool _loading = true;
  bool _obscure = true;
  bool _loggingIn = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Colour tokens ──────────────────────────────────────────────────────────
  static const _navy     = Color(0xFF0F2557);
  static const _blue     = Color(0xFF1A4FCE);
  static const _accent   = Color(0xFF4F8EF7);
  static const _surface  = Color(0xFFFFFFFF);
  static const _inputBg  = Color(0xFFF4F7FF);
  static const _border   = Color(0xFFD6E0FF);
  static const _textDark = Color(0xFF0F2557);
  static const _textGrey = Color(0xFF7A8AAD);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchColleges();
  }

  @override
  void dispose() {
    _animController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Fetch colleges ─────────────────────────────────────────────────────────
  Future<void> _fetchColleges() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('colleges')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final List<Map<String, dynamic>> temp = [];
        data.forEach((key, value) {
          if (value is Map) temp.add(Map<String, dynamic>.from(value));
        });
        setState(() {
          _colleges = temp;
          _loading  = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Firestore error: $e");
      setState(() => _loading = false);
    }

    _animController.forward();
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loggingIn = true);

    final college = _colleges.firstWhere(
          (c) => c['code'] == _selectedCollegeCode,
      orElse: () => {},
    );

    if (college.isNotEmpty &&
        _passwordController.text == college['password']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("collegeCode", college['code']);
      await prefs.setString("collegeName", college['name']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome, ${college['name']}"),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CollegeHomePage(collegeName: college['name']),
        ),
      );
    } else {
      if (!mounted) return;
      setState(() => _loggingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Invalid college or password"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background ───────────────────────────────────────────────────
          _buildBackground(size),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background with layered gradients + circles ────────────────────────────
  Widget _buildBackground(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1A4A), Color(0xFF1A4FCE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // large top-right circle
          Positioned(
            right: -80, top: -80,
            child: _bgCircle(280, Colors.white.withOpacity(0.05)),
          ),
          // small bottom-left circle
          Positioned(
            left: -50, bottom: 40,
            child: _bgCircle(200, Colors.white.withOpacity(0.04)),
          ),
          // tiny accent circle
          Positioned(
            left: 60, top: size.height * 0.15,
            child: _bgCircle(60, Colors.white.withOpacity(0.07)),
          ),
          // dot grid pattern (subtle)
          Positioned.fill(child: _dotGrid()),
        ],
      ),
    );
  }

  Widget _bgCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _dotGrid() {
    return CustomPaint(painter: _DotGridPainter());
  }

  // ── Login card ─────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 48,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Card top banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2557), Color(0xFF1A4FCE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // logo badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Collage Admin Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to your college dashboard',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Form ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // College dropdown
                  _label('Select College'),
                  const SizedBox(height: 8),
                  _buildDropdown(),

                  const SizedBox(height: 20),

                  // Password
                  _label('Password'),
                  const SizedBox(height: 8),
                  _buildPasswordField(),

                  const SizedBox(height: 28),

                  // Login button
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field label ────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _textDark,
      letterSpacing: 0.1,
    ),
  );

  // ── Dropdown ───────────────────────────────────────────────────────────────
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCollegeCode,
      isExpanded: true,
      dropdownColor: _surface,
      style: const TextStyle(color: _textDark, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
      decoration: InputDecoration(
        hintText: 'Choose your institution',
        hintStyle: TextStyle(color: _textGrey, fontSize: 13),
        prefixIcon: const Icon(Icons.school_rounded, color: _accent, size: 20),
        filled: true,
        fillColor: _inputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.8),
        ),
      ),
      items: _colleges.map((college) {
        return DropdownMenuItem<String>(
          value: college['code'].toString(),
          child: Text(
            college['name'] ?? 'Unknown',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _textDark),
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCollegeCode = value),
      validator: (v) => v == null ? 'Please select a college' : null,
    );
  }

  // ── Password field ─────────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscure,
      style: const TextStyle(color: _textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: TextStyle(color: _textGrey, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: _accent, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _textGrey,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: _inputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.8),
        ),
      ),
      validator: (v) => v!.isEmpty ? 'Password cannot be empty' : null,
    );
  }

  // ── Login button ───────────────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A4FCE), Color(0xFF4F8EF7)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loggingIn ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _loggingIn
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dot grid background painter ────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const radius  = 1.5;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}