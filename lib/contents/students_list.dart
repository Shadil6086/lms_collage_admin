import 'package:flutter/material.dart';
import 'package:lms_collage_admin/contents/students_add.dart';
import '../models/studentsmodel.dart';
import '../services/student_service.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage>
    with SingleTickerProviderStateMixin {
  late Future<List<StudentModel>> _studentsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Colour tokens ──────────────────────────────────────────────────────────
  static const _navy   = Color(0xFF0F2557);
  static const _blue   = Color(0xFF1A4FCE);
  static const _accent = Color(0xFF4F8EF7);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _studentsFuture = StudentService.getStudents();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(
          () => _studentsFuture = StudentService.getStudents());

  List<StudentModel> _filtered(List<StudentModel> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((s) =>
    s.name.toLowerCase().contains(q) ||
        s.id.toLowerCase().contains(q) ||
        s.academic.branch.toLowerCase().contains(q)).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FutureBuilder<List<StudentModel>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── Hero AppBar ────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 170,
                pinned: true,
                backgroundColor: _navy,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white),
                    onPressed: _refresh,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroHeader(snapshot),
                ),
                title: const Text(
                  'Students',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
              ),

              // ── Search bar ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: _buildSearchBar(),
                ),
              ),

              // ── Body ───────────────────────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _accent),
                  ),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: _buildEmptyState(
                    icon: Icons.error_outline_rounded,
                    color: Colors.red,
                    title: 'Something went wrong',
                    subtitle: snapshot.error.toString(),
                  ),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(
                      icon: Icons.school_outlined,
                      color: _accent,
                      title: 'No Students Yet',
                      subtitle: 'Tap + to add your first student',
                    ),
                  )
                else ...[
                    // results count
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                        child: _buildResultsLabel(
                            _filtered(snapshot.data!).length,
                            snapshot.data!.length),
                      ),
                    ),

                    // list
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, i) {
                            final list = _filtered(snapshot.data!);
                            if (list.isEmpty) {
                              return _buildEmptyState(
                                icon: Icons.search_off_rounded,
                                color: _accent,
                                title: 'No results',
                                subtitle: 'Try a different search term',
                              );
                            }
                            return FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildStudentCard(list[i], i),
                            );
                          },
                          childCount: _filtered(snapshot.data!).isEmpty
                              ? 1
                              : _filtered(snapshot.data!).length,
                        ),
                      ),
                    ),
                  ],
            ],
          );
        },
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Hero header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(AsyncSnapshot<List<StudentModel>> snapshot) {
    final count = snapshot.data?.length ?? 0;

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
              child: _circle(180, Colors.white.withAlpha(13))),
          Positioned(left: -20, bottom: -30,
              child: _circle(130, Colors.white.withAlpha(10))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 70, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Student Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statPill(Icons.people_rounded,
                        '$count Total', Colors.white.withAlpha(51)),
                    const SizedBox(width: 10),
                    _statPill(Icons.circle, 'Active',
                        Colors.green.withAlpha(77),
                        dotColor: const Color(0xFF34D399)),
                  ],
                ),
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

  Widget _statPill(IconData icon, String label, Color bg,
      {Color? dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null)
            Container(
              width: 7, height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                  color: dotColor, shape: BoxShape.circle),
            )
          else
            Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(
            fontSize: 14, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Search by name, ID or branch…',
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: _accent, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // ── Results label ──────────────────────────────────────────────────────────
  Widget _buildResultsLabel(int shown, int total) {
    return Text(
      _searchQuery.isEmpty
          ? '$total students enrolled'
          : '$shown of $total results',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF7A8AAD),
      ),
    );
  }

  // ── Student card ───────────────────────────────────────────────────────────
  Widget _buildStudentCard(StudentModel student, int index) {
    // cycle through accent colours for avatars
    final avatarColors = [
      [Color(0xFF4F8EF7), Color(0xFF2563EB)],
      [Color(0xFF34D399), Color(0xFF059669)],
      [Color(0xFFFBBF24), Color(0xFFD97706)],
      [Color(0xFFF472B6), Color(0xFFDB2777)],
      [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    ];
    final grad = avatarColors[index % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {}, // navigate to details
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [

              // avatar
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: grad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: grad[1].withAlpha((255 * 0.30).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: student.profile.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(student.profile,
                      fit: BoxFit.cover),
                )
                    : Center(
                  child: Text(
                    _initials(student.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID: ${student.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _badge(student.academic.branch, grad[0]),
                        const SizedBox(width: 6),
                        _badge(
                            'Sem ${student.academic.semester}',
                            const Color(0xFFD97706)),
                        if (student.academic.rollNo != 0) ...[
                          const SizedBox(width: 6),
                          _badge(
                              'Roll ${student.academic.rollNo}',
                              const Color(0xFF7C3AED)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // chevron
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: _accent, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(64)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Empty / error state ────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4FCE), Color(0xFF4F8EF7)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _blue.withAlpha(102),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddStudentPage()),
          );
          _refresh();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.person_add_rounded,
            color: Colors.white, size: 20),
        label: const Text(
          'Add Student',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}