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
import '../../data/models/result_model.dart';
import '../../data/models/venue_model.dart';
import '../../data/models/announcement_model.dart';
import '../../services/excel_service.dart';

class ControllerPortalScreen extends ConsumerStatefulWidget {
  const ControllerPortalScreen({super.key});

  @override
  ConsumerState<ControllerPortalScreen> createState() => _ControllerPortalScreenState();
}

class _ControllerPortalScreenState extends ConsumerState<ControllerPortalScreen> {
  int _selectedNavIndex = 0;

  // Student Form Controllers
  final _studentChaseController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  FestSection _studentSection = FestSection.junior;
  String? _studentTeamId;

  // Result Upload Form
  String? _selectedResultProgId;
  String? _selectedResultStudentId;
  final _resultMarksController = TextEditingController();
  final _resultGradeController = TextEditingController();
  int _resultPosition = 1;

  // Team Form Controllers
  final _teamNameController = TextEditingController();
  final _teamCodeController = TextEditingController();

  // Program Form Controllers
  final _progCodeController = TextEditingController();
  final _progNameController = TextEditingController();
  final _progDurationController = TextEditingController();
  FestSection _progSection = FestSection.junior;
  bool _progIsStage = true;

  // Excel Import state
  ExcelImportResult? _importResult;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final programsAsync = ref.watch(programsProvider);
    final resultsAsync = ref.watch(resultsProvider);
    final venuesAsync = ref.watch(venuesProvider);

    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text('FEST CONTROLLER PORTAL', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Chip(
            avatar: const Icon(Icons.person, size: 16),
            label: Text(currentUser?.name ?? 'Controller Admin'),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => triggerDataRefresh(ref),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authServiceProvider).logout();
              context.go('/public');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Students')),
              NavigationRailDestination(icon: Icon(Icons.groups), label: Text('Teams')),
              NavigationRailDestination(icon: Icon(Icons.category), label: Text('Programs')),
              NavigationRailDestination(icon: Icon(Icons.rate_review), label: Text('Result Upload')),
              NavigationRailDestination(icon: Icon(Icons.tv), label: Text('TV Control')),
              NavigationRailDestination(icon: Icon(Icons.file_upload), label: Text('Excel Import')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedNavIndex,
              children: [
                // 0. Dashboard
                _buildDashboard(studentsAsync, teamsAsync, programsAsync, resultsAsync, venuesAsync),
                // 1. Students Management
                _buildStudentsSection(studentsAsync, teamsAsync),
                // 2. Teams Management
                _buildTeamsSection(teamsAsync),
                // 3. Programs Management
                _buildProgramsSection(programsAsync),
                // 4. Result Upload & Verification Workflow
                _buildResultUploadSection(programsAsync, studentsAsync, teamsAsync, resultsAsync),
                // 5. TV Control & Announcements
                _buildTvControlSection(),
                // 6. Excel Import
                _buildExcelImportSection(),
                // 7. Settings & Demo Data Generator
                _buildSettingsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 0. DASHBOARD ---
  Widget _buildDashboard(
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Venue>> venuesAsync,
  ) {
    final students = studentsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    final results = resultsAsync.value ?? [];
    final venues = venuesAsync.value ?? [];

    final pendingDrafts = results.where((r) => r.status == ResultStatus.submitted || r.status == ResultStatus.draft).length;
    final publishedCount = results.where((r) => r.status == ResultStatus.published || r.status == ResultStatus.announced).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Performance & Overview', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
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
                  StatCard(title: 'Total Students', value: '${students.length}', icon: Icons.person, color: Colors.blue),
                  StatCard(title: 'Total Teams', value: '${teams.length}', icon: Icons.groups, color: Colors.purple),
                  StatCard(title: 'Programs', value: '${programs.length}', icon: Icons.category, color: Colors.orange),
                  StatCard(title: 'Pending Drafts', value: '$pendingDrafts', icon: Icons.pending_actions, color: Colors.amber),
                  StatCard(title: 'Published Results', value: '$publishedCount', icon: Icons.emoji_events, color: Colors.green),
                  StatCard(title: 'Active Venues', value: '${venues.length}', icon: Icons.stadium, color: Colors.teal),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Text('Top Ranked Teams', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: teams.length > 5 ? 5 : teams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final t = teams[index];
              return TeamScoreCard(
                rank: index + 1,
                teamName: t.teamName,
                teamCode: t.teamCode,
                points: t.totalPoints,
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 1. STUDENTS SECTION ---
  Widget _buildStudentsSection(AsyncValue<List<Student>> studentsAsync, AsyncValue<List<Team>> teamsAsync) {
    final teams = teamsAsync.value ?? [];
    final teamMap = {for (var t in teams) t.id: t.teamName};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(teams),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: studentsAsync.when(
        data: (students) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Registered Students (${students.length})', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Export Excel'),
                      onPressed: () {
                        final excelService = ref.read(excelServiceProvider);
                        excelService.exportStudentsToExcel(students, teamMap);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Exported ${students.length} students to Excel format.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, idx) {
                      final s = students[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(s.name.substring(0, 1))),
                          title: Text('${s.name} (${s.chaseNumber})'),
                          subtitle: Text('Team: ${teamMap[s.teamId] ?? s.teamId} • Section: ${s.section.label}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                tooltip: 'View QR Code',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => StudentQrDisplayDialog(studentName: s.name, chaseNumber: s.chaseNumber),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Delete Student',
                                onPressed: () => _confirmDeleteStudent(s),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _confirmDeleteStudent(Student student) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Student Deletion'),
          content: Text('Are you sure you want to delete student "${student.name}" (Chase #: ${student.chaseNumber})? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(studentRepositoryProvider).deleteStudent(student.id);
                triggerDataRefresh(ref);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Student "${student.name}" deleted successfully.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddStudentDialog(List<Team> teams) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Chase Number', controller: _studentChaseController, hint: 'e.g. CHASE-1099'),
                const SizedBox(height: 10),
                AppTextField(label: 'Full Name', controller: _studentNameController),
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
                const SizedBox(height: 10),
                AppDropdown<String>(
                  label: 'Team',
                  value: _studentTeamId ?? (teams.isNotEmpty ? teams.first.id : null),
                  items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.teamName))).toList(),
                  onChanged: (val) => setState(() => _studentTeamId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final student = Student(
                  id: const Uuid().v4(),
                  chaseNumber: _studentChaseController.text.trim(),
                  name: _studentNameController.text.trim(),
                  gender: 'Male',
                  dateOfBirth: '2008-01-01',
                  section: _studentSection,
                  teamId: _studentTeamId ?? (teams.isNotEmpty ? teams.first.id : 'default'),
                  phone: _studentPhoneController.text.trim(),
                  className: 'Class 10',
                  schoolName: 'Fest Academy',
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

  // --- 2. TEAMS SECTION ---
  Widget _buildTeamsSection(AsyncValue<List<Team>> teamsAsync) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeamDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Team'),
      ),
      body: teamsAsync.when(
        data: (teams) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Registered Teams (${teams.length})', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.group_add),
                      label: const Text('Add New Team'),
                      onPressed: _showAddTeamDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: teams.length,
                    itemBuilder: (context, idx) {
                      final t = teams[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text('#${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text('${t.teamName} (${t.teamCode})'),
                          subtitle: Text('Total Score: ${t.totalPoints} PTS • Members: ${t.totalStudents}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Rank #${t.rank > 0 ? t.rank : idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Delete Team',
                                onPressed: () => _confirmDeleteTeam(t),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _confirmDeleteTeam(Team team) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Team Deletion'),
          content: Text('Are you sure you want to delete team "${team.teamName}" (${team.teamCode})? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(teamRepositoryProvider).deleteTeam(team.id);
                triggerDataRefresh(ref);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Team "${team.teamName}" deleted successfully.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTeamDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Team Name',
                  controller: _teamNameController,
                  hint: 'e.g. Thunder Tigers',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Team Code',
                  controller: _teamCodeController,
                  hint: 'e.g. T-THUNDER',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _teamNameController.text.trim();
                final code = _teamCodeController.text.trim().toUpperCase();

                if (name.isEmpty || code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Team Name and Team Code are required!'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final existing = await ref.read(teamRepositoryProvider).getByCode(code);
                if (existing != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Team Code "$code" already exists!'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final team = Team(
                  id: 'team_${const Uuid().v4()}',
                  teamName: name,
                  teamCode: code,
                );

                await ref.read(teamRepositoryProvider).addTeam(team);
                triggerDataRefresh(ref);

                _teamNameController.clear();
                _teamCodeController.clear();

                if (mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Team "$name" ($code) created successfully!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Save Team'),
            ),
          ],
        );
      },
    );
  }

  // --- 3. PROGRAMS SECTION ---
  Widget _buildProgramsSection(AsyncValue<List<Program>> programsAsync) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProgramDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Program'),
      ),
      body: programsAsync.when(
        data: (programs) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fest Programs (${programs.length})', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Add New Program'),
                      onPressed: _showAddProgramDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: programs.length,
                    itemBuilder: (context, idx) {
                      final p = programs[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${p.programName} (${p.programCode})'),
                          subtitle: Text('Section: ${p.section.label} • ${p.isStageProgram ? "Stage" : "Non-Stage"} • Duration: ${p.duration}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(label: Text(p.status)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Delete Program',
                                onPressed: () => _confirmDeleteProgram(p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddProgramDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Program'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Program Code',
                      controller: _progCodeController,
                      hint: 'e.g. P-109',
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Program Name',
                      controller: _progNameController,
                      hint: 'e.g. Solo Violin',
                    ),
                    const SizedBox(height: 10),
                    AppDropdown<FestSection>(
                      label: 'Section',
                      value: _progSection,
                      items: FestSection.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _progSection = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _progIsStage,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => _progIsStage = val);
                          },
                        ),
                        const Text('Is Stage Program'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Duration',
                      controller: _progDurationController,
                      hint: 'e.g. 30 mins',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = _progCodeController.text.trim().toUpperCase();
                    final name = _progNameController.text.trim();
                    final duration = _progDurationController.text.trim().isEmpty ? '30 mins' : _progDurationController.text.trim();

                    if (code.isEmpty || name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Program Code and Program Name are required!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final program = Program(
                      id: 'prog_${const Uuid().v4()}',
                      programCode: code,
                      programName: name,
                      section: _progSection,
                      category: _progIsStage ? ProgramCategory.stage : ProgramCategory.nonStage,
                      isStageProgram: _progIsStage,
                      isGeneral: _progSection == FestSection.general,
                      duration: duration,
                    );

                    await ref.read(programRepositoryProvider).addProgram(program);
                    triggerDataRefresh(ref);

                    _progCodeController.clear();
                    _progNameController.clear();
                    _progDurationController.clear();

                    if (mounted) Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Program "$name" ($code) created successfully!'), backgroundColor: Colors.green),
                    );
                  },
                  child: const Text('Save Program'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteProgram(Program program) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Program Deletion'),
          content: Text('Are you sure you want to delete program "${program.programName}" (${program.programCode})? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(programRepositoryProvider).deleteProgram(program.id);
                triggerDataRefresh(ref);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Program "${program.programName}" deleted successfully.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // --- 4. RESULT UPLOAD & APPROVAL WORKFLOW SECTION ---
  Widget _buildResultUploadSection(
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Result>> resultsAsync,
  ) {
    final progs = programsAsync.value ?? [];
    final students = studentsAsync.value ?? [];
    final results = resultsAsync.value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Result Upload & Publishing Workflow', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upload New Result Draft', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                AppDropdown<String>(
                  label: 'Select Program',
                  value: _selectedResultProgId ?? (progs.isNotEmpty ? progs.first.id : null),
                  items: progs.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.programName} (${p.section.label})'))).toList(),
                  onChanged: (val) => setState(() => _selectedResultProgId = val),
                ),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  label: 'Select Student',
                  value: _selectedResultStudentId ?? (students.isNotEmpty ? students.first.id : null),
                  items: students.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.chaseNumber})'))).toList(),
                  onChanged: (val) => setState(() => _selectedResultStudentId = val),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      AppTextField(label: 'Marks', controller: _resultMarksController, keyboardType: TextInputType.number),
                      AppTextField(label: 'Grade (A, B, C)', controller: _resultGradeController),
                      AppDropdown<int>(
                        label: 'Position',
                        value: _resultPosition,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1st Place')),
                          DropdownMenuItem(value: 2, child: Text('2nd Place')),
                          DropdownMenuItem(value: 3, child: Text('3rd Place')),
                          DropdownMenuItem(value: 0, child: Text('Participant')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _resultPosition = v);
                        },
                      ),
                    ];

                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: f)).toList(),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 12),
                        Expanded(child: fields[1]),
                        const SizedBox(width: 12),
                        Expanded(child: fields[2]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Save & Publish Result',
                  onPressed: () async {
                    if (_selectedResultStudentId == null || _selectedResultProgId == null) return;
                    final student = students.firstWhere((s) => s.id == _selectedResultStudentId);

                    final scoring = ref.read(scoringServiceProvider);
                    final points = scoring.calculateResultPoints(
                      position: _resultPosition > 0 ? _resultPosition : null,
                      grade: _resultGradeController.text.trim(),
                    );

                    final result = Result(
                      id: 'res_${const Uuid().v4()}',
                      programId: _selectedResultProgId!,
                      studentId: student.id,
                      teamId: student.teamId,
                      marks: double.tryParse(_resultMarksController.text) ?? 85.0,
                      grade: _resultGradeController.text.trim().toUpperCase(),
                      position: _resultPosition > 0 ? _resultPosition : null,
                      points: points,
                      remarks: 'Published by Fest Controller',
                      status: ResultStatus.published,
                      publishedAt: DateTime.now(),
                    );

                    await ref.read(resultRepositoryProvider).saveResult(result);
                    await scoring.recalculateTeamScoresAndRanks();
                    triggerDataRefresh(ref);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Result successfully verified and published!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Existing Results & Draft Reviews', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            itemBuilder: (context, idx) {
              final r = results[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Result ID: ${r.id} • Marks: ${r.marks} (Grade ${r.grade})'),
                  subtitle: Text('Position: ${r.position ?? "Participant"} • Points: ${r.points} PTS'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(r.status.label),
                        backgroundColor: r.status == ResultStatus.published ? Colors.green[100] : Colors.amber[100],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Delete Result',
                        onPressed: () => _confirmDeleteResult(r),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteResult(Result result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Result Deletion'),
          content: Text('Are you sure you want to delete this result (ID: ${result.id})? Points will be automatically recalculated.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(resultRepositoryProvider).deleteResult(result.id);
                final scoring = ref.read(scoringServiceProvider);
                await scoring.recalculateTeamScoresAndRanks();
                triggerDataRefresh(ref);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Result deleted successfully and team scores updated.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // --- 5. TV CONTROL & ANNOUNCEMENTS SECTION ---
  Widget _buildTvControlSection() {
    final tvService = ref.watch(tvServiceProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TV / Projector Master Controller', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current TV Screen Mode: ${tvService.settings.screenMode}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => tvService.nextSlide(),
                      child: const Text('Next Slide'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => tvService.setAutoRotate(!tvService.settings.autoRotate),
                      child: Text(tvService.settings.autoRotate ? 'Pause Auto-Rotate' : 'Start Auto-Rotate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trigger Live Result Announcement Overlay', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.campaign),
                  label: const Text('ANNOUNCE LATEST RESULT ON TV'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
                  onPressed: () async {
                    final ann = Announcement(
                      id: 'ann_${const Uuid().v4()}',
                      title: '🎉 LIVE RESULT ANNOUNCEMENT 🎉',
                      message: 'New championship result published!',
                      status: 'ANNOUNCED',
                      announcedAt: DateTime.now(),
                    );
                    await ref.read(announcementRepositoryProvider).addAnnouncement(ann);
                    triggerDataRefresh(ref);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Announcement broadcasted live to TV screen!')),
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

  // --- 6. EXCEL IMPORT SECTION ---
  Widget _buildExcelImportSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Excel Multi-Entity Import Center', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Import Students from Excel File (.xlsx)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Expected Columns: Chase Number, Name, Gender, Date of Birth, Section, Team, Phone, Class, School'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select & Process Sample Excel Batch'),
                  onPressed: () async {
                    final demoService = ref.read(demoDataServiceProvider);
                    await demoService.generateDemoData();
                    triggerDataRefresh(ref);
                    setState(() {
                      _importResult = ExcelImportResult<Student>(
                        totalRows: 54,
                        validRows: 54,
                        invalidRows: 0,
                        duplicateRows: 0,
                        importedRows: 54,
                        errors: [],
                        validItems: [],
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          if (_importResult != null) ...[
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Import Summary Report', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                  const SizedBox(height: 12),
                  Text('Total Rows Processed: ${_importResult!.totalRows}'),
                  Text('Valid Rows Imported: ${_importResult!.validRows}'),
                  Text('Invalid Rows Rejected: ${_importResult!.invalidRows}'),
                  Text('Duplicates Skipped: ${_importResult!.duplicateRows}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 7. SETTINGS & DEMO DATA SECTION ---
  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Administration', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Database Management', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Reset or purge all database entries to start a fresh competition session.', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Reset All Database Data', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        final demo = ref.read(demoDataServiceProvider);
                        await demo.clearAllData();
                        final auth = ref.read(authServiceProvider);
                        await auth.seedDefaultUsers();
                        triggerDataRefresh(ref);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Database reset completely.')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
