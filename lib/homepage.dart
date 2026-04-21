import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contents/SemesterControlPage.dart';
import 'contents/faculty_list.dart';
import 'contents/students_list.dart';
import 'contents/bus_pass_admin.dart';
import 'contents/fees_admin.dart';
import 'contents/timetable_admin.dart';

class CollegeHomePage extends StatefulWidget {
  final String collegeName;

  const CollegeHomePage({super.key, required this.collegeName});

  @override
  State<CollegeHomePage> createState() => _CollegeHomePageState();
}

class _CollegeHomePageState extends State<CollegeHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collegeCode = prefs.getString("collegeCode");
      if (collegeCode == null || collegeCode.isEmpty) return;

      final studentsSnap = await FirebaseFirestore.instance
          .collection(collegeCode)
          .doc('users')
          .collection('students')
          .get();

      final facultySnap = await FirebaseFirestore.instance
          .collection(collegeCode)
          .doc('users')
          .collection('faculty')
          .get();

      final Set<String> depts = {};
      for (var doc in facultySnap.docs) {
        final data = doc.data();
        if (data.containsKey('department') && data['department'] != null) {
          final dept = data['department'].toString().trim();
          if (dept.isNotEmpty) depts.add(dept);
        }
      }

      if (mounted) {
        setState(() {
          _quickStats = [
            {
              'label': 'Total Students',
              'value': studentsSnap.docs.length.toString(),
              'icon': Icons.people_outline_rounded,
              'color': const Color(0xFF4F46E5),
            },
            {
              'label': 'Active Faculty',
              'value': facultySnap.docs.length.toString(),
              'icon': Icons.badge_outlined,
              'color': const Color(0xFF0D9488),
            },
            {
              'label': 'Departments',
              'value': depts.length.toString(),
              'icon': Icons.domain_outlined,
              'color': const Color(0xFFE11D48),
            },
          ];
        });
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Quick stat items
  List<Map<String, dynamic>> _quickStats = [
    {
      'label': 'Total Students',
      'value': '...',
      'icon': Icons.people_outline_rounded,
      'color': const Color(0xFF4F46E5),
    },
    {
      'label': 'Active Faculty',
      'value': '...',
      'icon': Icons.badge_outlined,
      'color': const Color(0xFF0D9488),
    },
    {
      'label': 'Departments',
      'value': '...',
      'icon': Icons.domain_outlined,
      'color': const Color(0xFFE11D48),
    },
  ];

  // ── Dashboard menu items
  late final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Students',
      'subtitle': 'Manage enrolments and profiles',
      'icon': Icons.school_outlined,
      'color': const Color(0xFF2563EB), // Blue
      'bgColor': const Color(0xFFEFF6FF),
      'page': const StudentsPage(),
    },
    {
      'title': 'Faculty',
      'subtitle': 'Staff and teacher management',
      'icon': Icons.person_outline_rounded,
      'color': const Color(0xFF059669), // Emerald
      'bgColor': const Color(0xFFECFDF5),
      'page': const FacultyListPage(),
    },
    {
      'title': 'Semester',
      'subtitle': 'Course scheduling and control',
      'icon': Icons.menu_book_outlined,
      'color': const Color(0xFFD97706), // Amber
      'bgColor': const Color(0xFFFFFBEB),
      'page': const SemesterControlPage(),
    },
    {
      'title': 'Bus Pass',
      'subtitle': 'Manage student transport passes',
      'icon': Icons.directions_bus_outlined,
      'color': const Color(0xFF7C3AED), // Violet
      'bgColor': const Color(0xFFF5F3FF),
      'page': const BusPassAdminPage(),
    },
    {
      'title': 'Fees Management',
      'subtitle': 'Student payments and bills',
      'icon': Icons.payments_outlined,
      'color': const Color(0xFFDC2626), // Red
      'bgColor': const Color(0xFFFEF2F2),
      'page': const FeesAdminPage(),
    },
    {
      'title': 'Timetable',
      'subtitle': 'Manage class schedules',
      'icon': Icons.calendar_month_outlined,
      'color': const Color(0xFF0D9488), // Teal
      'bgColor': const Color(0xFFF0FDFA),
      'page': const TimetableAdminPage(),
    },
    {
      'title': 'Notices',
      'subtitle': 'Announcements and circulars',
      'icon': Icons.campaign_outlined,
      'color': const Color(0xFFEA580C), // Orange
      'bgColor': const Color(0xFFFFF7ED),
      'page': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Very light slate for premium professional feel
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.collegeName,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Administrator Panel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 16),
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF475569),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person, color: Color(0xFF94A3B8), size: 20),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 32),
                _buildStatsRow(),
                const SizedBox(height: 32),
                const Text(
                  'Quick Modules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                _buildGrid(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Premium Dark
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF10B981,
                  ).withOpacity(0.2), // Light green bg
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'All Systems Operational',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome back, Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here is what’s happening in your institution today.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _quickStats.map((stat) {
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (stat['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          stat['icon'] as IconData,
                          color: stat['color'] as Color,
                          size: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stat['value'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat['label'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 800) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 500) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 154,
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) =>
              _buildMenuCard(_menuItems[index], index),
        );
      },
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> item, int index) {
    final color = item['color'] as Color;
    final bgColor = item['bgColor'] as Color;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final delay = (index * 0.05).clamp(0.0, 0.5);
        final t = ((_animController.value - delay) / (1.0 - delay)).clamp(
          0.0,
          1.0,
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item['page'] != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item['page'] as Widget),
                  );
                }
              : () {},
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Ink(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
