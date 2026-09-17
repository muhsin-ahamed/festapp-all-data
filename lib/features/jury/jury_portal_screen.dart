import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui_components.dart';
import '../../data/models/program_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/result_model.dart';
import '../../services/qr_service.dart';
import '../../services/scoring_service.dart';

class _PrizeSlotData {
  String? studentId;
  final TextEditingController marksController;
  final TextEditingController gradeController;
  int position;
  final String title;
  final String emoji;
  final bool isTieSlot;

  _PrizeSlotData({
    required String defaultMarks,
    required String defaultGrade,
    required this.position,
    required this.title,
    required this.emoji,
    this.isTieSlot = false,
  })  : marksController = TextEditingController(text: defaultMarks),
        gradeController = TextEditingController(text: defaultGrade);

  void dispose() {
    marksController.dispose();
    gradeController.dispose();
  }
}

class JuryPortalScreen extends ConsumerStatefulWidget {
  final String? targetProgramId;
  const JuryPortalScreen({super.key, this.targetProgramId});

  @override
  ConsumerState<JuryPortalScreen> createState() => _JuryPortalScreenState();
}

class _JuryPortalScreenState extends ConsumerState<JuryPortalScreen> {
  Program? _selectedProgram;
  List<_PrizeSlotData>? _prizeSlots;
  String? _currentProgramIdForSlots;

