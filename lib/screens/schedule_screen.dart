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
  String selectedDay = 'Tümü';
  String searchQuery = '';
  bool isTableView = true;

  final List<String> days = [
    'Tümü',
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];
  final List<String> alldays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];
  // Saat aralıkları (09:00 - 21:00)
  final double slotHeight = 55.0; // Her 1 saatlik dilimin yüksekliği
  final int startHour = 9;
  final int endHour = 21;

  Color _getDayColor(String day) {
    switch (day) {
      case 'Pazartesi':
        return const Color(0xFF4A90E2);
      case 'Salı':
        return const Color(0xFF9013FE);
      case 'Çarşamba':
        return const Color(0xFF50E3C2);
      case 'Perşembe':
        return const Color(0xFFF5A623);
      case 'Cuma':
        return const Color(0xFFE91E63);
      case 'Cumartesi':
        return const Color.fromARGB(255, 57, 73, 162);
      case 'Pazar':
        return const Color.fromARGB(255, 133, 55, 81);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    List<Course> filteredCourses = provider.courses.where((course) {
      bool matchesDay = selectedDay == 'Tümü' || course.day == selectedDay;
      bool matchesSearch = course.title
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          course.instructor.toLowerCase().contains(searchQuery.toLowerCase()) ||
          course.room.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesDay && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF141923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2638),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Haftalık Program',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white)),
            Text('${provider.courses.length} ders kayıtlı',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
                isTableView ? Icons.view_list_rounded : Icons.grid_on_rounded,
                color: isTableView ? const Color(0xFF6C5CE7) : Colors.white),
            tooltip: isTableView ? 'Liste Görünümü' : 'Haftalık Tablo Görünümü',
            onPressed: () => setState(() => isTableView = !isTableView),
          ),
          // Yenile Butonunun Yeni Hali:
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Verileri Yenile',
            onPressed: () => provider
                .fetchCourses(), // Sabit dersleri yüklemek yerine veritabanını günceller
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => provider.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Arama Kutusu
            TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Ders, akademisyen veya sınıf ara...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E2638),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Gün Filtreleri
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  int count = day == 'Tümü'
                      ? provider.courses.length
                      : provider.courses.where((c) => c.day == day).length;
                  bool isSelected = selectedDay == day;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text('$day ($count)'),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      selectedColor: const Color(0xFF6C5CE7),
                      backgroundColor: const Color(0xFF1E2638),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onSelected: (selected) {
                        if (selected) setState(() => selectedDay = day);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Ana İçerik
            Expanded(
              child: isTableView
                  ? _buildContinuousTimetable(filteredCourses)
                  : _buildListView(filteredCourses, provider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: () => _showCourseFormDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // BÖLÜNMEYEN TEK PARÇA HAFTALIK TABLO GÖRÜNÜMÜ
  Widget _buildContinuousTimetable(List<Course> courses) {
    final activeDays = selectedDay == 'Tümü' ? alldays : [selectedDay];
    final hours = List.generate(endHour - startHour, (i) => startHour + i);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2638),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Sütun Başlıkları
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF252E42),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const SizedBox(
                    width: 55,
                    child: Center(
                        child: Text('Saat',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)))),
                ...activeDays.map((day) => Expanded(
                      child: Center(
                        child: Text(day,
                            style: TextStyle(
                                color: _getDayColor(day),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // Çizelge Alanı
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol Saat Çizgisi
                  SizedBox(
                    width: 55,
                    child: Column(
                      children: hours.map((hour) {
                        return Container(
                          height: slotHeight,
                          alignment: Alignment.topCenter,
                          padding: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.white10, width: 0.5)),
                          ),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Gün Sütunları ve Çakışmasız Blok Ders Kartları
                  ...activeDays.map((day) {
                    final dayCourses =
                        courses.where((c) => c.day == day).toList();

                    return Expanded(
                      child: Stack(
                        children: [
                          // Arka Plan Çizgileri
                          Column(
                            children: hours.map((_) {
                              return Container(
                                height: slotHeight,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                        color: Colors.white10, width: 0.5),
                                    bottom: BorderSide(
                                        color: Colors.white10, width: 0.5),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          // Tek Parça Ders Blokları
                          ...dayCourses.map((course) {
                            int startH =
                                int.parse(course.startTime.split(':')[0]);
                            int startM =
                                int.parse(course.startTime.split(':')[1]);
                            int endH = int.parse(course.endTime.split(':')[0]);
                            int endM = int.parse(course.endTime.split(':')[1]);

                            double topOffset =
                                ((startH - startHour) + (startM / 60.0)) *
                                    slotHeight;
                            double durationInHours = (endH + (endM / 60.0)) -
                                (startH + (startM / 60.0));
                            double blockHeight = durationInHours * slotHeight;

                            final dayColor = _getDayColor(course.day);

                            return Positioned(
                              top: topOffset + 2,
                              left: 2,
                              right: 2,
                              height: blockHeight - 4,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: dayColor.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: dayColor, width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${course.startTime} - ${course.endTime}',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Icon(
                                            course.isOnline
                                                ? Icons.videocam
                                                : Icons.location_on,
                                            size: 10,
                                            color: dayColor),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            course.room,
                                            style: TextStyle(
                                                color: dayColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // KART/LİSTE GÖRÜNÜMÜ
  Widget _buildListView(List<Course> courses, AppProvider provider) {
    if (courses.isEmpty) {
      return const Center(
          child: Text('Gösterilecek ders bulunamadı.',
              style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final dayColor = _getDayColor(course.day);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2638),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: InkWell(
            onTap: () =>
                _showCourseDetailDialog(context, course), // DERS DETAYINI AÇAR
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                        color: dayColor,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14))),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(course.title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                      overflow: TextOverflow.ellipsis)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: dayColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(course.day,
                                    style: TextStyle(
                                        color: dayColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${course.startTime} - ${course.endTime}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                              const SizedBox(width: 16),
                              Icon(
                                  course.isOnline
                                      ? Icons.videocam_rounded
                                      : Icons.location_on_rounded,
                                  size: 14,
                                  color: course.isOnline
                                      ? Colors.orangeAccent
                                      : Colors.tealAccent),
                              const SizedBox(width: 4),
                              Text(course.room,
                                  style: TextStyle(
                                      color: course.isOnline
                                          ? Colors.orangeAccent
                                          : Colors.tealAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(course.instructor,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              Row(
                                children: [
                                  // DÜZENLEME BUTONU
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: Colors.amberAccent),
                                    onPressed: () => _showCourseFormDialog(
                                        context,
                                        course: course),
                                  ),
                                  // SİLME BUTONU
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.redAccent),
                                    onPressed: () =>
                                        provider.removeCourse(course.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCourseDetailDialog(BuildContext context, Course course) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final classLinkController = TextEditingController(text: course.classLink);
    final driveLinkController = TextEditingController(text: course.driveLink);

    List<GradeItem> currentItems = course.gradeItems
        .map((e) => GradeItem(name: e.name, weight: e.weight, score: e.score))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          double totalWeight = 0;
          double weightedScoreSum = 0;

          for (var item in currentItems) {
            totalWeight += item.weight;
            if (item.score != null) {
              weightedScoreSum += (item.score! * (item.weight / 100.0));
            }
          }

          String calculateLetter(double score) {
            if (score >= 90) return 'AA';
            if (score >= 85) return 'BA';
            if (score >= 80) return 'BB';
            if (score >= 75) return 'CB';
            if (score >= 70) return 'CC';
            if (score >= 60) return 'DC';
            if (score >= 50) return 'DD';
            return 'FF';
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E2638),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.amberAccent),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCourseFormDialog(context, course: course);
                  },
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${course.day} ${course.startTime} - ${course.endTime} | ${course.room}',
                      style: const TextStyle(color: Colors.grey)),
                  Text('Akademisyen: ${course.instructor}',
                      style: const TextStyle(color: Colors.grey)),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📊 Not & Etki Oranları',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline,
                            size: 16, color: Color(0xFF6C5CE7)),
                        label: const Text('Kriter Ekle',
                            style: TextStyle(
                                color: Color(0xFF6C5CE7), fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            currentItems
                                .add(GradeItem(name: 'Quiz', weight: 10));
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...currentItems.asMap().entries.map((entry) {
                    int idx = entry.key;
                    GradeItem item = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: item.name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                  hintText: 'Başlık', isDense: true),
                              onChanged: (val) => item.name = val,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.weight.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                  hintText: '%',
                                  suffixText: '%',
                                  isDense: true),
                              onChanged: (val) {
                                setState(() {
                                  item.weight = double.tryParse(val) ?? 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.score?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                  hintText: 'Not', isDense: true),
                              onChanged: (val) {
                                setState(() {
                                  item.score = double.tryParse(val);
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent, size: 18),
                            onPressed: () {
                              setState(() {
                                currentItems.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: totalWeight == 100
                            ? Colors.transparent
                            : Colors.orangeAccent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tahmini Ortalama:',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            Text(
                              '${weightedScoreSum.toStringAsFixed(1)} / 100',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Harf Notu:',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            Text(
                              calculateLetter(weightedScoreSum),
                              style: const TextStyle(
                                  color: Color(0xFF6C5CE7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                        if (totalWeight != 100) ...[
                          const SizedBox(height: 4),
                          Text(
                            '⚠️ Toplam etki yüzdesi %${totalWeight.toStringAsFixed(0)} (100 olmalı)',
                            style: const TextStyle(
                                color: Colors.orangeAccent, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  const Text('🔗 Ders Bağlantıları & Materyal',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: classLinkController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Online Ders Linki (Zoom/Teams)',
                        labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: driveLinkController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Ders Materyali / Drive Linki',
                        labelStyle: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal',
                      style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7)),
                onPressed: () {
                  final updatedCourse = Course(
                    id: course.id,
                    title: course.title,
                    instructor: course.instructor,
                    instructorEmail: course.instructorEmail,
                    room: course.room,
                    day: course.day,
                    startTime: course.startTime,
                    endTime: course.endTime,
                    duration: course.duration,
                    isOnline: course.isOnline,
                    akts: course.akts,
                    classLink: classLinkController.text,
                    driveLink: driveLinkController.text,
                    gradeItems: currentItems,
                  );
                  provider.updateCourse(updatedCourse);
                  Navigator.pop(ctx);
                },
                child:
                    const Text('Kaydet', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCourseFormDialog(BuildContext context, {Course? course}) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isEditing = course != null;

    final titleController = TextEditingController(text: course?.title ?? '');
    final instructorController =
        TextEditingController(text: course?.instructor ?? '');
    final roomController = TextEditingController(text: course?.room ?? '');
    final startTimeController =
        TextEditingController(text: course?.startTime ?? '09:00');
    final endTimeController =
        TextEditingController(text: course?.endTime ?? '11:50');

    String selectedDay = course?.day ?? 'Pazartesi';
    bool isOnline = course?.isOnline ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          title: Text(isEditing ? 'Dersi Düzenle' : 'Yeni Ders Ekle',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Ders Adı',
                      labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: instructorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Akademisyen Adı',
                      labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: roomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Derslik / Sınıf',
                      labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  dropdownColor: const Color(0xFF1E2638),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Gün',
                      labelStyle: TextStyle(color: Colors.grey)),
                  items: alldays
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedDay = val);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Başlangıç (09:00)',
                            labelStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Bitiş (11:50)',
                            labelStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Online Ders mi?',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: isOnline,
                  activeColor: const Color(0xFF6C5CE7),
                  onChanged: (val) => setState(() => isOnline = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    const Text('İptal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7)),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newCourse = Course(
                    id: isEditing ? course.id : '',
                    title: titleController.text,
                    instructor: instructorController.text,
                    room: roomController.text,
                    day: selectedDay,
                    startTime: startTimeController.text,
                    endTime: endTimeController.text,
                    duration: '2s 50dk',
                    isOnline: isOnline,
                  );

                  if (isEditing) {
                    provider.updateCourse(newCourse);
                  } else {
                    provider.addCourse(newCourse);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEditing ? 'Güncelle' : 'Ekle',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
