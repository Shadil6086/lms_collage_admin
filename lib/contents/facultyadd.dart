import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../strings/colors.dart';

class AddFacultyPage extends StatefulWidget {
  const AddFacultyPage({super.key});

  @override
  State<AddFacultyPage> createState() => _AddFacultyPageState();
}

class _AddFacultyPageState extends State<AddFacultyPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final idCtrl         = TextEditingController();
  final nameCtrl       = TextEditingController();
  final emailCtrl      = TextEditingController();
  final phoneCtrl      = TextEditingController();
  final passwordCtrl   = TextEditingController();
  final departmentCtrl = TextEditingController();
  final branchCtrl     = TextEditingController();
  final classCtrl      = TextEditingController();
  final semesterCtrl   = TextEditingController();
  final address1Ctrl   = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── Colour tokens ──────────────────────────────────────────────────────────
  static const _navy   = Color(0xFF0F2557);
  static const _blue   = Color(0xFF1A4FCE);
  static const _accent = Color(0xFF4F8EF7);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Color(0xFFFFFFFF);
  static const _input  = Color(0xFFF4F7FF);
  static const _border = Color(0xFFD6E0FF);
  static const _textD  = Color(0xFF1E293B);
  static const _textG  = Color(0xFF7A8AAD);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in [
      idCtrl, nameCtrl, emailCtrl, phoneCtrl, passwordCtrl,
      departmentCtrl, branchCtrl, classCtrl, semesterCtrl, address1Ctrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Save faculty ───────────────────────────────────────────────────────────
  Future<void> _addFaculty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final id = idCtrl.text.trim();
      await FirebaseFirestore.instance
          .collection('MEA')
          .doc('users')
          .collection('faculty')
          .doc(id)
          .set({
        'id':         id,
        'name':       nameCtrl.text.trim(),
        'email':      emailCtrl.text.trim(),
        'contact':    phoneCtrl.text.trim(),
        'password':   passwordCtrl.text.trim(),
        'department': departmentCtrl.text.trim(),
        'role':       'faculty',
        'gender':     'Male',
        'DOB':        Timestamp.now(),
        'address1':   address1Ctrl.text.trim(),
        'Academic': {
          'branch':   branchCtrl.text.trim(),
          'class':    classCtrl.text.trim(),
          'semester': int.tryParse(semesterCtrl.text.trim()) ?? 1,
        },
        'class':     ['CS1', 'CS2'],
        'messageId': '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Faculty added successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── AppBar ───────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: _navy,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroHeader(),
                ),
                title: const Text(
                  'Add Faculty',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
              ),

              // ── Form ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        // ── Section: Identity ──────────────────────────
                        _section(
                          title: 'Identity',
                          icon: Icons.badge_rounded,
                          color: _blue,
                          children: [
                            _field(idCtrl,   'Faculty ID',  Icons.tag_rounded),
                            _field(nameCtrl, 'Full Name',   Icons.person_rounded),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Section: Contact ───────────────────────────
                        _section(
                          title: 'Contact',
                          icon: Icons.contact_phone_rounded,
                          color: const Color(0xFF059669),
                          children: [
                            _field(emailCtrl, 'Email Address',
                                Icons.email_rounded),
                            _field(phoneCtrl, 'Phone Number',
                                Icons.phone_rounded,
                                isNumber: true),
                            _field(address1Ctrl, 'Address',
                                Icons.home_rounded),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Section: Academic ──────────────────────────
                        _section(
                          title: 'Academic',
                          icon: Icons.school_rounded,
                          color: const Color(0xFFD97706),
                          children: [
                            _field(departmentCtrl, 'Department',
                                Icons.business_rounded),
                            _field(branchCtrl, 'Branch',
                                Icons.account_tree_rounded),
                            Row(children: [
                              Expanded(
                                child: _field(classCtrl, 'Class',
                                    Icons.class_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(semesterCtrl, 'Semester',
                                    Icons.numbers_rounded,
                                    isNumber: true),
                              ),
                            ]),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Section: Security ──────────────────────────
                        _section(
                          title: 'Security',
                          icon: Icons.lock_rounded,
                          color: const Color(0xFF7C3AED),
                          children: [_passwordField()],
                        ),

                        const SizedBox(height: 28),

                        // ── Save button ────────────────────────────────
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2557), Color(0xFF1A4FCE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -40,
              child: _circle(160, Colors.white.withOpacity(0.05))),
          Positioned(left: -20, bottom: -30,
              child: _circle(120, Colors.white.withOpacity(0.04))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 70, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('New Faculty',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(height: 2),
                Text('Fill in the details to register a faculty member',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double s, Color c) => Container(
      width: s, height: s,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  // ── Section card ───────────────────────────────────────────────────────────
  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: -0.2,
                    )),
              ],
            ),
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Field helpers ──────────────────────────────────────────────────────────
  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType:
        isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 14, color: _textD),
        validator: (v) => v!.trim().isEmpty ? 'Required' : null,
        decoration: _dec(label, icon),
      ),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: passwordCtrl,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 14, color: _textD),
      validator: (v) =>
      v!.length < 6 ? 'Minimum 6 characters' : null,
      decoration: _dec('Login Password', Icons.lock_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _textG,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textG, fontSize: 13),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      filled: true,
      fillColor: _input,
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
    );
  }

  // ── Save button ────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A4FCE), Color(0xFF4F8EF7)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.38),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _addFaculty,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5))
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Save Faculty',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}