import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_model.dart';
import '../models/studentsmodel.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? collegeCode;

  // Controllers
  final nameCtrl      = TextEditingController();
  final idCtrl        = TextEditingController();
  final rollCtrl      = TextEditingController();
  final semesterCtrl  = TextEditingController();
  final branchCtrl    = TextEditingController();
  final classCtrl     = TextEditingController();
  final dobCtrl       = TextEditingController();
  final address1Ctrl  = TextEditingController();
  final address2Ctrl  = TextEditingController();
  final contactCtrl   = TextEditingController();
  final emailCtrl     = TextEditingController();
  final passwordCtrl  = TextEditingController();

  DateTime? _selectedDate;
  bool _obscurePassword = true;
  bool isHostel = false;
  String gender = 'Male';

  // Step tracker
  int _currentStep = 0;

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

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    loadCollege();
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
      nameCtrl, idCtrl, rollCtrl, semesterCtrl, branchCtrl,
      classCtrl, dobCtrl, address1Ctrl, address2Ctrl,
      contactCtrl, emailCtrl, passwordCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> loadCollege() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => collegeCode = prefs.getString("collegeCode"));
  }

  // ── Parent auto-create ─────────────────────────────────────────────────────
  Future<void> _addParentIfNotExists({
    required String phone,
    required String studentId,
    required String password,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection(collegeCode!)
        .doc('users')
        .collection('parents')
        .doc(phone);
    if (!(await ref.get()).exists) {
      await ref.set({
        'role': 'parent',
        'password': password,
        'studentID': studentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        dobCtrl.text =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      });
    }
  }

  // ── Save student ───────────────────────────────────────────────────────────
  Future<void> addStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (collegeCode == null) return;

    setState(() => _isLoading = true);
    try {
      final student = StudentModel(
        id:       idCtrl.text.trim(),
        name:     nameCtrl.text.trim(),
        dob:      _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!)
            : null,
        address1: address1Ctrl.text.trim(),
        address2: address2Ctrl.text.trim(),
        contact:  contactCtrl.text.trim(),
        email:    emailCtrl.text.trim(),
        gender:   gender,
        isHostel: isHostel,
        role:     'student',
        profile:  'https://static.wikimedia.org/download-android-profile.png',
        password: passwordCtrl.text.trim(),
        academic: AcademicModel(
          branch:    branchCtrl.text.trim(),
          className: classCtrl.text.trim(),
          rollNo:    int.tryParse(rollCtrl.text.trim()) ?? 0,
          semester:  int.tryParse(semesterCtrl.text.trim()) ?? 1,
        ),
      );

      await FirebaseFirestore.instance
          .collection(collegeCode!)
          .doc('users')
          .collection('students')
          .doc(student.id)
          .set(student.toMap());

      await _addParentIfNotExists(
        phone:     contactCtrl.text.trim(),
        studentId: student.id,
        password:  passwordCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Student added successfully!'),
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
    if (collegeCode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

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
                  'Add Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
              ),

              // ── Step indicator ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildStepIndicator(),
                ),
              ),

              // ── Form ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Section 0 — Personal
                        _buildSection(
                          index: 0,
                          title: 'Personal Details',
                          icon: Icons.person_rounded,
                          color: _blue,
                          children: [
                            _field(nameCtrl, 'Full Name',
                                Icons.badge_rounded),
                            _field(idCtrl, 'Student ID (Unique)',
                                Icons.tag_rounded),
                            _dobField(),
                            _genderDropdown(),
                            _field(contactCtrl, 'Phone Number',
                                Icons.phone_rounded,
                                isNumber: true),
                            _field(emailCtrl, 'Email Address',
                                Icons.email_rounded),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Section 1 — Academic
                        _buildSection(
                          index: 1,
                          title: 'Academic Info',
                          icon: Icons.school_rounded,
                          color: const Color(0xFF059669),
                          children: [
                            Row(children: [
                              Expanded(
                                  child: _field(classCtrl, 'Class',
                                      Icons.class_rounded)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _field(semesterCtrl, 'Semester',
                                      Icons.numbers_rounded,
                                      isNumber: true)),
                            ]),
                            _field(branchCtrl, 'Branch',
                                Icons.account_tree_rounded),
                            _field(rollCtrl, 'Roll No',
                                Icons.format_list_numbered_rounded,
                                isNumber: true),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Section 2 — Address
                        _buildSection(
                          index: 2,
                          title: 'Address',
                          icon: Icons.location_on_rounded,
                          color: const Color(0xFFD97706),
                          children: [
                            _field(address1Ctrl, 'Address Line 1',
                                Icons.home_rounded),
                            _field(address2Ctrl, 'Address Line 2',
                                Icons.location_city_rounded),
                            // Hostel toggle
                            _hostelToggle(),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Section 3 — Security
                        _buildSection(
                          index: 3,
                          title: 'Login & Security',
                          icon: Icons.lock_rounded,
                          color: const Color(0xFF7C3AED),
                          children: [
                            _passwordField(),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Save button
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
                const Text('New Student',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(height: 2),
                Text('Fill in the details below to enrol a student',
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

  // ── Step dots ──────────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = ['Personal', 'Academic', 'Address', 'Security'];
    final colors = [_blue,
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED)];

    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentStep = i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: active
                              ? colors[i]
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: active ? colors[i] : _textG,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < steps.length - 1) const SizedBox(width: 6),
            ],
          ),
        );
      }),
    );
  }

  // ── Section card ───────────────────────────────────────────────────────────
  Widget _buildSection({
    required int index,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _currentStep = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _currentStep == index
                ? color.withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _currentStep == index
                  ? color.withOpacity(0.10)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // header row
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
      ),
    );
  }

  // ── Field helpers ──────────────────────────────────────────────────────────
  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType:
        isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 14, color: _textD),
        validator: (v) => v!.trim().isEmpty ? 'Required' : null,
        onTap: () => setState(() {}),
        decoration: _dec(label, icon),
      ),
    );
  }

  Widget _dobField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: dobCtrl,
        readOnly: true,
        onTap: _pickDob,
        style: const TextStyle(fontSize: 14, color: _textD),
        validator: (v) => v!.isEmpty ? 'Select date of birth' : null,
        decoration: _dec('Date of Birth', Icons.calendar_month_rounded),
      ),
    );
  }

  Widget _genderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: gender,
        style: const TextStyle(fontSize: 14, color: _textD),
        dropdownColor: _card,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: _accent),
        decoration: _dec('Gender', Icons.wc_rounded),
        items: ['Male', 'Female', 'Other']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => gender = v!),
      ),
    );
  }

  Widget _passwordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
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
      ),
    );
  }

  Widget _hostelToggle() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _input,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.hotel_rounded, color: _accent, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hostel Student',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textD)),
                Text('Enable if student lives in hostel',
                    style: TextStyle(fontSize: 11, color: _textG)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isHostel,
            onChanged: (v) => setState(() => isHostel = v),
            activeColor: _blue,
          ),
        ],
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
          onPressed: _isLoading ? null : addStudent,
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
                'Save Student',
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