  bool _isScanningProgramQr = false;
  bool _hasInitialProgramSet = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    if (_prizeSlots != null) {
      for (final s in _prizeSlots!) {
        s.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final juriesAsync = ref.watch(juriesProvider);
    final programsAsync = ref.watch(programsProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final regsAsync = ref.watch(registrationsProvider);
    final resultsAsync = ref.watch(resultsProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(size: 26),
            const SizedBox(width: 10),
            Text(
              'JURY MARKING PORTAL',
              style: GoogleFonts.rye(fontSize: 18, color: AppTheme.ink),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.ink),
            tooltip: 'Scan Program QR',
            onPressed: () {
              setState(() {
                _isScanningProgramQr = !_isScanningProgramQr;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.red),
            onPressed: () {
              ref.read(authServiceProvider).logout();
              context.go('/public');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          const PatternStrip(height: 8),
          Expanded(
            child: juriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading jury data: $err')),
              data: (juries) {
                if (juries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No jury profiles found in the system.\nPlease create a jury profile in Controller settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                final currentJury =
                    juries
                        .where(
                          (j) =>
                              j.id == user?.juryId ||
                              j.username == user?.username,
                        )
                        .firstOrNull ??
                    juries.first;
                final assignedProgIds = currentJury.assignedPrograms;

                final allPrograms = programsAsync.value ?? [];
                final assignedPrograms = allPrograms
                    .where((p) => assignedProgIds.contains(p.id))
                    .toList();

                if (!_hasInitialProgramSet && widget.targetProgramId != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final prog = assignedPrograms
                        .where((p) => p.id == widget.targetProgramId)
                        .firstOrNull;
                    if (prog != null) {
                      setState(() {
                        _selectedProgram = prog;
                        _hasInitialProgramSet = true;
                      });
                    } else {
                      setState(() {
                        _hasInitialProgramSet = true;
                      });
                    }
                  });
                }

                if (_isScanningProgramQr) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Scan Program Jury QR Code',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        QRScannerWidget(
                          onScanned: (payload) {
                            final scanRes = QrService.parseQrPayload(payload);
                            String? searchProgramId = scanRes.value;
                            if (scanRes.type == QrScanType.juryLoginProgram) {
                              searchProgramId = scanRes.programId;
                            }

                            final prog = allPrograms
                                .where(
                                  (p) =>
                                      p.id == searchProgramId ||
                                      p.programCode == searchProgramId,
                                )
                                .firstOrNull;
                            if (prog != null) {
                              setState(() {
                                _selectedProgram = prog;
                                _isScanningProgramQr = false;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Program "$searchProgramId" not found.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }

                if (_selectedProgram != null) {
                  return _buildMarkingForm(
                    _selectedProgram!,
                    studentsAsync.value ?? [],
                    regsAsync.value ?? [],
                    resultsAsync.value ?? [],
                    currentJury.id,
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Programs for ${currentJury.name}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (assignedPrograms.isEmpty) ...[
                        const Text(
                          'No programs currently assigned to your jury account.',
                        ),
                      ] else ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: assignedPrograms.length,
                          itemBuilder: (context, idx) {
                            final p = assignedPrograms[idx];
                            final progResults = (resultsAsync.value ?? [])
                                .where((r) => r.programId == p.id)
                                .toList();
                            final hasDraft = progResults
                                .any((r) => r.status == ResultStatus.draft);
                            final hasPublished = progResults.any(
                              (r) =>
                                  r.status == ResultStatus.published ||
                                  r.status == ResultStatus.announced,
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${p.programName} (${p.programCode})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (hasDraft) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.amber.shade700,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.drafts_outlined,
                                              size: 14,
                                              color: Colors.amber.shade900,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Draft Submitted',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (hasPublished) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 14,
                                              color: Colors.green.shade900,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Published',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  'Section: ${p.section.label} • ${p.isStageProgram ? "Stage" : "Non-Stage"}',
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedProgram = p;
                                    });
                                  },
                                  child: Text(
                                    hasDraft
                                        ? 'Edit Draft'
                                        : (hasPublished
                                            ? 'View Results'
                                            : 'Open Marking Paper'),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _initSlotsForProgram(
    Program program,
    List<Student> participants,
    List<Result> existingResults,
  ) {
    if (_prizeSlots != null) {
      for (final s in _prizeSlots!) {
        s.dispose();
      }
    }

    _prizeSlots = [
      _PrizeSlotData(
        defaultMarks: '90',
        defaultGrade: 'A',
        position: 1,
        title: '1st Place (First Prize)',
        emoji: '🥇',
      ),
      _PrizeSlotData(
        defaultMarks: '85',
        defaultGrade: 'A',
        position: 2,
        title: '2nd Place (Second Prize)',
        emoji: '🥈',
      ),
      _PrizeSlotData(
        defaultMarks: '80',
        defaultGrade: 'B',
        position: 3,
        title: '3rd Place (Third Prize)',
        emoji: '🥉',
      ),
      _PrizeSlotData(
        defaultMarks: '85',
        defaultGrade: 'A',
        position: 1,
        title: 'Shared / Tie Position (Optional)',
        emoji: '🤝',
        isTieSlot: true,
      ),
    ];
    _currentProgramIdForSlots = program.id;

    // Pre-populate with existing results if any
    final progResults =
        existingResults.where((r) => r.programId == program.id).toList();
    if (progResults.isNotEmpty) {
      final pos1 = progResults.where((r) => r.position == 1).toList();
      final pos2 = progResults.where((r) => r.position == 2).toList();
      final pos3 = progResults.where((r) => r.position == 3).toList();

      if (pos1.isNotEmpty) {
        _prizeSlots![0].studentId = pos1[0].studentId;
        _prizeSlots![0].marksController.text =
            pos1[0].marks.toInt().toString();
        _prizeSlots![0].gradeController.text = pos1[0].grade;
      }
      if (pos2.isNotEmpty) {
        _prizeSlots![1].studentId = pos2[0].studentId;
        _prizeSlots![1].marksController.text =
            pos2[0].marks.toInt().toString();
        _prizeSlots![1].gradeController.text = pos2[0].grade;
      }
      if (pos3.isNotEmpty) {
        _prizeSlots![2].studentId = pos3[0].studentId;
        _prizeSlots![2].marksController.text =
            pos3[0].marks.toInt().toString();
        _prizeSlots![2].gradeController.text = pos3[0].grade;
      }

      // Check for tie (second recipient of pos 1, 2, or 3)
      if (pos1.length > 1) {
        _prizeSlots![3].studentId = pos1[1].studentId;
        _prizeSlots![3].position = 1;
        _prizeSlots![3].marksController.text =
            pos1[1].marks.toInt().toString();
        _prizeSlots![3].gradeController.text = pos1[1].grade;
      } else if (pos2.length > 1) {
        _prizeSlots![3].studentId = pos2[1].studentId;
        _prizeSlots![3].position = 2;
        _prizeSlots![3].marksController.text =
            pos2[1].marks.toInt().toString();
        _prizeSlots![3].gradeController.text = pos2[1].grade;
      } else if (pos3.length > 1) {
        _prizeSlots![3].studentId = pos3[1].studentId;
        _prizeSlots![3].position = 3;
        _prizeSlots![3].marksController.text =
            pos3[1].marks.toInt().toString();
        _prizeSlots![3].gradeController.text = pos3[1].grade;
      }
    } else {
      // Default to distinct participants if available
      if (participants.isNotEmpty) {
        _prizeSlots![0].studentId = participants[0].id;
      }
      if (participants.length > 1) {
        _prizeSlots![1].studentId = participants[1].id;
      }
      if (participants.length > 2) {
        _prizeSlots![2].studentId = participants[2].id;
      }
      // Slot 3 (tie slot) stays null by default
    }
  }

  void _onMarksChanged(int slotIdx, String val) {
    final marks = double.tryParse(val.trim());
    if (marks != null) {
      String autoGrade;
      if (marks >= 80) {
        autoGrade = 'A';
      } else if (marks >= 70) {
        autoGrade = 'B';
      } else if (marks >= 60) {
        autoGrade = 'C';
      } else {
        autoGrade = 'D';
      }
      _prizeSlots![slotIdx].gradeController.text = autoGrade;
    }
    setState(() {});
  }

  Widget _buildPrizeCard({
    required int slotIdx,
    required _PrizeSlotData slot,
    required List<Student> participants,
    required ScoringService scoring,
  }) {
    final pos = slot.position;
    final grade = slot.gradeController.text.trim().toUpperCase();
    final calculatedPoints = scoring.calculateResultPoints(
      position: pos > 0 ? pos : null,
      grade: grade,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: slot.isTieSlot
                      ? Colors.purple.shade50
                      : (slotIdx == 0
                          ? Colors.amber.shade50
                          : (slotIdx == 1
                              ? Colors.blueGrey.shade50
                              : Colors.orange.shade50)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: slot.isTieSlot
                        ? Colors.purple.shade300
                        : (slotIdx == 0
                            ? Colors.amber.shade400
                            : (slotIdx == 1
                                ? Colors.blueGrey.shade300
                                : Colors.orange.shade300)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(slot.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      slot.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: slot.isTieSlot
                            ? Colors.purple.shade900
                            : (slotIdx == 0
                                ? Colors.amber.shade900
                                : (slotIdx == 1
                                    ? Colors.blueGrey.shade900
                                    : Colors.orange.shade900)),
                      ),
                    ),
                  ],
                ),
              ),
              if (slot.isTieSlot) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '(Assign if two participants share 1st, 2nd, or 3rd place)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Dropdown: Select Registered Student (Matches screenshot format)
          AppDropdown<String?>(
            label:
                '${slotIdx + 1}. Select Registered Student (${participants.length} registered)',
            value: slot.studentId,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  slot.isTieSlot
                      ? 'None / No Tie Awarded'
                      : '-- Select Winner (${participants.length} registered) --',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              ...participants.map(
                (s) => DropdownMenuItem<String?>(
                  value: s.id,
                  child: Text('${s.name} (${s.chaseNumber})'),
                ),
              ),
            ],
            onChanged: (val) {
              setState(() {
                slot.studentId = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // 3 Fields Layout: Marks / Points Value, Grade (A, B, C), Position (1 Position per Student)
          LayoutBuilder(
            builder: (context, constraints) {
              final marksField = AppTextField(
                label: 'Marks / Points Value',
                controller: slot.marksController,
                keyboardType: TextInputType.number,
                onChanged: (v) => _onMarksChanged(slotIdx, v),
              );

              final gradeField = AppTextField(
                label: 'Grade (A, B, C)',
                controller: slot.gradeController,
                onChanged: (_) => setState(() {}),
              );

              final posDropdown = AppDropdown<int>(
                label: 'Position (1 Position per Student)',
                value: slot.position,
                items: slot.isTieSlot
                    ? const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('1st Place (Tie)'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('2nd Place (Tie)'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('3rd Place (Tie)'),
                        ),
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Participant (No Position)'),
                        ),
                      ]
                    : const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('1st Place'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('2nd Place'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('3rd Place'),
                        ),
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Participant (No Position)'),
                        ),
                      ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => slot.position = v);
                  }
                },
              );

              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    marksField,
                    const SizedBox(height: 12),
                    gradeField,
                    const SizedBox(height: 12),
                    posDropdown,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: marksField),
                  const SizedBox(width: 12),
                  Expanded(child: gradeField),
                  const SizedBox(width: 12),
                  Expanded(child: posDropdown),
                ],
              );
            },
          ),
          const SizedBox(height: 8),

          // Calculated Total Points preview line (Matches screenshot format)
          Text(
            'Calculated Total Points: $calculatedPoints PTS (Position: ${pos > 0 ? "$pos" : "None"} + Grade: ${grade.isEmpty ? "None" : grade})',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppTheme.red,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkingForm(
    Program program,
    List<Student> allStudents,
    List<dynamic> allRegs,
    List<Result> allResults,
    String juryId,
  ) {
    // Filter participants for this program
    final progRegs = allRegs.where((r) => r.programId == program.id).toList();
    final studentIds = progRegs.map((r) => r.studentId).toSet();
    final participants =
        allStudents.where((s) => studentIds.contains(s.id)).toList();

    // Initialize or refresh slots for this program
    if (_prizeSlots == null || _currentProgramIdForSlots != program.id) {
      _initSlotsForProgram(program, participants, allResults);
    }

    final scoring = ref.read(scoringServiceProvider);
    final isGroup =
        program.maxParticipants > 1 || program.section == FestSection.group;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _selectedProgram = null;
            _prizeSlots = null;
            _currentProgramIdForSlots = null;
          }),
        ),
        title: Text('Marking: ${program.programName} (${program.programCode})'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program Header Information Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${program.programName} (${program.programCode})',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(program.section.label),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Chip(
                        label: Text(
                          program.isStageProgram
                              ? 'Stage Program'
                              : 'Non-Stage Program',
                        ),
                        backgroundColor: Colors.amber.shade50,
                        labelStyle: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Chip(
                        label: Text(
                          isGroup
                              ? 'Group Program (${program.maxParticipants} max)'
                              : 'Individual Program',
                        ),
                        backgroundColor: isGroup
                            ? Colors.purple.shade50
                            : Colors.green.shade50,
                        labelStyle: TextStyle(
                          color: isGroup
                              ? Colors.purple.shade900
                              : Colors.green.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Chip(
                        label: Text('${participants.length} Registered'),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Enter Student Marks & Positions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (participants.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(31),
                  border: Border.all(color: Colors.amber.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No registered participants found for this program.',
                        style: GoogleFonts.inter(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // The 4 Prize Entry Cards: 1st, 2nd, 3rd, and Tie
              for (int i = 0; i < _prizeSlots!.length; i++) ...[
                _buildPrizeCard(
                  slotIdx: i,
                  slot: _prizeSlots![i],
                  participants: participants,
                  scoring: scoring,
                ),
                const SizedBox(height: 14),
              ],

              const SizedBox(height: 16),
              AppButton(
                label: _isSubmitting
                    ? 'Submitting Draft Results...'
                    : 'Submit Draft Results to Controller',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                width: double.infinity,
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final assignedSlots = <int>[];
                        final selectedStudentIds = <String>{};

                        for (int i = 0; i < _prizeSlots!.length; i++) {
                          final sId = _prizeSlots![i].studentId;
                          if (sId != null && sId.isNotEmpty) {
                            if (selectedStudentIds.contains(sId)) {
                              final stud = allStudents
                                  .where((s) => s.id == sId)
                                  .firstOrNull;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Duplicate student: "${stud?.name ?? sId}" is selected for multiple prize slots! Each student can only be awarded once.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            selectedStudentIds.add(sId);
                            assignedSlots.add(i);
                          }
                        }

                        if (assignedSlots.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one student before submitting.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        // Validate position counts: max 2 recipients per position (allowing ties)
                        final positionCounts = <int, int>{};
                        for (final slotIdx in assignedSlots) {
                          final pos = _prizeSlots![slotIdx].position;
                          if (pos > 0) {
                            positionCounts[pos] =
                                (positionCounts[pos] ?? 0) + 1;
                            if (positionCounts[pos]! > 2) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Position $pos has been assigned more than twice! At most two students can share a position (tie).',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                          }
                        }

                        setState(() => _isSubmitting = true);

                        try {
                          final allExistingResults = await ref
                              .read(resultRepositoryProvider)
                              .getByProgram(program.id);

                          // Delete any existing results for this program that are no longer assigned
                          final currentStudentIds = assignedSlots
                              .map((idx) => _prizeSlots![idx].studentId)
                              .whereType<String>()
                              .toSet();
                          for (final ex in allExistingResults) {
                            if (!currentStudentIds.contains(ex.studentId)) {
                              await ref
                                  .read(resultRepositoryProvider)
                                  .deleteResult(ex.id);
                            }
                          }

                          for (final slotIdx in assignedSlots) {
                            final slot = _prizeSlots![slotIdx];
                            final student = allStudents
                                .where((s) => s.id == slot.studentId)
                                .firstOrNull;
                            if (student == null) continue;

                            final pos = slot.position;
                            final grade =
                                slot.gradeController.text.trim().toUpperCase();
                            final marks = double.tryParse(
                                  slot.marksController.text.trim(),
                                ) ??
                                80.0;
                            final pts = scoring.calculateResultPoints(
                              position: pos > 0 ? pos : null,
                              grade: grade,
                            );

                            final existing = allExistingResults
                                .where((r) => r.studentId == student.id)
                                .firstOrNull;

                            final result = Result(
                              id: existing?.id ?? 'res_${const Uuid().v4()}',
                              programId: program.id,
                              studentId: student.id,
                              teamId: student.teamId,
                              juryId: juryId,
                              marks: marks,
                              grade: grade,
                              position: pos > 0 ? pos : null,
                              points: pts,
                              remarks: slot.isTieSlot && pos > 0
                                  ? 'Shared / Tie Position $pos awarded by Jury (Draft)'
                                  : 'Awarded by Jury ($pos Place - Draft)',
                              status: ResultStatus.draft,
                              publishedAt: null,
                            );
                            await ref
                                .read(resultRepositoryProvider)
                                .saveResult(result);
                          }

                          // Safely recalculate team scores and ranks (only affects published results)
                          try {
                            await scoring.recalculateTeamScoresAndRanks();
                          } catch (_) {}

                          triggerDataRefresh(ref);

                          if (!mounted) return;
                          setState(() {
                            _isSubmitting = false;
                            _selectedProgram = null;
                            _prizeSlots = null;
                            _currentProgramIdForSlots = null;
                          });

                          final isController = ref
                                  .read(authServiceProvider)
                                  .currentUser
                                  ?.role ==
                              UserRole.festController;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Results for "${program.programName}" submitted as Draft to Controller successfully!',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                              action: isController
                                  ? SnackBarAction(
                                      label: 'View in Controller',
                                      textColor: Colors.white,
                                      onPressed: () => context.go('/controller'),
                                    )
                                  : null,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error submitting draft: ${e.toString().replaceAll("Exception: ", "")}',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
