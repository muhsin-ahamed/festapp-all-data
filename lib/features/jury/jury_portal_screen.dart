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

class JuryPortalScreen extends ConsumerStatefulWidget {
  final String? targetProgramId;
  const JuryPortalScreen({super.key, this.targetProgramId});

  @override
  ConsumerState<JuryPortalScreen> createState() => _JuryPortalScreenState();
}

class _JuryPortalScreenState extends ConsumerState<JuryPortalScreen> {
  Program? _selectedProgram;
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _gradeControllers = {};
  final Map<String, int> _positions = {};

  bool _isScanningProgramQr = false;
  bool _hasInitialProgramSet = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final juriesAsync = ref.watch(juriesProvider);
    final programsAsync = ref.watch(programsProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final regsAsync = ref.watch(registrationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(size: 26),
            const SizedBox(width: 10),
            Text('JURY MARKING PORTAL', style: GoogleFonts.rye(fontSize: 18, color: AppTheme.ink)),
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
        error: (err, stack) => Center(child: Text('Error loading jury data: $err')),
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

          final currentJury = juries.where((j) => j.id == user?.juryId || j.username == user?.username).firstOrNull ?? juries.first;
          final assignedProgIds = currentJury.assignedPrograms;

          final allPrograms = programsAsync.value ?? [];
          final assignedPrograms = allPrograms.where((p) => assignedProgIds.contains(p.id)).toList();

          if (!_hasInitialProgramSet && widget.targetProgramId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final prog = assignedPrograms.where((p) => p.id == widget.targetProgramId).firstOrNull;
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
                  Text('Scan Program Jury QR Code', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  QRScannerWidget(
                    onScanned: (payload) {
                      final scanRes = QrService.parseQrPayload(payload);
                      String? searchProgramId = scanRes.value;
                      if (scanRes.type == QrScanType.juryLoginProgram) {
                        searchProgramId = scanRes.programId;
                      }
                      
                      final prog = allPrograms.where((p) => p.id == searchProgramId || p.programCode == searchProgramId).firstOrNull;
                      if (prog != null) {
                        setState(() {
                          _selectedProgram = prog;
                          _isScanningProgramQr = false;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Program "$searchProgramId" not found.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }

          if (_selectedProgram != null) {
            return _buildMarkingForm(_selectedProgram!, studentsAsync.value ?? [], regsAsync.value ?? [], currentJury.id);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned Programs for ${currentJury.name}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (assignedPrograms.isEmpty) ...[
                  const Text('No programs currently assigned to your jury account.'),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assignedPrograms.length,
                    itemBuilder: (context, idx) {
                      final p = assignedPrograms[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('${p.programName} (${p.programCode})'),
                          subtitle: Text('Section: ${p.section.label} • ${p.isStageProgram ? "Stage" : "Non-Stage"}'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedProgram = p;
                              });
                            },
                            child: const Text('Open Marking Paper'),
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

  Widget _buildMarkingForm(Program program, List<Student> allStudents, List<dynamic> allRegs, String juryId) {
    // Filter participants for this program
    final progRegs = allRegs.where((r) => r.programId == program.id).toList();
    final studentIds = progRegs.map((r) => r.studentId).toSet();
    final participants = allStudents.where((s) => studentIds.contains(s.id)).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedProgram = null),
        ),
        title: Text('Marking: ${program.programName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Student Marks & Positions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (participants.isEmpty) ...[
              const Text('No registered participants found for this program.'),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: participants.length,
                itemBuilder: (context, idx) {
                  final stud = participants[idx];
                  _marksControllers.putIfAbsent(stud.id, () => TextEditingController(text: '85'));
                  _gradeControllers.putIfAbsent(stud.id, () => TextEditingController(text: 'A'));
                  _positions.putIfAbsent(stud.id, () => idx + 1 <= 3 ? idx + 1 : 0);

                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${stud.name} (${stud.chaseNumber})', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 480;
                            final marksField = AppTextField(label: 'Marks', controller: _marksControllers[stud.id]!, keyboardType: TextInputType.number);
                            final gradeField = AppTextField(label: 'Grade', controller: _gradeControllers[stud.id]!);
                            final posDropdown = AppDropdown<int>(
                              label: 'Position',
                              value: _positions[stud.id],
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('1st Place')),
                                DropdownMenuItem(value: 2, child: Text('2nd Place')),
                                DropdownMenuItem(value: 3, child: Text('3rd Place')),
                                DropdownMenuItem(value: 0, child: Text('Participant')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _positions[stud.id] = v);
                              },
                            );

                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: marksField),
                                      const SizedBox(width: 10),
                                      Expanded(child: gradeField),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  posDropdown,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: marksField),
                                const SizedBox(width: 10),
                                Expanded(child: gradeField),
                                const SizedBox(width: 10),
                                Expanded(child: posDropdown),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Submit Final Results to Controller',
                width: double.infinity,
                onPressed: () async {
                  final scoring = ref.read(scoringServiceProvider);
                  for (final stud in participants) {
                    final pos = _positions[stud.id];
                    final grade = _gradeControllers[stud.id]!.text.trim();
                    final marks = double.tryParse(_marksControllers[stud.id]!.text) ?? 80.0;
                    final pts = scoring.calculateResultPoints(position: pos != null && pos > 0 ? pos : null, grade: grade);

                    final result = Result(
                      id: 'res_${const Uuid().v4()}',
                      programId: program.id,
                      studentId: stud.id,
                      teamId: stud.teamId,
                      juryId: juryId,
                      marks: marks,
                      grade: grade,
                      position: pos != null && pos > 0 ? pos : null,
                      points: pts,
                      remarks: 'Submitted by Jury',
                      status: ResultStatus.submitted,
                    );
                    await ref.read(resultRepositoryProvider).saveResult(result);
                  }

                  triggerDataRefresh(ref);
                  if (!mounted) return;
                  setState(() => _selectedProgram = null);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Jury results submitted successfully to Controller!'), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
