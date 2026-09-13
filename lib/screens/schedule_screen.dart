import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/course.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedDayFilter = 'All';
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _dayTranslations = {
    'Tümü': 'All',
    'Pazartesi': 'Monday',
    'Salı': 'Tuesday',
    'Çarşamba': 'Wednesday',
    'Perşembe': 'Thursday',
    'Cuma': 'Friday',
    'Cumartesi': 'Saturday',
    'Pazar': 'Sunday',
  };

  String _getTranslatedDay(String day, bool isEn) {
    if (!isEn) return day;
    return _dayTranslations[day] ?? day;
  }

  int? _timeToMinutes(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return (hour * 60) + minute;
  }

  String _calculateDurationText(String startTime, String endTime) {
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);
    if (start == null || end == null || end <= start) return '';

    final duration = end - start;
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (minutes == 0) return '${hours}s';
    if (hours == 0) return '${minutes}dk';
    return '${hours}s ${minutes}dk';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isEn = provider.isEnglish;
    final courses = provider.courses;

    final List<String> days = isEn 
        ? ['All', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        : ['Tümü', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

    return Scaffold(
      backgroundColor: const Color(0xFF131824),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: () => _showAddOrEditCourseDialog(context, isEn: isEn),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: isEn ? 'Search course, instructor or room...' : 'Ders, akademisyen veya sınıf ara...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E2638),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isGridView ? Icons.format_list_bulleted : Icons.grid_on_rounded,
                    color: const Color(0xFF6C5CE7),
                  ),
                  tooltip: _isGridView 
                      ? (isEn ? 'List View' : 'Liste Görünümü') 
                      : (isEn ? 'Grid View' : 'Haftalık Program'),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isSelected = _selectedDayFilter == day || (_selectedDayFilter == 'All' && day == (isEn ? 'All' : 'Tümü'));
                  final count = (day == 'All' || day == 'Tümü')
                      ? courses.length
                      : courses.where((c) => _getTranslatedDay(c.day, isEn) == day || c.day == day).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$day ($count)'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6C5CE7),
                      backgroundColor: const Color(0xFF1E2638),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedDayFilter = day;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isGridView
                  ? _buildTimetableGrid(courses, isEn)
                  : _buildDailyListView(courses, isEn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyListView(List<Course> allCourses, bool isEn) {
    final filteredCourses = _getFilteredCourses(allCourses, isEn);

    if (filteredCourses.isEmpty) {
      return Center(
        child: Text(
          isEn ? 'No registered courses found.' : 'Kayıtlı ders bulunamadı.',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        final course = filteredCourses[index];
        final color = _getCourseColor(course.title);
        final gpa = _calculateCourseAverage(course);

        return Card(
          color: const Color(0xFF1E2638),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (gpa != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isEn ? 'Avg' : 'Ort'}: ${gpa.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${_getTranslatedDay(course.day, isEn)} | ${course.startTime} - ${course.endTime}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                if (course.room.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(course.isOnline ? Icons.video_camera_front_rounded : Icons.location_on_rounded,
                          size: 14, color: course.isOnline ? const Color(0xFF00CEC9) : Colors.grey),
                      const SizedBox(width: 4),
                      Text(course.room, style: TextStyle(color: course.isOnline ? const Color(0xFF00CEC9) : Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF1E2638),
              onSelected: (value) {
                if (value == 'grades') {
                  _showGradeDialog(context, course, isEn: isEn);
                } else if (value == 'edit') {
                  _showAddOrEditCourseDialog(context, course: course, isEn: isEn);
                } else if (value == 'delete') {
                  _confirmDelete(context, course.id, isEn: isEn);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'grades',
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined, color: Color(0xFF00CEC9), size: 18),
                      const SizedBox(width: 8),
                      Text(isEn ? 'Grades' : 'Not Hesapla', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(isEn ? 'Edit' : 'Düzenle', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(isEn ? 'Delete' : 'Sil', style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimetableGrid(List<Course> allCourses, bool isEn) {
    final filteredCourses = _getFilteredCourses(allCourses, isEn);
    final weekDaysOriginal = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final weekDaysDisplay = isEn
        ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        : weekDaysOriginal;

    final hours = [
      '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', 
      '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00'
    ];

    const double hourColWidth = 55.0;
    const double dayColWidth = 110.0;
    const double hourRowHeight = 50.0;
    final double totalTableWidth = hourColWidth + (dayColWidth * weekDaysOriginal.length) + 24.0;

    return Card(
      color: const Color(0xFF1E2638),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: totalTableWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: hourColWidth,
                          child: Text(isEn ? 'Hour' : 'Saat', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        ...weekDaysDisplay.map((d) => SizedBox(
                              width: dayColWidth,
                              child: Center(
                                child: Text(
                                  d,
                                  style: TextStyle(
                                    color: _selectedDayFilter == d ? const Color(0xFF6C5CE7) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    SizedBox(
                      height: hours.length * hourRowHeight,
                      child: Stack(
                        children: [
                          Column(
                            children: hours.map((h) => SizedBox(
                              height: hourRowHeight,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: hourColWidth,
                                    child: Text(h, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ),
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(top: BorderSide(color: Colors.white10, width: 0.8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                          ...filteredCourses.map((course) {
                            final dayIdx = weekDaysOriginal.indexOf(course.day);
                            if (dayIdx == -1) return const SizedBox.shrink();

                            final startMinutes = _timeToMinutes(course.startTime);
                            final endMinutes = _timeToMinutes(course.endTime);
                            if (startMinutes == null ||
                                endMinutes == null ||
                                endMinutes <= startMinutes) {
                              return const SizedBox.shrink();
                            }

                            final topOffset =
                                ((startMinutes - (8 * 60)) / 60.0) * hourRowHeight;
                            final durationInMins = endMinutes - startMinutes;
                            final cardHeight = (durationInMins / 60.0) * hourRowHeight;

                            if (topOffset < 0 || topOffset >= hours.length * hourRowHeight) {
                              return const SizedBox.shrink();
                            }

                            final color = _getCourseColor(course.title);

                            return Positioned(
                              left: hourColWidth + (dayIdx * dayColWidth) + 3,
                              top: topOffset,
                              width: dayColWidth - 6,
                              height: cardHeight > 40 ? cardHeight : 40,
                              child: GestureDetector(
                                onTap: () => _showCourseDetailDialog(context, course, isEn: isEn),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: color, width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        course.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${course.startTime} - ${course.endTime}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 9),
                                      ),
                                      if (course.room.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              course.isOnline ? Icons.video_camera_front_rounded : Icons.location_on_rounded,
                                              size: 9,
                                              color: color,
                                            ),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                course.room,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.grey, fontSize: 9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGradeDialog(BuildContext context, Course course, {required bool isEn}) {
    final editableItems = course.gradeItems
        .map(
          (item) => GradeItem(
            name: item.name,
            weight: item.weight,
            score: item.score,
          ),
        )
        .toList();
    final weightControllers = editableItems
        .map((item) => TextEditingController(text: item.weight.toString()))
        .toList();
    final scoreControllers = editableItems
        .map(
          (item) => TextEditingController(
            text: item.score?.toString() ?? '',
          ),
        )
        .toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final average = _calculateGradeAverage(editableItems);

          return AlertDialog(
            backgroundColor: const Color(0xFF1E2638),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${course.title} - ${isEn ? 'Grades' : 'Notlar'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (average != null)
                  Text(
                    '${isEn ? 'Avg' : 'Ort'}: ${average.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Color(0xFF00CEC9),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: editableItems.length,
                itemBuilder: (context, index) {
                  final item = editableItems[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: weightControllers[index],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: isEn ? 'Weight %' : 'Ağırlık %',
                              labelStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null && parsed >= 0) {
                                item.weight = parsed;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: scoreControllers[index],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: isEn ? 'Score' : 'Not (0-100)',
                              labelStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              item.score = parsed?.clamp(0, 100).toDouble();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  editableItems.add(
                    GradeItem(
                      name: isEn ? 'Quiz / Assignment' : 'Quiz / Ödev',
                      weight: 10,
                    ),
                  );
                  weightControllers.add(TextEditingController(text: '10.0'));
                  scoreControllers.add(TextEditingController());
                  setState(() {});
                },
                child: Text(
                  isEn ? '+ Add Grade Item' : '+ Not Kalemi Ekle',
                  style: const TextStyle(color: Color(0xFF6C5CE7)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                ),
                onPressed: () async {
                  course.gradeItems = editableItems;
                  await Provider.of<AppProvider>(
                    dialogContext,
                    listen: false,
                  ).updateCourse(course);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  isEn ? 'Save' : 'Kaydet',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      for (final controller in weightControllers) {
        controller.dispose();
      }
      for (final controller in scoreControllers) {
        controller.dispose();
      }
    });
  }

  double? _calculateGradeAverage(List<GradeItem> items) {
    double totalWeightedScore = 0.0;
    double totalWeight = 0.0;
    for (final item in items) {
      if (item.score != null && item.weight > 0) {
        totalWeightedScore += item.score! * item.weight;
        totalWeight += item.weight;
      }
    }
    if (totalWeight == 0) return null;
    return totalWeightedScore / totalWeight;
  }

  double? _calculateCourseAverage(Course course) {
    return _calculateGradeAverage(course.gradeItems);
  }

  void _showCourseDetailDialog(BuildContext context, Course course, {required bool isEn}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(course.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${isEn ? 'Day & Time' : 'Gün & Saat'}: ${_getTranslatedDay(course.day, isEn)} | ${course.startTime} - ${course.endTime}', style: const TextStyle(color: Colors.white70)),
            Text('${isEn ? 'Room' : 'Sınıf / Ortam'}: ${course.room}', style: const TextStyle(color: Colors.white70)),
            Text('${isEn ? 'Instructor' : 'Akademisyen'}: ${course.instructor} (${course.instructorEmail})', style: const TextStyle(color: Colors.white70)),
            Text('AKTS: ${course.akts}', style: const TextStyle(color: Colors.white70)),
            const Divider(color: Colors.white24, height: 16),
            if (course.classLink.isNotEmpty)
              Text('${isEn ? 'Online Link' : 'Canlı Ders Linki'}: ${course.classLink}', style: const TextStyle(color: Color(0xFF00CEC9))),
            if (course.driveLink.isNotEmpty)
              Text('${isEn ? 'Drive Material' : 'Drive / Materyal'}: ${course.driveLink}', style: const TextStyle(color: Color(0xFF4A90E2))),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calculate_outlined, color: Color(0xFF00CEC9)),
            label: Text(isEn ? 'Grades' : 'Notlar', style: const TextStyle(color: Color(0xFF00CEC9))),
            onPressed: () {
              Navigator.pop(ctx);
              _showGradeDialog(context, course, isEn: isEn);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit, color: Color(0xFF6C5CE7)),
            label: Text(isEn ? 'Edit' : 'Düzenle', style: const TextStyle(color: Color(0xFF6C5CE7))),
            onPressed: () {
              Navigator.pop(ctx);
              _showAddOrEditCourseDialog(context, course: course, isEn: isEn);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            label: Text(isEn ? 'Delete' : 'Sil', style: const TextStyle(color: Colors.redAccent)),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(context, course.id, isEn: isEn);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String courseId, {required bool isEn}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEn ? 'Delete Course?' : 'Ders Silinsin mi?', style: const TextStyle(color: Colors.white)),
        content: Text(isEn ? 'Are you sure you want to delete this course?' : 'Bu dersi programınızdan silmek istediğinize emin misiniz?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'İptal', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).removeCourse(courseId);
              Navigator.pop(ctx);
            },
            child: Text(isEn ? 'Delete' : 'Sil', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditCourseDialog(
    BuildContext context, {
    Course? course,
    required bool isEn,
  }) {
    final isEditing = course != null;
    final titleController = TextEditingController(
      text: isEditing ? course.title : '',
    );
    final roomController = TextEditingController(
      text: isEditing ? course.room : '',
    );
    final instructorController = TextEditingController(
      text: isEditing ? course.instructor : '',
    );
    final emailController = TextEditingController(
      text: isEditing ? course.instructorEmail : '',
    );
    final classLinkController = TextEditingController(
      text: isEditing ? course.classLink : '',
    );
    final driveLinkController = TextEditingController(
      text: isEditing ? course.driveLink : '',
    );
    final aktsController = TextEditingController(
      text: isEditing ? course.akts.toString() : '4',
    );
    final startTimeController = TextEditingController(
      text: isEditing ? course.startTime : '09:00',
    );
    final endTimeController = TextEditingController(
      text: isEditing ? course.endTime : '11:50',
    );

    String selectedDay = isEditing ? course.day : 'Pazartesi';
    bool isOnline = isEditing ? course.isOnline : false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEditing
                ? (isEn ? 'Edit Course' : 'Dersi Düzenle')
                : (isEn ? 'Add New Course' : 'Yeni Ders Ekle'),
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: isEn ? 'Course Title' : 'Ders Adı',
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                TextField(
                  controller: roomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: isEn ? 'Room / Classroom' : 'Sınıf / Derslik',
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                TextField(
                  controller: instructorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: isEn ? 'Instructor' : 'Akademisyen',
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: isEn ? 'Instructor Email' : 'Akademisyen E-posta',
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isEn ? 'Online Course' : 'Online Ders',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: isOnline,
                  activeColor: const Color(0xFF6C5CE7),
                  onChanged: (val) {
                    setState(() => isOnline = val ?? false);
                  },
                ),
                if (isOnline)
                  TextField(
                    controller: classLinkController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: isEn
                          ? 'Online Course Link'
                          : 'Online Ders Linki (Teams/Zoom)',
                      labelStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                TextField(
                  controller: driveLinkController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: isEn
                        ? 'Drive / Material Link'
                        : 'Drive / Materyal Linki',
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                TextField(
                  controller: aktsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'AKTS',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedDay,
                  dropdownColor: const Color(0xFF1E2638),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    'Pazartesi',
                    'Salı',
                    'Çarşamba',
                    'Perşembe',
                    'Cuma',
                    'Cumartesi',
                    'Pazar',
                  ]
                      .map(
                        (day) => DropdownMenuItem(
                          value: day,
                          child: Text(_getTranslatedDay(day, isEn)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedDay = val);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        keyboardType: TextInputType.datetime,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: isEn
                              ? 'Start (HH:mm)'
                              : 'Başlangıç (HH:mm)',
                          labelStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        keyboardType: TextInputType.datetime,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: isEn ? 'End (HH:mm)' : 'Bitiş (HH:mm)',
                          labelStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isEn ? 'Cancel' : 'İptal',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                final startTime = startTimeController.text.trim();
                final endTime = endTimeController.text.trim();
                final startMinutes = _timeToMinutes(startTime);
                final endMinutes = _timeToMinutes(endTime);

                if (title.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEn
                            ? 'Course title cannot be empty.'
                            : 'Ders adı boş bırakılamaz.',
                      ),
                    ),
                  );
                  return;
                }

                if (startMinutes == null ||
                    endMinutes == null ||
                    endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEn
                            ? 'Enter a valid time range in HH:mm format.'
                            : 'Saatleri HH:mm formatında ve geçerli bir aralık olarak girin.',
                      ),
                    ),
                  );
                  return;
                }

                final newCourse = Course(
                  id: isEditing
                      ? course.id
                      : DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  instructor: instructorController.text.trim(),
                  instructorEmail: emailController.text.trim(),
                  room: roomController.text.trim(),
                  day: selectedDay,
                  startTime: startTime,
                  endTime: endTime,
                  duration: _calculateDurationText(startTime, endTime),
                  isOnline: isOnline,
                  classLink: classLinkController.text.trim(),
                  driveLink: driveLinkController.text.trim(),
                  akts: int.tryParse(aktsController.text.trim()) ?? 4,
                  gradeItems: isEditing ? course.gradeItems : null,
                );

                final provider = Provider.of<AppProvider>(
                  dialogContext,
                  listen: false,
                );
                if (isEditing) {
                  await provider.updateCourse(newCourse);
                } else {
                  await provider.addCourse(newCourse);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(
                isEditing
                    ? (isEn ? 'Save' : 'Kaydet')
                    : (isEn ? 'Add' : 'Ekle'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      titleController.dispose();
      roomController.dispose();
      instructorController.dispose();
      emailController.dispose();
      classLinkController.dispose();
      driveLinkController.dispose();
      aktsController.dispose();
      startTimeController.dispose();
      endTimeController.dispose();
    });
  }

  List<Course> _getFilteredCourses(List<Course> allCourses, bool isEn) {
    return allCourses.where((c) {
      final translatedDay = _getTranslatedDay(c.day, isEn);
      final matchesDay = _selectedDayFilter == 'All' || 
          _selectedDayFilter == 'Tümü' || 
          c.day == _selectedDayFilter || 
          translatedDay == _selectedDayFilter;
          
      final query = _searchController.text.toLowerCase();
      final matchesSearch = c.title.toLowerCase().contains(query) ||
          c.instructor.toLowerCase().contains(query) ||
          c.room.toLowerCase().contains(query);
      return matchesDay && matchesSearch;
    }).toList();
  }

  Color _getCourseColor(String title) {
    if (title.contains('EEE')) return const Color(0xFF4A90E2);
    if (title.contains('BIL321')) return const Color(0xFF00CEC9);
    if (title.contains('BIL317')) return const Color(0xFFF39C12);
    if (title.contains('BIL453')) return const Color(0xFF9B59B6);
    if (title.contains('BIL451')) return const Color(0xFFE84393);
    if (title.contains('BIL353')) return const Color(0xFF6C5CE7);
    if (title.contains('GNL')) return const Color(0xFFE67E22);
    return const Color(0xFF00B894);
  }
}