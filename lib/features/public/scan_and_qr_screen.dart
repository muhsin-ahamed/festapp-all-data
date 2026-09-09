import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui_components.dart';
import '../../data/models/program_model.dart';
import '../../data/models/result_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/registration_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/venue_model.dart';
import '../../services/qr_service.dart';

class ScanAndQrScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final String? initialQuery;

  const ScanAndQrScreen({
    super.key,
    this.isEmbedded = false,
    this.initialQuery,
  });

  @override
  ConsumerState<ScanAndQrScreen> createState() => _ScanAndQrScreenState();
}

class _ScanAndQrScreenState extends ConsumerState<ScanAndQrScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCameraActive = true;
  Student? _foundStudent;
  Program? _foundProgram;
  String? _searchErrorMessage;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String rawQuery) async {
    final clean = rawQuery.trim();
    if (clean.isEmpty) return;

    final parsed = QrService.parseQrPayload(clean);
    final query = parsed.value.trim().toLowerCase();

    setState(() {
      _hasSearched = true;
      _searchErrorMessage = null;
      _foundStudent = null;
      _foundProgram = null;
    });

    final students = ref.read(studentsProvider).value ?? [];
    final programs = ref.read(programsProvider).value ?? [];
    final registrations = ref.read(registrationsProvider).value ?? [];

    // 1. Check for Student by Chase Number or ID or Name
    final matchedStudent =
        students.where((s) {
          final sChase = s.chaseNumber.trim().toLowerCase();
          final sId = s.id.trim().toLowerCase();
          final sName = s.name.trim().toLowerCase();
          return sChase == query || sId == query || sName == query;
        }).firstOrNull ??
        students.where((s) {
          final sChase = s.chaseNumber.trim().toLowerCase();
          final sName = s.name.trim().toLowerCase();
          return sChase.contains(query) || sName.contains(query);
        }).firstOrNull;

    if (matchedStudent != null) {
      setState(() {
        _foundStudent = matchedStudent;
        _isCameraActive = false;
      });
      return;
    }

    // 1b. Try remote / repository lookup for student by chase number
    try {
      final repoStudent =
          await ref.read(studentRepositoryProvider).getByChaseNumber(clean);
      if (repoStudent != null && mounted) {
        setState(() {
          _foundStudent = repoStudent;
          _isCameraActive = false;
        });
        return;
      }
    } catch (_) {}

    // 1c. Check if query matches a registration number or student chase in registration
    final matchedReg = registrations.where((r) {
      final regNum = r.registrationNumber.trim().toLowerCase();
      final regStud = r.studentId.trim().toLowerCase();
      if (regStud == query) return true;
      if (regNum == query || regNum.contains(query)) return true;
      if (regNum.startsWith('reg-')) {
        final parts = regNum.split('-');
        if (parts.length >= 2 && parts[1] == query) return true;
      }
      return false;
    }).firstOrNull;

    if (matchedReg != null) {
      final regStudent = students.where((s) {
        final sId = s.id.trim().toLowerCase();
        final sChase = s.chaseNumber.trim().toLowerCase();
        final matchTarget = matchedReg.studentId.trim().toLowerCase();
        return sId == matchTarget || sChase == matchTarget;
      }).firstOrNull;

      if (regStudent != null) {
        setState(() {
          _foundStudent = regStudent;
          _isCameraActive = false;
        });
        return;
      } else {
        // Synthesize student from registration so details still render
        String chase = clean;
        if (matchedReg.registrationNumber.toUpperCase().startsWith('REG-')) {
          final parts = matchedReg.registrationNumber.split('-');
          if (parts.length >= 2) chase = parts[1];
        }
        final fallbackStudent = Student(
          id: matchedReg.studentId.isNotEmpty ? matchedReg.studentId : chase,
          chaseNumber: chase.toUpperCase(),
          name: 'Student ($chase)',
          gender: 'Male',
          dateOfBirth: '',
          section: FestSection.fromString('', chase),
          teamId: matchedReg.teamId,
          phone: '',
          className: '',
          schoolName: '',
          qrCode: chase,
        );
        setState(() {
          _foundStudent = fallbackStudent;
          _isCameraActive = false;
        });
        return;
      }
    }

    // 2. Check for Program if QrType is program or query matches program code/name
    final matchedProgram = programs.where((p) {
      return p.id.toLowerCase() == query ||
          p.programCode.toLowerCase() == query ||
          p.programName.toLowerCase().contains(query);
    }).firstOrNull;

    if (matchedProgram != null) {
      setState(() {
        _foundProgram = matchedProgram;
        _isCameraActive = false;
      });
      return;
    }

    setState(() {
      _searchErrorMessage = 'No student or program found matching "$clean"';
    });
  }

  void _resetSearch() {
    setState(() {
      _searchController.clear();
      _foundStudent = null;
      _foundProgram = null;
      _searchErrorMessage = null;
      _hasSearched = false;
      _isCameraActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer(
      builder: (context, ref, child) {
        final studentsAsync = ref.watch(studentsProvider);
        final teamsAsync = ref.watch(teamsProvider);
        final programsAsync = ref.watch(programsProvider);
        final resultsAsync = ref.watch(publishedResultsProvider);
        final registrationsAsync = ref.watch(registrationsProvider);
        final schedulesAsync = ref.watch(schedulesProvider);
        final venuesAsync = ref.watch(venuesProvider);

        final isLoading =
            studentsAsync.isLoading ||
            teamsAsync.isLoading ||
            programsAsync.isLoading ||
            resultsAsync.isLoading;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = studentsAsync.value ?? [];
        final teams = teamsAsync.value ?? [];
        final programs = programsAsync.value ?? [];
        final results = resultsAsync.value ?? [];
        final registrations = registrationsAsync.value ?? [];
        final schedules = schedulesAsync.value ?? [];
        final venues = venuesAsync.value ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Card exactly matching uploaded design
              _buildSearchCard(),
              const SizedBox(height: 20),

              // Live Camera Scanner Box (if camera active and no result selected)
              if (_isCameraActive &&
                  _foundStudent == null &&
                  _foundProgram == null) ...[
                _buildCameraScannerCard(),
                const SizedBox(height: 24),
              ],

              // Camera Toggle Button if hidden
              if (!_isCameraActive &&
                  _foundStudent == null &&
                  _foundProgram == null) ...[
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      foregroundColor: AppTheme.cream,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      'Turn On Camera Scanner',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isCameraActive = true;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Search Error Message
              if (_searchErrorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _searchErrorMessage!,
                          style: GoogleFonts.workSans(
                            color: AppTheme.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Student Results Card
              if (_foundStudent != null) ...[
                _buildStudentCard(
                  _foundStudent!,
                  teams,
                  programs,
                  results,
                  registrations,
                  schedules,
                  venues,
                ),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.red,
                      side: const BorderSide(color: AppTheme.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(
                      'Scan / Search Another Student',
                      style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _resetSearch,
                  ),
                ),
              ],

              // Program Result Card
              if (_foundProgram != null) ...[
                _buildProgramCard(
                  _foundProgram!,
                  results,
                  registrations,
                  students,
                  teams,
                  schedules,
                  venues,
                ),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.red,
                      side: const BorderSide(color: AppTheme.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(
                      'Scan / Search Another Item',
                      style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _resetSearch,
                  ),
                ),
              ],

              // Initial Empty State Guidance
              if (!_hasSearched &&
                  _foundStudent == null &&
                  _foundProgram == null &&
                  !_isCameraActive) ...[
                _buildEmptyState(),
              ],
            ],
          ),
        );
      },
    );

    if (widget.isEmbedded) {
      return Scaffold(backgroundColor: AppTheme.cream, body: body);
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(
          'SCAN QR & SEARCH',
          style: GoogleFonts.rye(fontSize: 18, color: AppTheme.ink),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.ink),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/public');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.ink),
            tooltip: 'Refresh Data',
            onPressed: () => triggerDataRefresh(ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cream2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, color: AppTheme.red, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SEARCH STUDENT BY CHASE NUMBER OR SCAN QR',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter Chase No (e.g. J-101, S-204)...',
                    hintStyle: GoogleFonts.workSans(
                      fontSize: 13,
                      color: AppTheme.inkSoft,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: AppTheme.cream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.line),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppTheme.inkSoft,
                              size: 18,
                            ),
                            onPressed: _resetSearch,
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppTheme.red,
                          ),
                          tooltip: 'Scan QR Code',
                          onPressed: () {
                            setState(() {
                              _isCameraActive = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: _handleSearch,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: AppTheme.cream,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleSearch(_searchController.text),
                child: Text(
                  'Search',
                  style: GoogleFonts.workSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraScannerCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.red.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.camera_front,
                    color: AppTheme.cream,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CAMERA QR SCANNER',
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cream,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.videocam_off_outlined,
                  color: AppTheme.cream,
                  size: 20,
                ),
                tooltip: 'Hide Camera',
                onPressed: () {
                  setState(() {
                    _isCameraActive = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: QRScannerWidget(
                onScanned: (payload) {
                  _searchController.text = payload;
                  _handleSearch(payload);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Point camera at student QR badge or program sheet.',
            style: GoogleFonts.workSans(
              fontSize: 12,
              color: AppTheme.cream2.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _formatDateAndDay(String rawDate) {
    if (rawDate.trim().isEmpty) {
      return ('Date TBA', 'Day TBA');
    }
    final clean = rawDate.trim();
    final parsed = DateTime.tryParse(clean);
    if (parsed != null) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final dayName = weekdays[parsed.weekday - 1];
      final monthName = months[parsed.month - 1];
      final formattedDate =
          '${parsed.day.toString().padLeft(2, '0')} $monthName ${parsed.year}';
      return (formattedDate, dayName);
    }
    if (clean.toLowerCase().contains('day')) {
      return (clean, clean);
    }
    return (clean, 'Festival Day');
  }

  Widget _buildStudentCard(
    Student student,
    List<Team> teams,
    List<Program> programs,
    List<Result> results,
    List<Registration> registrations,
    List<Schedule> schedules,
    List<Venue> venues,
  ) {
    final team = teams.where((t) => t.id == student.teamId).firstOrNull;

    final cleanId = student.id.trim().toLowerCase();
    final cleanChase = student.chaseNumber.trim().toLowerCase();
    final cleanName = student.name.trim().toLowerCase();

    // 1. Match Registrations taken from FestController registration program
    final matchedRegistrations = registrations.where((r) {
      final rStud = r.studentId.trim().toLowerCase();
      final regNum = r.registrationNumber.trim().toLowerCase();

      if (cleanId.isNotEmpty && rStud == cleanId) return true;
      if (cleanChase.isNotEmpty && rStud == cleanChase) return true;
      if (cleanName.isNotEmpty && rStud == cleanName) return true;
      if (cleanChase.isNotEmpty && regNum.contains(cleanChase)) return true;
      if (regNum.startsWith('reg-')) {
        final parts = regNum.split('-');
        if (parts.length >= 2 && parts[1] == cleanChase) return true;
      }
      return false;
    }).toList();

    // Deduplicate registrations by programId to avoid duplicate rows
    final seenProgIds = <String>{};
    final uniqueRegistrations = <Registration>[];
    for (final reg in matchedRegistrations) {
      final key = reg.programId.trim().toLowerCase();
      if (key.isNotEmpty && !seenProgIds.contains(key)) {
        seenProgIds.add(key);
        uniqueRegistrations.add(reg);
      } else if (key.isEmpty) {
        uniqueRegistrations.add(reg);
      }
    }

    // 2. Pair each registration with its Program, Schedule, and Venue
    final registeredItems = uniqueRegistrations.map((reg) {
      String progCodeFromReg = '';
      if (reg.registrationNumber.toUpperCase().startsWith('REG-')) {
        final parts = reg.registrationNumber.split('-');
        if (parts.length >= 3) {
          progCodeFromReg = parts.sublist(2).join('-');
        }
      }

      final prog = programs.where((p) {
        final pId = p.id.trim().toLowerCase();
        final pCode = p.programCode.trim().toLowerCase();
        final pName = p.programName.trim().toLowerCase();
        final regProgId = reg.programId.trim().toLowerCase();

        if (pId == regProgId || pCode == regProgId || pName == regProgId) {
          return true;
        }
        if (progCodeFromReg.isNotEmpty &&
            (pCode == progCodeFromReg.toLowerCase() ||
                pId == progCodeFromReg.toLowerCase())) {
          return true;
        }
        return false;
      }).firstOrNull;

      final progName = prog?.programName ??
          (progCodeFromReg.isNotEmpty
              ? progCodeFromReg
              : (reg.programId.isNotEmpty
                  ? 'Program #${reg.programId}'
                  : 'Registered Program'));
      final progCode = prog?.programCode ?? progCodeFromReg;
      final sectionLabel = prog?.section.label ?? student.section.label;
      final isStage = prog?.isStageProgram ?? true;

      // Schedule matching
      final schedule = schedules.where((s) {
        final sProgId = s.programId.trim().toLowerCase();
        final regProgId = reg.programId.trim().toLowerCase();
        if (sProgId == regProgId) return true;
        if (prog != null) {
          if (sProgId == prog.id.trim().toLowerCase()) return true;
          if (sProgId == prog.programCode.trim().toLowerCase()) return true;
          if (sProgId == prog.programName.trim().toLowerCase()) return true;
        }
        if (progCodeFromReg.isNotEmpty &&
            sProgId == progCodeFromReg.toLowerCase()) {
          return true;
        }
        return false;
      }).firstOrNull;

      final venue = schedule != null
          ? venues.where((v) {
              final vId = v.id.trim().toLowerCase();
              final sVenId = schedule.venueId.trim().toLowerCase();
              final vName = v.name.trim().toLowerCase();
              return vId == sVenId || vName == sVenId;
            }).firstOrNull
          : null;

      final venueName = venue?.name ??
          (schedule?.venueId.isNotEmpty == true
              ? schedule!.venueId
              : 'Venue TBA');

      return (
        reg: reg,
        prog: prog,
        progName: progName,
        progCode: progCode,
        sectionLabel: sectionLabel,
        isStage: isStage,
        schedule: schedule,
        venueName: venueName,
      );
    }).toList();

    // 3. PRIORITY SORT: Scheduled programs ("sudeulmet") MUST appear FIRST
    registeredItems.sort((a, b) {
      final aHasSchedule = a.schedule != null;
      final bHasSchedule = b.schedule != null;
      if (aHasSchedule && !bHasSchedule) return -1;
      if (!aHasSchedule && bHasSchedule) return 1;
      if (aHasSchedule && bHasSchedule) {
        final dateCmp = a.schedule!.date.compareTo(b.schedule!.date);
        if (dateCmp != 0) return dateCmp;
        return a.schedule!.startTime.compareTo(b.schedule!.startTime);
      }
      return a.progName.compareTo(b.progName);
    });

    // 4. Published Results for this student
    final studentPublishedResults = results.where((r) {
      final rStud = r.studentId.trim().toLowerCase();
      final matchStudent = (cleanId.isNotEmpty && rStud == cleanId) ||
          (cleanChase.isNotEmpty && rStud == cleanChase) ||
          (cleanName.isNotEmpty && rStud == cleanName);
      final isPublished =
          r.status == ResultStatus.published || r.publishedAt != null;
      return matchStudent && isPublished;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.red, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.rye(fontSize: 22, color: AppTheme.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chase #${student.chaseNumber} • ${student.section.label} Section',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        color: AppTheme.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.qr_code_2,
                  color: AppTheme.ink,
                  size: 28,
                ),
                tooltip: 'View QR Code',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => StudentQrDisplayDialog(
                      studentName: student.name,
                      chaseNumber: student.chaseNumber,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.line),
          const SizedBox(height: 10),

          // Team Badge
          if (team != null) ...[
            Row(
              children: [
                const Icon(Icons.group, color: AppTheme.red, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Team: ${team.teamName} (${team.teamCode})',
                  style: GoogleFonts.workSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 1. REGISTERED PROGRAMS SECTION (From FestController Registration Program)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGISTERED PROGRAMS (${registeredItems.length})',
                style: GoogleFonts.workSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.inkSoft,
                ),
              ),
              if (registeredItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${registeredItems.length} Enrolled',
                    style: GoogleFonts.workSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (registeredItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cream2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.inkSoft,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No registered programs found for this student. Verify registration in Fest Controller.',
                        style: GoogleFonts.workSans(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.inkSoft,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: registeredItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = registeredItems[idx];
                final reg = item.reg;
                final progName = item.progName;
                final progCode = item.progCode;
                final sectionLabel = item.sectionLabel;
                final isStage = item.isStage;
                final schedule = item.schedule;
                final venueName = item.venueName;

                // Format Date and Day
                final (dateFormatted, dayFormatted) =
                    schedule != null
                        ? _formatDateAndDay(schedule.date)
                        : ('Date TBA', 'Day TBA');

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cream2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: schedule != null
                          ? AppTheme.red.withValues(alpha: 0.3)
                          : AppTheme.line,
                      width: schedule != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Program Title Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              color: AppTheme.red,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progName,
                                  style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                if (progCode.isNotEmpty)
                                  Text(
                                    'Code: $progCode',
                                    style: GoogleFonts.workSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.inkSoft,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              reg.status.label,
                              style: GoogleFonts.workSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Program Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Chip(
                            labelPadding: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppTheme.cream,
                            side: const BorderSide(color: AppTheme.line),
                            label: Text(
                              sectionLabel,
                              style: GoogleFonts.workSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                          Chip(
                            labelPadding: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppTheme.cream,
                            side: const BorderSide(color: AppTheme.line),
                            label: Text(
                              isStage ? 'Stage' : 'Non-Stage',
                              style: GoogleFonts.workSans(
                                fontSize: 10.5,
                                color: AppTheme.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // SCHEDULE CARD UNDER PROGRAM (FORMAT: Date, Day, Time, Venue)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              schedule != null
                                  ? Colors.white
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                schedule != null
                                    ? AppTheme.red.withValues(alpha: 0.25)
                                    : Colors.grey.shade300,
                            width: 1.2,
                          ),
                          boxShadow:
                              schedule != null
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child:
                            schedule != null
                                ? Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // DATE
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 15,
                                          color: AppTheme.red,
                                        ),
                                        const SizedBox(width: 5),
                                        RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.workSans(
                                              fontSize: 12,
                                              color: AppTheme.ink,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Date: ',
                                                style: GoogleFonts.workSans(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.inkSoft,
                                                ),
                                              ),
                                              TextSpan(
                                                text: dateFormatted,
                                                style: GoogleFonts.workSans(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.ink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // DAY
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.today_rounded,
                                          size: 15,
                                          color: AppTheme.red,
                                        ),
                                        const SizedBox(width: 5),
                                        RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.workSans(
                                              fontSize: 12,
                                              color: AppTheme.ink,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Day: ',
                                                style: GoogleFonts.workSans(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.inkSoft,
                                                ),
                                              ),
                                              TextSpan(
                                                text: dayFormatted,
                                                style: GoogleFonts.workSans(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.ink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // TIME
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_filled_rounded,
                                          size: 15,
                                          color: AppTheme.red,
                                        ),
                                        const SizedBox(width: 5),
                                        RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.workSans(
                                              fontSize: 12,
                                              color: AppTheme.ink,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Time: ',
                                                style: GoogleFonts.workSans(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.inkSoft,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${schedule.startTime} - ${schedule.endTime}',
                                                style: GoogleFonts.workSans(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.ink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // VENUE
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.place_rounded,
                                          size: 15,
                                          color: AppTheme.red,
                                        ),
                                        const SizedBox(width: 5),
                                        RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.workSans(
                                              fontSize: 12,
                                              color: AppTheme.ink,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Venue: ',
                                                style: GoogleFonts.workSans(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.inkSoft,
                                                ),
                                              ),
                                              TextSpan(
                                                text: venueName,
                                                style: GoogleFonts.workSans(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.ink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                                : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Schedule: Date, Day, Time & Venue TBA (Pending Schedule)',
                                      style: GoogleFonts.workSans(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.line),
          const SizedBox(height: 12),

          // 2. PUBLISHED RESULTS SECTION (Placed after all registered programs list)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PUBLISHED RESULTS (${studentPublishedResults.length})',
                style: GoogleFonts.workSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.inkSoft,
                ),
              ),
              if (studentPublishedResults.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.mustard.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.mustard.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppTheme.mustard,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Published',
                        style: GoogleFonts.workSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (studentPublishedResults.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cream2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: AppTheme.inkSoft,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No published results found for this student yet. Results will appear once published by the Fest Controller.',
                      style: GoogleFonts.workSans(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: studentPublishedResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final r = studentPublishedResults[idx];
                final prog = programs
                    .where((p) => p.id == r.programId)
                    .firstOrNull;
                final progName = prog?.programName ?? 'Program #${r.programId}';

                // Winner badge styling
                Color posColor = AppTheme.red;
                String posLabel = 'Position #${r.position}';
                IconData posIcon = Icons.emoji_events_rounded;
                if (r.position == 1) {
                  posColor = const Color(0xFFD4AF37); // Gold
                  posLabel = '1st Place (Winner)';
                } else if (r.position == 2) {
                  posColor = const Color(0xFF757575); // Silver
                  posLabel = '2nd Place';
                } else if (r.position == 3) {
                  posColor = const Color(0xFFCD7F32); // Bronze
                  posLabel = '3rd Place';
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.mustard.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(posIcon, color: posColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progName,
                              style: GoogleFonts.workSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppTheme.ink,
                              ),
                            ),
                            if (r.remarks != null && r.remarks!.isNotEmpty)
                              Text(
                                r.remarks!,
                                style: GoogleFonts.workSans(
                                  fontSize: 11,
                                  color: AppTheme.inkSoft,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (r.position != null && r.position! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: posColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            posLabel,
                            style: GoogleFonts.workSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (r.grade.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.mustard.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.mustard.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'Grade ${r.grade}',
                            style: GoogleFonts.workSans(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${r.points} pts',
                          style: GoogleFonts.workSans(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.red,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(
    Program program,
    List<Result> results,
    List<Registration> registrations,
    List<Student> students,
    List<Team> teams,
    List<Schedule> schedules,
    List<Venue> venues,
  ) {
    final progResults = results
        .where((r) => r.programId == program.id)
        .toList();
    final progRegistrations = registrations
        .where((r) => r.programId == program.id)
        .toList();

    final progSchedule = schedules.where((s) {
      if (s.programId == program.id) return true;
      if (s.programId.toLowerCase().trim() ==
          program.programCode.toLowerCase().trim()) {
        return true;
      }
      if (s.programId.toLowerCase().trim() ==
          program.programName.toLowerCase().trim()) {
        return true;
      }
      return false;
    }).firstOrNull;

    final progVenue =
        progSchedule != null
            ? venues.where((v) {
              return v.id == progSchedule.venueId ||
                  v.name.toLowerCase().trim() ==
                      progSchedule.venueId.toLowerCase().trim();
            }).firstOrNull
            : null;
    final progVenueName =
        progVenue?.name ??
        (progSchedule?.venueId.isNotEmpty == true
            ? progSchedule!.venueId
            : 'Venue TBA');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.red, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: AppTheme.red, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  program.programName,
                  style: GoogleFonts.rye(fontSize: 20, color: AppTheme.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Code: ${program.programCode} • Category: ${program.category.name.toUpperCase()} • Section: ${program.section.label}',
            style: GoogleFonts.workSans(
              fontSize: 13,
              color: AppTheme.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          // SCHEDULE BANNER (Date, Time, Venue) directly under program
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: progSchedule != null ? AppTheme.cream : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: progSchedule != null
                    ? AppTheme.line
                    : Colors.grey.shade300,
              ),
            ),
            child: progSchedule != null
                ? Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 15,
                            color: AppTheme.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            progSchedule.date.isNotEmpty
                                ? progSchedule.date
                                : 'Date TBA',
                            style: GoogleFonts.workSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_filled_rounded,
                            size: 15,
                            color: AppTheme.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${progSchedule.startTime} - ${progSchedule.endTime}',
                            style: GoogleFonts.workSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 15,
                            color: AppTheme.red,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            progVenueName,
                            style: GoogleFonts.workSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: progSchedule.status == 'IN_PROGRESS'
                              ? Colors.orange.withValues(alpha: 0.15)
                              : (progSchedule.status == 'COMPLETED'
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          progSchedule.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: progSchedule.status == 'IN_PROGRESS'
                                ? Colors.orange.shade900
                                : (progSchedule.status == 'COMPLETED'
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Schedule: Date, Time & Venue TBA',
                        style: GoogleFonts.workSans(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.line),
          const SizedBox(height: 10),

          // Registered Students / Participants
          Text(
            'REGISTERED PARTICIPANTS (${progRegistrations.length})',
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          if (progRegistrations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No students registered for this program yet.',
                style: GoogleFonts.workSans(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.inkSoft,
                  fontSize: 13,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: progRegistrations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (ctx, idx) {
                final reg = progRegistrations[idx];
                final student = students
                    .where((s) => s.id == reg.studentId)
                    .firstOrNull;
                final studentTeam = student != null
                    ? teams.where((t) => t.id == student.teamId).firstOrNull
                    : null;

                return ListTile(
                  dense: true,
                  tileColor: AppTheme.cream2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.line),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.red.withValues(alpha: 0.15),
                    child: Text(
                      student?.chaseNumber.isNotEmpty == true
                          ? student!.chaseNumber.substring(0, 1)
                          : '#',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.red,
                      ),
                    ),
                  ),
                  title: Text(
                    student?.name ?? 'Student #${reg.studentId}',
                    style: GoogleFonts.workSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    'Chase #${student?.chaseNumber ?? "-"} • Team: ${studentTeam?.teamName ?? "-"}',
                    style: GoogleFonts.workSans(fontSize: 11),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reg.status.label,
                      style: GoogleFonts.workSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.line),
          const SizedBox(height: 10),

          // Program Results
          Text(
            'PROGRAM RESULTS (${progResults.length})',
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          if (progResults.isEmpty)
            Text(
              'No results published yet for this program.',
              style: GoogleFonts.workSans(
                fontStyle: FontStyle.italic,
                color: AppTheme.inkSoft,
                fontSize: 13,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: progResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (ctx, idx) {
                final r = progResults[idx];
                final student =
                    students.where((s) => s.id == r.studentId).firstOrNull;
                return ListTile(
                  dense: true,
                  tileColor: AppTheme.cream2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  title: Text(
                    student != null
                        ? '${student.name} (${student.chaseNumber})'
                        : 'Student ID: ${r.studentId}',
                    style: GoogleFonts.workSans(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Position: ${r.position ?? "N/A"} | Grade: ${r.grade.isNotEmpty ? r.grade : "N/A"}',
                  ),
                  trailing: Text(
                    '+${r.points} pts',
                    style: GoogleFonts.workSans(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.red,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppTheme.cream2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner, size: 48, color: AppTheme.inkSoft),
          const SizedBox(height: 14),
          Text(
            'Ready to Scan',
            style: GoogleFonts.rye(fontSize: 16, color: AppTheme.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter a student Chase Number in the box above or scan their QR badge with your camera.',
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(fontSize: 13, color: AppTheme.inkSoft),
          ),
        ],
      ),
    );
  }
}
