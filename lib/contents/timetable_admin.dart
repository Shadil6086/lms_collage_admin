import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TimetableAdminPage extends StatefulWidget {
  const TimetableAdminPage({super.key});

  @override
  State<TimetableAdminPage> createState() => _TimetableAdminPageState();
}

class _TimetableAdminPageState extends State<TimetableAdminPage> with SingleTickerProviderStateMixin {
  String _collegeId = '';
  
  // Selection controllers
  String? _semester;
  String? _selectedBranch;
  List<String> _availableBranches = [];
  final TextEditingController _classController = TextEditingController();

  bool _isLoading = false;
  bool _isFetched = false;
  
  // Local active class timetable data representation
  // Structure: { 'Monday': { 'Period1': { subject, faculty, location, time: {from, to} } }, 'Tuesday': ... }
  Map<String, dynamic> _localClassData = {};
  
  late TabController _tabController;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    _loadCollegeId();
  }

  Future<void> _loadCollegeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _collegeId = prefs.getString("collegeCode") ?? "";
    });
  }

  Future<void> _fetchBranchesForSemester(String sem) async {
    setState(() {
       _semester = sem;
       _selectedBranch = null;
       _availableBranches = [];
    });
    
    try {
      final docSnap = await FirebaseFirestore.instance.collection(_collegeId).doc('S$sem').get();
      if (docSnap.exists) {
         final data = docSnap.data();
         if (data != null && data.containsKey('departments')) {
            setState(() {
               _availableBranches = List<String>.from(data['departments']);
            });
         }
      }
    } catch (e) {
      // Ignore if document not properly configured yet
    }
  }

  DocumentReference get _docRef {
    return FirebaseFirestore.instance
        .collection(_collegeId)
        .doc('S$_semester')
        .collection(_selectedBranch ?? '')
        .doc('TimeTable');
  }

  Future<void> _fetchTimetable() async {
    if (_semester == null || _selectedBranch == null || _classController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Semester, Branch, and Class')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isFetched = false;
      _localClassData = {};
    });

    try {
      final snapshot = await _docRef.get();
      
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        final className = _classController.text.trim();
        
        if (data.containsKey(className)) {
           // We found existing data for this class
           _localClassData = Map<String, dynamic>.from(data[className] as Map);
        }
      }
      
      setState(() {
        _isFetched = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching timetable: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pushToServer() async {
    setState(() => _isLoading = true);
    try {
       // We push the entire updated local class map back. Using merge:true guarantees
       // we ONLY overwrite this specific class's schedule in the TimeTable document.
       await _docRef.set({
          _classController.text.trim() : _localClassData
       }, SetOptions(merge: true));

       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Timetable updated successfully!'), backgroundColor: Colors.green),
       );
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error saving: $e')),
       );
    } finally {
       setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePeriod(String day, String periodKey) async {
    bool confirm = await showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
          title: const Text('Delete Period?'),
          content: const Text('Are you sure you want to remove this period?'),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
               onPressed: ()=>Navigator.pop(ctx, true), 
               child: const Text('Delete', style: TextStyle(color: Colors.red))
            ),
          ],
       )
    ) ?? false;

    if (!confirm) return;

    setState(() {
       final dayMap = _localClassData[day] as Map;
       dayMap.remove(periodKey);
       // Clean up empty days
       if (dayMap.isEmpty) _localClassData.remove(day);
    });

    // Pushing the map without the period acts as a deletion since we overwrite the class property entirely
    // Wait, if we use merge: true, missing keys in our map WON'T delete existing keys in Firestore. 
    // To truly delete via merge, we must explicitly delete the Field, or we can use set WITHOUT merge for the whole doc? 
    // No! If we set without merge, we destroy other classes!
    // Correct approach to delete a nested field: update({ "CS2.Monday.Period1": FieldValue.delete() })
    
    setState(() => _isLoading = true);
    try {
       final path = '${_classController.text.trim()}.$day.$periodKey';
       await _docRef.update({ path : FieldValue.delete() });
       
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Period deleted'), backgroundColor: Colors.orange),
       );
    } catch(e) {
       // If doc doesn't exist or field doesn't exist, it's fine.
    } finally {
       setState(() => _isLoading = false);
    }
  }

  void _showPeriodDialog(String day, {String? existingPeriodKey, Map? existingData}) {
    final titleCtrl = TextEditingController(text: existingData?['subject'] ?? '');
    final teacherCtrl = TextEditingController(text: existingData?['faculty'] ?? '');
    final roomCtrl = TextEditingController(text: existingData?['location'] ?? '');
    
    // Parse time if edits
    TimeOfDay? startT;
    TimeOfDay? endT;
    if (existingData != null && existingData['time'] != null) {
       final format = DateFormat("h:mm a");
       try {
         final f = format.parse(existingData['time']['from']);
         final t = format.parse(existingData['time']['to']);
         startT = TimeOfDay(hour: f.hour, minute: f.minute);
         endT = TimeOfDay(hour: t.hour, minute: t.minute);
       } catch(_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          Future<void> pickTime(bool isStart) async {
             final t = await showTimePicker(context: context, initialTime: isStart ? (startT ?? TimeOfDay.now()) : (endT ?? TimeOfDay.now()));
             if (t != null) {
                setDialogState((){
                   if (isStart) startT = t; else endT = t;
                });
             }
          }

          String formatTime(TimeOfDay? time) {
             if (time == null) return "Select Time";
             final now = DateTime.now();
             final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
             return DateFormat("h:mm a").format(dt);
          }

          return AlertDialog(
            title: Text(existingPeriodKey == null ? 'Add Period to $day' : 'Edit Period'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Subject Name')),
                  TextField(controller: teacherCtrl, decoration: const InputDecoration(labelText: 'Faculty Name')),
                  TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room/Location')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Start:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton(
                         onPressed: () => pickTime(true), 
                         child: Text(formatTime(startT))
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('End:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton(
                         onPressed: () => pickTime(false), 
                         child: Text(formatTime(endT))
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                   if (titleCtrl.text.isEmpty || startT == null || endT == null) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject and Times are required')));
                     return;
                   }
                   
                   // Generate new Period Key if adding new
                   final pKey = existingPeriodKey ?? 'Period_${DateTime.now().millisecondsSinceEpoch}';
                   
                   final newPeriodData = {
                      'subject': titleCtrl.text.trim(),
                      'faculty': teacherCtrl.text.trim(),
                      'location': roomCtrl.text.trim(),
                      'time': {
                         'from': formatTime(startT),
                         'to': formatTime(endT)
                      }
                   };

                   setState(() {
                      if (!_localClassData.containsKey(day)) {
                         _localClassData[day] = {};
                      }
                      (_localClassData[day] as Map)[pKey] = newPeriodData;
                   });

                   Navigator.pop(context);
                   _pushToServer();
                }, 
                child: const Text('Save')
              )
            ],
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Timetable Management', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Premium Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2557), Color(0xFF1A4FCE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class Schedules', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Manage and assign weekly periods per branch and department.', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // 1. Target Selector Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Schedule Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: const Text('Sem'),
                            value: _semester,
                            items: List.generate(8, (index) => 'S${index+1}').map((s) => DropdownMenuItem(value: s.replaceAll('S', ''), child: Text(s))).toList(),
                            onChanged: (val) {
                               if (val != null) _fetchBranchesForSemester(val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: const Text('Branch'),
                            value: _selectedBranch,
                            isExpanded: true,
                            items: _availableBranches.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedBranch = val),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: TextField(
                          controller: _classController,
                          decoration: const InputDecoration(hintText: 'Class (CS2)', border: InputBorder.none),
                          onSubmitted: (_) => _fetchTimetable(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
                      ),
                      onPressed: _fetchTimetable, 
                      child: const Icon(Icons.search, color: Colors.white)
                    )
                  ],
                ),
              ],
            ),
          ),
          
          if (_isLoading)
             const LinearProgressIndicator(color: Color(0xFF3B82F6), backgroundColor: Color(0xFFDBEAFE)),

          // 2. Tabbed Weekly Schedule
          if (_isFetched && !_isLoading) ...[
             const SizedBox(height: 16),
             Container(
               color: Colors.white,
               child: TabBar(
                 controller: _tabController,
                 isScrollable: true,
                 labelColor: const Color(0xFF3B82F6),
                 unselectedLabelColor: const Color(0xFF64748B),
                 indicatorColor: const Color(0xFF3B82F6),
                 indicatorWeight: 3,
                 labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                 tabs: _days.map((day) => Tab(text: day)).toList(),
               ),
             ),
             Expanded(
               child: TabBarView(
                 controller: _tabController,
                 children: _days.map((day) {
                    
                    final dayData = _localClassData[day] as Map?;
                    final periods = dayData?.entries.toList() ?? [];
                    
                    // Simple chronological sort based on the 'from' time.
                    periods.sort((a, b) {
                        try {
                           final format = DateFormat("h:mm a");
                           final timeA = format.parse(a.value['time']['from']);
                           final timeB = format.parse(b.value['time']['from']);
                           return timeA.compareTo(timeB);
                        } catch(e) {
                           return 0;
                        }
                    });

                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                           Align(
                             alignment: Alignment.centerLeft,
                             child: ElevatedButton.icon(
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFFEFF6FF),
                                 foregroundColor: const Color(0xFF3B82F6),
                                 elevation: 0,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                               ),
                               onPressed: () => _showPeriodDialog(day), 
                               icon: const Icon(Icons.add_circle_outline), 
                               label: const Text('Add Period', style: TextStyle(fontWeight: FontWeight.bold))
                             ),
                           ),
                           const SizedBox(height: 24),
                           
                           if (periods.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.event_busy, size: 64, color: Colors.grey.withOpacity(0.3)),
                                      const SizedBox(height: 16),
                                      const Text('No classes scheduled', style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500)),
                                    ],
                                  )
                                )
                              ),
                              
                           if (periods.isNotEmpty)
                           Expanded(
                             child: ListView.builder(
                               itemCount: periods.length,
                               itemBuilder: (ctx, idx) {
                                  final pKey = periods[idx].key;
                                  final pData = periods[idx].value as Map;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 4))],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 100,
                                            color: const Color(0xFF3B82F6),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Text(pData['time']?['from'] ?? '--', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                                  child: const Text('TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))
                                                ),
                                                const SizedBox(height: 4),
                                                Text(pData['time']?['to'] ?? '--', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                                              ],
                                            ),
                                          ),
                                          Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(pData['subject'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Text('${pData['faculty'] ?? '--'}', style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
                                                    const SizedBox(width: 16),
                                                    const Icon(Icons.room_outlined, size: 16, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Text('${pData['location'] ?? '--'}', style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
                                            onPressed: () => _showPeriodDialog(day, existingPeriodKey: pKey, existingData: pData),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                                            onPressed: () => _deletePeriod(day, pKey),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    ),
                                  );
                               }
                             ),
                           )
                        ],
                      ),
                    );
                 }).toList(),
               ),
             )
          ]
        ],
      ),
    );
  }
}
