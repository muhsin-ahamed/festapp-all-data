import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _handleSearch(String rawQuery) {
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
          return s.chaseNumber.toLowerCase() == query ||
              s.id.toLowerCase() == query ||
              s.name.toLowerCase() == query;
        }).firstOrNull ??
        students.where((s) {
          return s.name.toLowerCase().contains(query);
        }).firstOrNull;

    if (matchedStudent != null) {
      setState(() {
        _foundStudent = matchedStudent;
        _isCameraActive = false;
      });
      return;
    }

    // 1b. Check if query matches a registration number or student chase in registration
    final matchedReg = registrations.where((r) {
      return r.registrationNumber.toLowerCase() == query ||
          r.registrationNumber.toLowerCase().contains(query);
    }).firstOrNull;
    if (matchedReg != null) {
      final regStudent =
          students.where((s) => s.id == matchedReg.studentId).firstOrNull;
      if (regStudent != null) {
        setState(() {
          _foundStudent = regStudent;
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
    final studentResults = results
        .where((r) => r.studentId == student.id)
        .toList();
    final studentRegistrations = registrations
        .where((r) =>
            r.studentId == student.id ||
            r.registrationNumber.contains(student.chaseNumber))
        .toList();

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

          // REGISTERED PROGRAMS SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGISTERED PROGRAMS (${studentRegistrations.length})',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.inkSoft,
                ),
              ),
              if (studentRegistrations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${studentRegistrations.length} Enrolled',
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

          if (studentRegistrations.isEmpty)
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
                child: Text(
                  'No registered programs found for this student.',
                  style: GoogleFonts.workSans(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.inkSoft,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: studentRegistrations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final reg = studentRegistrations[idx];
                final prog = programs
                    .where((p) => p.id == reg.programId)
                    .firstOrNull;
                final progName =
                    prog?.programName ?? 'Program #${reg.programId}';
                final progCode = prog?.programCode ?? '';
                final sectionLabel =
                    prog?.section.label ?? student.section.label;
                final isStage = prog?.isStageProgram ?? true;

                // Schedule details if available (matching flexibly by id, code, or name)
                final schedule = schedules.where((s) {
                  if (s.programId == reg.programId) return true;
                  if (prog != null) {
                    if (s.programId == prog.id) return true;
                    if (s.programId.toLowerCase().trim() ==
                        prog.programCode.toLowerCase().trim()) {
                      return true;
                    }
                    if (s.programId.toLowerCase().trim() ==
                        prog.programName.toLowerCase().trim()) {
                      return true;
                    }
                  }
                  return false;
                }).firstOrNull;

                final venue =
                    schedule != null
                        ? venues.where((v) {
                          return v.id == schedule.venueId ||
                              v.name.toLowerCase().trim() ==
                                  schedule.venueId.toLowerCase().trim();
                        }).firstOrNull
                        : null;
                final venueName =
                    venue?.name ??
                    (schedule?.venueId.isNotEmpty == true
                        ? schedule!.venueId
                        : 'Venue TBA');

                // Check if result is already available for this program
                final progResult =
                    studentResults
                        .where((r) => r.programId == reg.programId)
                        .firstOrNull;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cream2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                    fontSize: 14,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                if (progCode.isNotEmpty)
                                  Text(
                                    'Code: $progCode',
                                    style: GoogleFonts.workSans(
                                      fontSize: 11,
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
                      // SCHEDULE BANNER (Date, Time, Venue) directly under program
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              schedule != null
                                  ? Colors.white
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                schedule != null
                                    ? AppTheme.line
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child:
                            schedule != null
                                ? Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Date
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 14,
                                          color: AppTheme.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          schedule.date.isNotEmpty
                                              ? schedule.date
                                              : 'Date TBA',
                                          style: GoogleFonts.workSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Time
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_filled_rounded,
                                          size: 14,
                                          color: AppTheme.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${schedule.startTime} - ${schedule.endTime}',
                                          style: GoogleFonts.workSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Venue
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.place_rounded,
                                          size: 14,
                                          color: AppTheme.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          venueName,
                                          style: GoogleFonts.workSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                            color: AppTheme.ink,
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
                                      Icons.info_outline,
                                      size: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Schedule: Date, Time & Venue TBA',
                                      style: GoogleFonts.workSans(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                      Wrap(
                        spacing: 8,
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
                          if (schedule != null)
                            Chip(
                              labelPadding: EdgeInsets.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              backgroundColor:
                                  schedule.status == 'IN_PROGRESS'
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : (schedule.status == 'COMPLETED'
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.blue.withValues(
                                            alpha: 0.12,
                                          )),
                              side: BorderSide(
                                color:
                                    schedule.status == 'IN_PROGRESS'
                                        ? Colors.orange.shade400
                                        : (schedule.status == 'COMPLETED'
                                            ? Colors.green.shade400
                                            : Colors.blue.shade300),
                              ),
                              label: Text(
                                schedule.status,
                                style: GoogleFonts.workSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      schedule.status == 'IN_PROGRESS'
                                          ? Colors.orange.shade900
                                          : (schedule.status == 'COMPLETED'
                                              ? Colors.green.shade800
                                              : Colors.blue.shade800),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (progResult != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.mustard.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.mustard
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events,
                                  size: 14, color: AppTheme.mustard),
                              const SizedBox(width: 6),
                              Text(
                                'Result: Position #${progResult.position ?? "-"} • Grade ${progResult.grade} • +${progResult.points} pts',
                                style: GoogleFonts.workSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 18),
          const Divider(color: AppTheme.line),
          const SizedBox(height: 10),

          // Results / Accomplishments
          Text(
            'PERFORMANCE & RESULTS (${studentResults.length})',
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.inkSoft,
            ),
          ),
          const SizedBox(height: 10),

          if (studentResults.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No published results found for this student yet.',
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
              itemCount: studentResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final r = studentResults[idx];
                final prog = programs
                    .where((p) => p.id == r.programId)
                    .firstOrNull;
                final progName = prog?.programName ?? 'Program #${r.programId}';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cream2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppTheme.mustard,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          progName,
                          style: GoogleFonts.workSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      if (r.position != null && r.position! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Position #${r.position}',
                            style: GoogleFonts.workSans(
                              color: AppTheme.cream,
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
                            color: AppTheme.mustard,
                            borderRadius: BorderRadius.circular(8),
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
                      Text(
                        '+${r.points} pts',
                        style: GoogleFonts.workSans(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.red,
                          fontSize: 13,
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
