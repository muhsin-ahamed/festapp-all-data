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
import '../../data/models/team_leader_model.dart';
import '../../data/models/jury_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/result_model.dart';
import '../../data/models/venue_model.dart';
import '../../data/models/announcement_model.dart';
import '../../data/models/user_model.dart';
import 'package:file_picker/file_picker.dart';
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
  final _teamLeaderNameController = TextEditingController();

  // Program Form Controllers
  final _progCodeController = TextEditingController();
  final _progNameController = TextEditingController();
  final _progDurationController = TextEditingController();
  FestSection _progSection = FestSection.junior;
  bool _progIsStage = true;

  // Excel Import state
  ExcelImportResult? _importResult;

  // User Account Management state
  final Set<String> _visiblePasswords = {};
  final _userLoginNameController = TextEditingController();
  final _userUsernameController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _userJuryCodeController = TextEditingController();
  String? _selectedLeaderTeamId;
  List<String> _selectedJuryProgramIds = [];

  @override
  void dispose() {
    _studentChaseController.dispose();
    _studentNameController.dispose();
    _studentPhoneController.dispose();
    _resultMarksController.dispose();
    _resultGradeController.dispose();
    _teamNameController.dispose();
    _teamCodeController.dispose();
    _teamLeaderNameController.dispose();
    _progCodeController.dispose();
    _progNameController.dispose();
    _progDurationController.dispose();
    _userLoginNameController.dispose();
    _userUsernameController.dispose();
    _userPasswordController.dispose();
    _userPhoneController.dispose();
    _userEmailController.dispose();
    _userJuryCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final programsAsync = ref.watch(programsProvider);
    final resultsAsync = ref.watch(resultsProvider);
    final venuesAsync = ref.watch(venuesProvider);
    final usersAsync = ref.watch(usersProvider);
    final leadersAsync = ref.watch(leadersProvider);
    final juriesAsync = ref.watch(juriesProvider);

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
              NavigationRailDestination(icon: Icon(Icons.manage_accounts), label: Text('User Logins')),
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
                // 7. User Logins Management (Team Leaders & Jury)
                _buildUserManagementSection(usersAsync, leadersAsync, juriesAsync, teamsAsync, programsAsync),
                // 8. Settings & Demo Data Generator
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Import Students (Excel)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _importStudentsFromExcel,
                        ),
                        OutlinedButton.icon(
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

  Future<void> _importStudentsFromExcel() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (files.isNotEmpty) {
        final bytes = await files.first.readAsBytes();
        final excelService = ref.read(excelServiceProvider);
        final importResult = await excelService.importStudents(bytes);
        triggerDataRefresh(ref);

        if (mounted) {
          _showImportResultDialog('Students Excel Import Summary', importResult);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import Excel file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImportResultDialog(String title, ExcelImportResult result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.analytics, color: Colors.blue),
                  title: const Text('Total Rows Processed'),
                  trailing: Text('${result.totalRows}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Successfully Imported'),
                  trailing: Text('${result.importedRows}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ),
                if (result.duplicateRows > 0)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.copy, color: Colors.orange),
                    title: const Text('Duplicates Skipped'),
                    trailing: Text('${result.duplicateRows}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ),
                if (result.invalidRows > 0)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Invalid / Failed Rows'),
                    trailing: Text('${result.invalidRows}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                if (result.errors.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Error Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: result.errors.map((err) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text('• $err', style: const TextStyle(fontSize: 12, color: Colors.red)),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
                          subtitle: Text('Leader: ${t.leaderName ?? 'N/A'} • Score: ${t.totalPoints} PTS • Members: ${t.totalStudents}'),
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
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Leader Name',
                  controller: _teamLeaderNameController,
                  hint: 'e.g. John Doe',
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
                final inputLeaderName = _teamLeaderNameController.text.trim();

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

                final teamId = 'team_${const Uuid().v4()}';
                final leaderName = inputLeaderName.isNotEmpty ? inputLeaderName : '$name Leader';
                final cleanUser = (inputLeaderName.isNotEmpty ? inputLeaderName : name).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                final leaderUsername = cleanUser.isEmpty ? 'team_${code.toLowerCase()}' : cleanUser;
                final leaderPassword = '${leaderUsername}123';
                final leaderId = 'leader_$teamId';

                final team = Team(
                  id: teamId,
                  teamName: name,
                  teamCode: code,
                  leaderId: leaderId,
                  leaderName: leaderName,
                );

                await ref.read(teamRepositoryProvider).addTeam(team);

                // Create Team Leader profile
                final leaderProfile = TeamLeader(
                  id: leaderId,
                  name: leaderName,
                  phone: '',
                  email: '',
                  username: leaderUsername,
                  password: leaderPassword,
                  teamId: teamId,
                );
                await ref.read(leaderRepositoryProvider).addLeader(leaderProfile);

                // Auto-generate Team Leader user login
                final leaderUser = User(
                  id: 'usr_leader_$teamId',
                  username: leaderUsername,
                  password: leaderPassword,
                  name: leaderName,
                  role: UserRole.teamLeader,
                  teamId: teamId,
                );
                await ref.read(userRepositoryProvider).saveUser(leaderUser);

                triggerDataRefresh(ref);

                _teamNameController.clear();
                _teamCodeController.clear();
                _teamLeaderNameController.clear();

                if (mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Team "$name" ($code) with Leader "$leaderName" created! User: $leaderUsername | Pass: $leaderPassword'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 5),
                  ),
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

  // --- 7. USER LOGINS MANAGEMENT SECTION ---
  Widget _buildUserManagementSection(
    AsyncValue<List<User>> usersAsync,
    AsyncValue<List<TeamLeader>> leadersAsync,
    AsyncValue<List<Jury>> juriesAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Program>> programsAsync,
  ) {
    final users = usersAsync.value ?? [];
    final leaders = leadersAsync.value ?? [];
    final juries = juriesAsync.value ?? [];
    final teams = teamsAsync.value ?? [];
    final programs = programsAsync.value ?? [];

    final teamMap = {for (var t in teams) t.id: t};
    final leaderUsers = users.where((u) => u.role == UserRole.teamLeader).toList();
    final juryUsers = users.where((u) => u.role == UserRole.jury).toList();

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Credentials & Access Control', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Create and manage Login IDs & Passwords for Team Leaders and Jury members', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Team Leader Login'),
                      onPressed: () => _showAddEditTeamLeaderDialog(teams: teams),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.assignment_ind),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                      label: const Text('Add Jury Login'),
                      onPressed: () => _showAddEditJuryDialog(programs: programs),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.groups), text: 'Team Leader Logins'),
                Tab(icon: Icon(Icons.rate_review), text: 'Jury Logins'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Team Leader Logins
                  _buildTeamLeadersList(leaderUsers, leaders, teamMap, teams),
                  // Tab 2: Jury Logins
                  _buildJuriesList(juryUsers, juries, programs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLeadersList(List<User> leaderUsers, List<TeamLeader> leaders, Map<String, Team> teamMap, List<Team> teams) {
    if (leaderUsers.isEmpty && leaders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No Team Leader user accounts created yet.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Team Leader Account'),
              onPressed: () => _showAddEditTeamLeaderDialog(teams: teams),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: leaderUsers.length,
      itemBuilder: (context, index) {
        final u = leaderUsers[index];
        final team = u.teamId != null ? teamMap[u.teamId] : null;
        final leaderProfile = leaders.firstWhere(
          (l) => l.teamId == u.teamId || l.username == u.username,
          orElse: () => TeamLeader(id: '', name: u.name, phone: '', email: '', username: u.username, password: u.password, teamId: u.teamId ?? ''),
        );
        final isPasswordVisible = _visiblePasswords.contains(u.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            avatar: const Icon(Icons.shield, size: 14, color: Colors.indigo),
                            label: Text(team != null ? '${team.teamName} (${team.teamCode})' : 'Unassigned Team', style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          if (leaderProfile.phone.isNotEmpty)
                            Text('📞 ${leaderProfile.phone}  ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          if (leaderProfile.email.isNotEmpty)
                            Text('✉️ ${leaderProfile.email}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Credentials Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_circle, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Login ID: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          SelectableText(u.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.key, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Password: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          SelectableText(
                            isPasswordVisible ? u.password : '••••••••',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: isPasswordVisible ? null : 'monospace', color: Colors.blue[900]),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isPasswordVisible) {
                                  _visiblePasswords.remove(u.id);
                                } else {
                                  _visiblePasswords.add(u.id);
                                }
                              });
                            },
                            child: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 16, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Login & Password',
                      onPressed: () => _showAddEditTeamLeaderDialog(teams: teams, existingUser: u, existingLeader: leaderProfile),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Delete User Account',
                      onPressed: () => _confirmDeleteUser(u, leaderProfile.id, isJury: false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJuriesList(List<User> juryUsers, List<Jury> juries, List<Program> programs) {
    final juryMap = {for (var j in juries) j.id: j};

    if (juryUsers.isEmpty && juries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gavel, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No Jury user accounts created yet.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Jury Account'),
              onPressed: () => _showAddEditJuryDialog(programs: programs),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: juryUsers.length,
      itemBuilder: (context, index) {
        final u = juryUsers[index];
        final juryProfile = u.juryId != null ? juryMap[u.juryId] : juries.firstWhere(
          (j) => j.username == u.username,
          orElse: () => Jury(id: '', name: u.name, username: u.username, password: u.password, juryCode: 'JURY-N/A', assignedPrograms: []),
        );
        final isPasswordVisible = _visiblePasswords.contains(u.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.rate_review, color: AppTheme.secondaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            avatar: const Icon(Icons.badge, size: 14, color: Colors.purple),
                            label: Text('Code: ${juryProfile?.juryCode ?? "JURY"}', style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            avatar: const Icon(Icons.assignment, size: 14, color: Colors.teal),
                            label: Text('${juryProfile?.assignedPrograms.length ?? 0} Programs Assigned', style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Credentials Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_circle, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Login ID: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          SelectableText(u.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.key, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Password: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          SelectableText(
                            isPasswordVisible ? u.password : '••••••••',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: isPasswordVisible ? null : 'monospace', color: Colors.blue[900]),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isPasswordVisible) {
                                  _visiblePasswords.remove(u.id);
                                } else {
                                  _visiblePasswords.add(u.id);
                                }
                              });
                            },
                            child: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 16, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Login & Password',
                      onPressed: () => _showAddEditJuryDialog(programs: programs, existingUser: u, existingJury: juryProfile),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Delete User Account',
                      onPressed: () => _confirmDeleteUser(u, juryProfile?.id ?? '', isJury: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEditTeamLeaderDialog({required List<Team> teams, User? existingUser, TeamLeader? existingLeader}) {
    final isEditing = existingUser != null;
    _userLoginNameController.text = existingUser?.name ?? existingLeader?.name ?? '';
    _userUsernameController.text = existingUser?.username ?? existingLeader?.username ?? '';
    _userPasswordController.text = existingUser?.password ?? existingLeader?.password ?? '';
    _userPhoneController.text = existingLeader?.phone ?? '';
    _userEmailController.text = existingLeader?.email ?? '';
    _selectedLeaderTeamId = existingUser?.teamId ?? existingLeader?.teamId ?? (teams.isNotEmpty ? teams.first.id : null);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Team Leader Login Credentials' : 'Create Team Leader Login ID & Password'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        label: 'Leader Full Name',
                        controller: _userLoginNameController,
                        hint: 'e.g. John Doe',
                      ),
                      const SizedBox(height: 12),
                      AppDropdown<String>(
                        label: 'Select Team',
                        value: _selectedLeaderTeamId,
                        items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.teamName} (${t.teamCode})'))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedLeaderTeamId = val),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Login ID (Username)',
                        controller: _userUsernameController,
                        hint: 'e.g. leader_alpha',
                        prefixIcon: Icons.account_circle_outlined,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Password',
                        controller: _userPasswordController,
                        hint: 'Set strong password',
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Phone (Optional)',
                        controller: _userPhoneController,
                        hint: 'e.g. +91 9876543210',
                        prefixIcon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Email (Optional)',
                        controller: _userEmailController,
                        hint: 'e.g. leader@fest.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = _userLoginNameController.text.trim();
                    final username = _userUsernameController.text.trim();
                    final password = _userPasswordController.text.trim();
                    final phone = _userPhoneController.text.trim();
                    final email = _userEmailController.text.trim();
                    final teamId = _selectedLeaderTeamId ?? '';

                    if (name.isEmpty || username.isEmpty || password.isEmpty || teamId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Leader Name, Team, Login ID, and Password are required!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (!isEditing || existingUser.username != username) {
                      final userRepo = ref.read(userRepositoryProvider);
                      final existing = await userRepo.getByUsername(username);
                      if (existing != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Login ID "$username" is already taken. Please use a unique Login ID.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                    }

                    final leaderId = existingLeader?.id.isNotEmpty == true ? existingLeader!.id : 'leader_${const Uuid().v4()}';
                    final userId = existingUser?.id.isNotEmpty == true ? existingUser!.id : 'usr_$leaderId';

                    final leader = TeamLeader(
                      id: leaderId,
                      name: name,
                      phone: phone,
                      email: email,
                      username: username,
                      password: password,
                      teamId: teamId,
                    );
                    await ref.read(leaderRepositoryProvider).addLeader(leader);

                    final user = User(
                      id: userId,
                      username: username,
                      password: password,
                      name: name,
                      role: UserRole.teamLeader,
                      teamId: teamId,
                    );
                    await ref.read(userRepositoryProvider).saveUser(user);

                    triggerDataRefresh(ref);
                    if (mounted) Navigator.pop(dialogContext);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Team Leader login credentials saved for "$name"! Login ID: $username'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEditJuryDialog({required List<Program> programs, User? existingUser, Jury? existingJury}) {
    final isEditing = existingUser != null;
    _userLoginNameController.text = existingUser?.name ?? existingJury?.name ?? '';
    _userJuryCodeController.text = existingJury?.juryCode ?? 'JURY-101';
    _userUsernameController.text = existingUser?.username ?? existingJury?.username ?? '';
    _userPasswordController.text = existingUser?.password ?? existingJury?.password ?? '';
    _selectedJuryProgramIds = List<String>.from(existingJury?.assignedPrograms ?? []);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Jury Member Login Credentials' : 'Create Jury Login ID & Password'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'Jury Judge Name',
                        controller: _userLoginNameController,
                        hint: 'e.g. Prof. Sarah Jenkins',
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Jury Code',
                        controller: _userJuryCodeController,
                        hint: 'e.g. JURY-101',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Login ID (Username)',
                        controller: _userUsernameController,
                        hint: 'e.g. jury_singing',
                        prefixIcon: Icons.account_circle_outlined,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Password',
                        controller: _userPasswordController,
                        hint: 'Set strong password',
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 16),
                      Text('Assigned Programs (${_selectedJuryProgramIds.length} selected):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: programs.length,
                          itemBuilder: (context, idx) {
                            final p = programs[idx];
                            final isChecked = _selectedJuryProgramIds.contains(p.id);
                            return CheckboxListTile(
                              dense: true,
                              title: Text('${p.programName} (${p.programCode})'),
                              subtitle: Text('${p.section.label} • ${p.isStageProgram ? "Stage" : "Non-Stage"}'),
                              value: isChecked,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    _selectedJuryProgramIds.add(p.id);
                                  } else {
                                    _selectedJuryProgramIds.remove(p.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = _userLoginNameController.text.trim();
                    final juryCode = _userJuryCodeController.text.trim().toUpperCase();
                    final username = _userUsernameController.text.trim();
                    final password = _userPasswordController.text.trim();

                    if (name.isEmpty || juryCode.isEmpty || username.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Jury Name, Jury Code, Login ID, and Password are required!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (!isEditing || existingUser.username != username) {
                      final userRepo = ref.read(userRepositoryProvider);
                      final existing = await userRepo.getByUsername(username);
                      if (existing != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Login ID "$username" is already taken. Please use a unique Login ID.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                    }

                    final juryId = existingJury?.id.isNotEmpty == true ? existingJury!.id : 'jury_${const Uuid().v4()}';
                    final userId = existingUser?.id.isNotEmpty == true ? existingUser!.id : 'usr_$juryId';

                    final jury = Jury(
                      id: juryId,
                      name: name,
                      username: username,
                      password: password,
                      juryCode: juryCode,
                      assignedPrograms: List<String>.from(_selectedJuryProgramIds),
                    );
                    await ref.read(juryRepositoryProvider).addJury(jury);

                    final user = User(
                      id: userId,
                      username: username,
                      password: password,
                      name: name,
                      role: UserRole.jury,
                      juryId: juryId,
                    );
                    await ref.read(userRepositoryProvider).saveUser(user);

                    triggerDataRefresh(ref);
                    if (mounted) Navigator.pop(dialogContext);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Jury credentials saved for "$name" ($juryCode)! Login ID: $username'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create Jury Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(User user, String modelId, {required bool isJury}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: Text('Are you sure you want to delete user account "${user.name}" (Login ID: ${user.username})? This user will no longer be able to log in.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(userRepositoryProvider).deleteUser(user.id);
                if (isJury) {
                  if (modelId.isNotEmpty) {
                    await ref.read(juryRepositoryProvider).deleteJury(modelId);
                  }
                } else {
                  if (modelId.isNotEmpty) {
                    await ref.read(leaderRepositoryProvider).deleteLeader(modelId);
                  }
                }
                triggerDataRefresh(ref);
                if (mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User account "${user.username}" deleted successfully.')),
                  );
                }
              },
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  // --- 8. SETTINGS & DEMO DATA SECTION ---
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
