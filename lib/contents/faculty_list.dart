import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../strings/colors.dart';
import 'facultyadd.dart';

class FacultyListPage extends StatefulWidget {
  const FacultyListPage({super.key});

  @override
  State<FacultyListPage> createState() => _FacultyListPageState();
}

class _FacultyListPageState extends State<FacultyListPage>
    with SingleTickerProviderStateMixin {
  String? collegeCode;
  bool _isInitialLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Colour tokens ──────────────────────────────────────────────────────────
  static const _navy   = Color(0xFF0F2557);
  static const _blue   = Color(0xFF1A4FCE);
  static const _accent = Color(0xFF4F8EF7);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Color(0xFFFFFFFF);
  static const _textD  = Color(0xFF1E293B);
  static const _textG  = Color(0xFF7A8AAD);

  // Avatar gradient palette
  static const _avatarGrads = [
    [Color(0xFF4F8EF7), Color(0xFF2563EB)],
    [Color(0xFF34D399), Color(0xFF059669)],
    [Color(0xFFFBBF24), Color(0xFFD97706)],
    [Color(0xFFF472B6), Color(0xFFDB2777)],
    [Color(0xFFA78BFA), Color(0xFF7C3AED)],
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadCollege();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCollege() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      collegeCode = prefs.getString("collegeCode");
      _isInitialLoading = false;
    });
    _animController.forward();
  }

  List<QueryDocumentSnapshot> _filtered(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;
    final q = _searchQuery.toLowerCase();
    return docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['name']?.toString().toLowerCase().contains(q) ?? false) ||
          (data['department']?.toString().toLowerCase().contains(q) ?? false) ||
          d.id.toLowerCase().contains(q);
    }).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (collegeCode == null || collegeCode!.isEmpty) {
      return Scaffold(
        backgroundColor: _bg,
        body: _emptyState(
          icon: Icons.error_outline_rounded,
          color: Colors.red,
          title: 'Not Logged In',
          subtitle: 'No college code found. Please log in again.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collegeCode!)
            .doc('users')
            .collection('faculty')
            .snapshots(),
        builder: (context, snapshot) {
          final docs      = snapshot.data?.docs ?? [];
          final filtered  = _filtered(docs);
          final isWaiting = snapshot.connectionState ==
              ConnectionState.waiting && docs.isEmpty;

          return FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [

                // ── Hero AppBar ──────────────────────────────────────
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
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeroHeader(docs.length),
                  ),
                  title: const Text(
                    'Faculty',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  centerTitle: true,
                ),

                // ── Search bar ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: _buildSearchBar(),
                  ),
                ),

                // ── Results label ────────────────────────────────────
                if (docs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                      child: Text(
                        _searchQuery.isEmpty
                            ? '${docs.length} faculty members'
                            : '${filtered.length} of ${docs.length} results',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textG,
                        ),
                      ),
                    ),
                  ),

                // ── Body ─────────────────────────────────────────────
                if (snapshot.hasError)
                  SliverFillRemaining(
                    child: _emptyState(
                      icon: Icons.error_outline_rounded,
                      color: Colors.red,
                      title: 'Something went wrong',
                      subtitle: snapshot.error.toString(),
                    ),
                  )
                else if (isWaiting)
                  const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(color: _accent)),
                  )
                else if (docs.isEmpty)
                    SliverFillRemaining(
                      child: _emptyState(
                        icon: Icons.person_off_rounded,
                        color: _accent,
                        title: 'No Faculty Yet',
                        subtitle: 'Tap + to add your first faculty member',
                      ),
                    )
                  else if (filtered.isEmpty)
                      SliverFillRemaining(
                        child: _emptyState(
                          icon: Icons.search_off_rounded,
                          color: _accent,
                          title: 'No Results',
                          subtitle: 'Try a different search term',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, i) =>
                                _buildFacultyCard(filtered[i], i),
                            childCount: filtered.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Hero header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(int count) {
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
              child: _circle(180, Colors.white.withOpacity(0.05))),
          Positioned(left: -20, bottom: -30,
              child: _circle(130, Colors.white.withOpacity(0.04))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 70, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Faculty Management',
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
                    _statPill(
                        Icons.people_rounded, '$count Total',
                        Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 10),
                    _statPill(Icons.circle, 'Active',
                        Colors.green.withOpacity(0.3),
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
          color: bg, borderRadius: BorderRadius.circular(20)),
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 14, color: _textD),
        decoration: InputDecoration(
          hintText: 'Search by name, department or ID…',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon:
          const Icon(Icons.search_rounded, color: _accent, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Colors.grey),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // ── Faculty card ───────────────────────────────────────────────────────────
  Widget _buildFacultyCard(QueryDocumentSnapshot doc, int index) {
    final data  = doc.data() as Map<String, dynamic>;
    final name  = data['name']?.toString() ?? 'Unknown';
    final dept  = data['department']?.toString() ?? '';
    final role  = data['role']?.toString() ?? 'Faculty';
    final profile = data['profile']?.toString() ?? '';
    final grad  = _avatarGrads[index % _avatarGrads.length];

    String initials(String n) {
      final p = n.trim().split(' ');
      if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
      return n.isNotEmpty ? n[0].toUpperCase() : '?';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {}, // navigate to detail page
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
                      color: grad[1].withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: profile.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(profile, fit: BoxFit.cover),
                )
                    : Center(
                  child: Text(
                    initials(name),
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
                    Text(name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textD,
                          letterSpacing: -0.2,
                        )),
                    const SizedBox(height: 3),
                    Text('ID: ${doc.id}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        if (dept.isNotEmpty) ...[
                          _badge(dept, _blue),
                          const SizedBox(width: 6),
                        ],
                        _badge(role, const Color(0xFF059669)),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ── Empty / error state ────────────────────────────────────────────────────
  Widget _emptyState({
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
                  color: color.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textD)),
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
            color: _blue.withOpacity(0.40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddFacultyPage()),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.person_add_rounded,
            color: Colors.white, size: 20),
        label: const Text(
          'Add Faculty',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
      ),
    );
  }

}