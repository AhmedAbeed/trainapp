import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class IncidentReportScreen extends StatefulWidget {
  final TrainSchedule? selectedTrain; // ✅ تم الإضافة

  const IncidentReportScreen({super.key, this.selectedTrain}); // ✅ تم الإضافة

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  String? _selectedStation;
  String? _selectedViolation;
  String? _selectedTrainNumber; // ✅ رقم القطار
  final _descriptionCtrl = TextEditingController();
  bool _isLoading = false;

  List<String> _trainNumbers = [];

  // قائمة المخالفات المقترحة
  final List<String> _violationTypes = [
    'السب والشتم',
    'الاعتداء بالضرب',
    'إزعاج الركاب',
    'التدخين في الأماكن الممنوعة',
    'ركوب بدون تذكرة',
    'التعدي على ممتلكات القطار',
    'حيازة أسلحة أو مواد خطرة',
    'مخالفة أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrainNumbers();

    // ✅ إذا كان هناك قطار محدد مسبقاً
    if (widget.selectedTrain != null) {
      _selectedTrainNumber = widget.selectedTrain!.trainNumber;
    }
  }

  void _loadTrainNumbers() {
    final allTrains = SampleData.getAllTrains();
    final seen = <String>{};
    _trainNumbers = allTrains.where((t) {
      if (seen.contains(t.trainNumber)) {
        return false;
      } else {
        seen.add(t.trainNumber);
        return true;
      }
    }).map((t) => t.trainNumber).toList();
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submitReport() {
    // التحقق من صحة البيانات
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTrainNumber == null) {
      _showSnackBar('يرجى اختيار رقم القطار', AppTheme.warningAmber);
      return;
    }
    if (_selectedStation == null) {
      _showSnackBar('يرجى اختيار المحطة', AppTheme.warningAmber);
      return;
    }
    if (_selectedViolation == null) {
      _showSnackBar('يرجى اختيار نوع المخالفة', AppTheme.warningAmber);
      return;
    }

    setState(() => _isLoading = true);

    // إنشاء المحضر بالبيانات اللي دخلها المستخدم
    final report = IncidentReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reportNumber: 'IR-${DateTime.now().millisecondsSinceEpoch}',
      passengerName: _nameCtrl.text.trim(),
      nationalId: _nationalIdCtrl.text.trim(),
      station: _selectedStation!,
      violationType: _selectedViolation!,
      description: _descriptionCtrl.text.trim().isEmpty
          ? _selectedViolation!
          : _descriptionCtrl.text.trim(),
      createdAt: DateTime.now(),
      resolved: false,
      trainNumber: _selectedTrainNumber!, // ✅ تم الإضافة
    );

    // الرجوع بالبيانات إلى الشاشة السابقة
    Navigator.pop(context, report);
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;

    // قائمة المحطات
    final stations = SampleData.stations
        .map((station) => SampleData.getStationName(station, isArabic))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'محضر شغب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          backgroundColor:
          isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
          actions: [
            TextButton.icon(
              onPressed: _isLoading ? null : _submitReport,
              icon: Icon(Icons.save,
                  color: _isLoading
                      ? AppTheme.textSecondary
                      : AppTheme.accentDefault),
              label: Text(
                'حفظ المحضر',
                style: GoogleFonts.cairo(
                  color: _isLoading
                      ? AppTheme.textSecondary
                      : AppTheme.accentDefault,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رقم القطار
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfacePrimary
                        : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accentDefault.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.train, color: AppTheme.accentDefault),
                          const SizedBox(width: 8),
                          Text(
                            'رقم القطار',
                            style: GoogleFonts.cairo(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTrainNumber,
                        decoration: InputDecoration(
                          labelText: 'اختر رقم القطار',
                          prefixIcon: Icon(Icons.train_outlined,
                              color: AppTheme.accentDefault),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        dropdownColor: isDark
                            ? AppTheme.darkSurfaceSecondary
                            : AppTheme.lightSurfaceSecondary,
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        items: _trainNumbers.map((trainNum) {
                          return DropdownMenuItem(
                            value: trainNum,
                            child: Text('قطار رقم $trainNum',
                                style: GoogleFonts.cairo()),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedTrainNumber = value),
                        validator: (v) =>
                        v == null ? 'يرجى اختيار رقم القطار' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // بطاقة معلومات المخالف
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfacePrimary
                        : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accentDefault.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: AppTheme.accentDefault),
                          const SizedBox(width: 8),
                          Text(
                            'بيانات المخالف',
                            style: GoogleFonts.cairo(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم الراكب',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nationalIdCtrl,
                        decoration: InputDecoration(
                          labelText: 'الرقم القومي',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'الرقم القومي مطلوب';
                          if (v.length < 14) {
                            return 'الرقم القومي غير صحيح (14 رقم)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // موقع المخالفة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfacePrimary
                        : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'موقع المخالفة',
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStation,
                        decoration: InputDecoration(
                          labelText: 'اختر المحطة',
                          prefixIcon:
                          Icon(Icons.train, color: AppTheme.accentDefault),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        dropdownColor: isDark
                            ? AppTheme.darkSurfaceSecondary
                            : AppTheme.lightSurfaceSecondary,
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        items: stations.map((station) {
                          return DropdownMenuItem(
                            value: station,
                            child: Text(station, style: GoogleFonts.cairo()),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedStation = value),
                        validator: (v) =>
                        v == null ? 'يرجى اختيار المحطة' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // نوع المخالفة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfacePrimary
                        : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع المخالفة',
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _violationTypes.map((type) {
                          final isSelected = _selectedViolation == type;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedViolation = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.accentDefault
                                    : (isDark
                                    ? AppTheme.darkSurfaceSecondary
                                    : AppTheme.lightSurfaceSecondary),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.accentDefault
                                      : (isDark
                                      ? AppTheme.darkSurfaceTertiary
                                      : AppTheme.lightSurfaceTertiary),
                                ),
                              ),
                              child: Text(
                                type,
                                style: GoogleFonts.cairo(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // وصف المخالفة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfacePrimary
                        : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل إضافية',
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionCtrl,
                        maxLines: 4,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText:
                          'اكتب تفاصيل إضافية عن المخالفة (اختياري)...',
                          hintStyle:
                          GoogleFonts.cairo(color: AppTheme.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: AppTheme.surfaceTertiary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: AppTheme.surfaceTertiary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppTheme.accentDefault, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentDefault,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : Text('حفظ المحضر',
                        style: GoogleFonts.cairo(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}