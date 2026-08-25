import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui_components.dart';
import '../../data/models/student_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/registration_model.dart';
import '../../data/models/result_model.dart';

class LeaderPortalScreen extends ConsumerStatefulWidget {
  const LeaderPortalScreen({super.key});

  @override
  ConsumerState<LeaderPortalScreen> createState() => _LeaderPortalScreenState();
}

class _LeaderPortalScreenState extends ConsumerState<LeaderPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _studentNameController = TextEditingController();
  final _studentChaseController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  FestSection _studentSection = FestSection.junior;

  String? _selectedStudentForReg;
  String? _selectedProgramForReg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentNameController.dispose();
    _studentChaseController.dispose();
    _studentPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final teamsAsync = ref.watch(teamsProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final programsAsync = ref.watch(programsProvider);
    final regsAsync = ref.watch(registrationsProvider);
    final resultsAsync = ref.watch(publishedResultsProvider);

    final teams = teamsAsync.value ?? [];
    final teamId = user?.teamId ?? (teams.isNotEmpty ? teams.first.id : '');
    final currentTeam = teams.firstWhere((t) => t.id == teamId, orElse: () => Team(id: teamId, teamName: 'My Team', teamCode: 'MY-TEAM'));

    final allStudents = studentsAsync.value ?? [];
    final myStudents = allStudents.where((s) => s.teamId == teamId).toList();
    final allPrograms = programsAsync.value ?? [];
    final allRegs = regsAsync.value ?? [];
    final myRegs = allRegs.where((r) => r.teamId == teamId).toList();
    final publishedResults = resultsAsync.value ?? [];
    final myResults = publishedResults.where((r) => r.teamId == teamId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.group, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text('${currentTeam.teamName} Leader Portal', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => triggerDataRefresh(ref),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              ref.read(authServiceProvider).logout();
              context.go('/public');
            },
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.person_add), text: 'Team Students'),
            Tab(icon: Icon(Icons.app_registration), text: 'Program Registration'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Team Results'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 0. Dashboard
          _buildDashboard(currentTeam, myStudents, myRegs, myResults),
          // 1. Team Students & Add
          _buildStudentsTab(myStudents, teamId),
          // 2. Program Registration with Limits Enforcement
          _buildRegistrationTab(myStudents, allPrograms, allRegs, teamId),
          // 3. Team Results
          _buildTeamResultsTab(myResults, allPrograms, allStudents),
        ],
      ),
    );
  }

  // --- 0. DASHBOARD ---
  Widget _buildDashboard(Team team, List<Student> students, List<Registration> regs, List<Result> results) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, Leader of ${team.teamName} (${team.teamCode})', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  mainAxisExtent: 100,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                children: [
                  StatCard(title: 'Total Students', value: '${students.length}', icon: Icons.people, color: Colors.blue),
                  StatCard(title: 'Approved Registrations', value: '${regs.length}', icon: Icons.how_to_reg, color: Colors.green),
                  StatCard(title: 'Team Total Score', value: '${team.totalPoints} PTS', icon: Icons.stars, color: Colors.amber),
                  StatCard(title: 'Current Rank', value: '#${team.rank > 0 ? team.rank : "-"}', icon: Icons.military_tech, color: Colors.purple),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 1. TEAM STUDENTS ---
  Widget _buildStudentsTab(List<Student> myStudents, String teamId) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Team Student'),
        onPressed: () => _showAddStudentDialog(teamId),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Team Members (${myStudents.length})', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: myStudents.length,
                itemBuilder: (context, idx) {
                  final s = myStudents[idx];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(s.name.substring(0, 1))),
                      title: Text('${s.name} (${s.chaseNumber})'),
                      subtitle: Text('Section: ${s.section.label} • Class: ${s.className}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.qr_code),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => StudentQrDisplayDialog(studentName: s.name, chaseNumber: s.chaseNumber),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog(String teamId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Student to Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Chase Number', controller: _studentChaseController, hint: 'e.g. CHASE-1088'),
              const SizedBox(height: 10),
              AppTextField(label: 'Student Name', controller: _studentNameController),
              const SizedBox(height: 10),
              AppTextField(label: 'Phone', controller: _studentPhoneController),
              const SizedBox(height: 10),
              AppDropdown<FestSection>(
                label: 'Section',
                value: _studentSection,
                items: FestSection.values
                    .where((s) => s != FestSection.general)
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _studentSection = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final student = Student(
                  id: 'stud_${const Uuid().v4()}',
                  chaseNumber: _studentChaseController.text.trim(),
                  name: _studentNameController.text.trim(),
                  gender: 'Male',
                  dateOfBirth: '2008-01-01',
                  section: _studentSection,
                  teamId: teamId,
                  phone: _studentPhoneController.text.trim(),
                  className: 'Class 10',
                  schoolName: 'Team Academy',
                  qrCode: _studentChaseController.text.trim(),
                );
                await ref.read(studentRepositoryProvider).addStudent(student);
                triggerDataRefresh(ref);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- 2. PROGRAM REGISTRATION TAB WITH STRICT LIMIT ENFORCEMENT ---
  Widget _buildRegistrationTab(
    List<Student> myStudents,
    List<Program> allPrograms,
    List<Registration> allRegs,
    String teamId,
  ) {
    // Current student calculation
    Student? activeStudent;
    if (_selectedStudentForReg != null) {
      activeStudent = myStudents.firstWhere((s) => s.id == _selectedStudentForReg, orElse: () => myStudents.first);
    } else if (myStudents.isNotEmpty) {
      activeStudent = myStudents.first;
    }

    int nonStageUsed = 0;
    int stageUsed = 0;

    if (activeStudent != null) {
      final studentRegs = allRegs.where((r) => r.studentId == activeStudent!.id).toList();
      for (final reg in studentRegs) {
        final prog = allPrograms.firstWhere((p) => p.id == reg.programId, orElse: () => Program(id: '', programCode: '', programName: '', section: FestSection.junior, category: ProgramCategory.stage, isStageProgram: true, isGeneral: false));
        if (!prog.isGeneral) {
          if (prog.isStageProgram) {
            stageUsed++;
          } else {
            nonStageUsed++;
          }
        }
      }
    }

    final remainingNonStage = AppConstants.maxNonStagePerStudent - nonStageUsed;
    final remainingStage = AppConstants.maxStagePerStudent - stageUsed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Student Program Registration', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppDropdown<String>(
                  label: 'Select Student',
                  value: activeStudent?.id,
                  items: myStudents.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.chaseNumber}) - ${s.section.label}'))).toList(),
                  onChanged: (val) => setState(() => _selectedStudentForReg = val),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Non-Stage Slot Usage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$nonStageUsed / ${AppConstants.maxNonStagePerStudent}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          Text('Remaining: $remainingNonStage', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Stage Slot Usage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$stageUsed / ${AppConstants.maxStagePerStudent}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                          Text('Remaining: $remainingStage', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppDropdown<String>(
                  label: 'Select Program to Apply',
                  value: _selectedProgramForReg ?? (allPrograms.isNotEmpty ? allPrograms.first.id : null),
                  items: allPrograms.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.programName} (${p.section.label}) [${p.isStageProgram ? "Stage" : "Non-Stage"}]'))).toList(),
                  onChanged: (val) => setState(() => _selectedProgramForReg = val),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Register Student for Program',
                  onPressed: () async {
                    if (activeStudent == null || _selectedProgramForReg == null) return;
                    final targetProg = allPrograms.firstWhere((p) => p.id == _selectedProgramForReg);

                    // 1. Check duplicate registration
                    final isDuplicate = allRegs.any((r) => r.studentId == activeStudent!.id && r.programId == targetProg.id);
                    if (isDuplicate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Student is already registered for this program!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // 2. Validate section
                    if (!targetProg.isGeneral && targetProg.section != activeStudent.section) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Section mismatch! ${activeStudent.name} is in ${activeStudent.section.label}, but program is in ${targetProg.section.label}.'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // 3. Enforce slot limits
                    if (!targetProg.isGeneral) {
                      if (targetProg.isStageProgram && remainingStage <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Stage program limit reached (Max 3 stage programs allowed)!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (!targetProg.isStageProgram && remainingNonStage <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Non-stage program limit reached (Max 4 non-stage programs allowed)!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                    }

                    // Create registration
                    final reg = Registration(
                      id: 'reg_${const Uuid().v4()}',
                      studentId: activeStudent.id,
                      programId: targetProg.id,
                      teamId: teamId,
                      registrationNumber: 'REG-${10000 + allRegs.length + 1}',
                      status: RegistrationStatus.approved,
                    );

                    await ref.read(registrationRepositoryProvider).addRegistration(reg);
                    triggerDataRefresh(ref);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully registered ${activeStudent.name} for ${targetProg.programName}!'), backgroundColor: Colors.green),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. TEAM RESULTS ---
  Widget _buildTeamResultsTab(List<Result> myResults, List<Program> allPrograms, List<Student> allStudents) {
    final progMap = {for (var p in allPrograms) p.id: p.programName};
    final studMap = {for (var s in allStudents) s.id: s.name};

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Published Team Results (${myResults.length})', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: myResults.length,
              itemBuilder: (context, idx) {
                final r = myResults[idx];
                return Card(
                  child: ListTile(
                    title: Text('${progMap[r.programId] ?? "Program"} - ${studMap[r.studentId] ?? "Student"}'),
                    subtitle: Text('Grade: ${r.grade} • Marks: ${r.marks}'),
                    trailing: Text('+${r.points} PTS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
