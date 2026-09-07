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
import '../../data/models/schedule_model.dart';
import '../../data/models/registration_model.dart';
import '../../data/models/announcement_model.dart';
import '../../data/models/user_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../../services/excel_service.dart';
import '../../services/qr_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  FestSection _studentSection = FestSection.subJunior;
  String? _studentTeamId;

  // Result Upload Form
  String? _selectedResultProgId;
  String? _selectedResultStudentId;
  final _resultMarksController = TextEditingController();
  final _resultGradeController = TextEditingController();
  int _resultPosition = 1;

  // Team Form Controllers
  final _teamNameController = TextEditingController();
  final _teamMentorController = TextEditingController();
  final _teamLeaderNameController = TextEditingController();
  final _teamAssistantLeaderController = TextEditingController();

  // Program Form Controllers
  final _progCodeController = TextEditingController();
  final _progNameController = TextEditingController();
  final _progMaxParticipantsController = TextEditingController(text: '1');
  FestSection _progSection = FestSection.subJunior;

  // Schedule & Venue State & Controllers
  String _scheduleSearchQuery = '';
  String _selectedScheduleDateFilter = 'ALL';
  String _selectedScheduleVenueFilter = 'ALL';
  String _selectedScheduleSectionFilter = 'ALL';

  final _schDateController = TextEditingController(text: '2026-09-05');
  final _schStartTimeController = TextEditingController(text: '09:00');
  final _schEndTimeController = TextEditingController(text: '10:30');

  final _venueNameController = TextEditingController();
  final _venueLocationController = TextEditingController();
  final _venueCapacityController = TextEditingController(text: '100');
  final _venueDescController = TextEditingController();

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
    _teamMentorController.dispose();
    _teamLeaderNameController.dispose();
    _teamAssistantLeaderController.dispose();
    _progCodeController.dispose();
    _progNameController.dispose();
    _progMaxParticipantsController.dispose();
    _schDateController.dispose();
    _schStartTimeController.dispose();
    _schEndTimeController.dispose();
    _venueNameController.dispose();
    _venueLocationController.dispose();
    _venueCapacityController.dispose();
    _venueDescController.dispose();
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
    final schedulesAsync = ref.watch(schedulesProvider);
    final registrationsAsync = ref.watch(registrationsProvider);
    final usersAsync = ref.watch(usersProvider);
    final leadersAsync = ref.watch(leadersProvider);
    final juriesAsync = ref.watch(juriesProvider);

    final currentUser = ref.watch(authServiceProvider).currentUser;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final navItems = const [
      SidebarNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
      SidebarNavItem(icon: Icons.people_alt_rounded, label: 'Students'),
      SidebarNavItem(icon: Icons.groups_rounded, label: 'Teams'),
      SidebarNavItem(icon: Icons.category_rounded, label: 'Programs'),
      SidebarNavItem(icon: Icons.calendar_month_rounded, label: 'Schedule & Venue'),
      SidebarNavItem(icon: Icons.rate_review_rounded, label: 'Result Upload'),
      SidebarNavItem(icon: Icons.tv_rounded, label: 'TV Control'),
      SidebarNavItem(icon: Icons.upload_file_rounded, label: 'Excel Import'),
      SidebarNavItem(icon: Icons.manage_accounts_rounded, label: 'User Logins'),
      SidebarNavItem(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    Widget mainContent = IndexedStack(
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
        // 4. Schedule & Venue Management
        _buildScheduleAndVenueSection(schedulesAsync, venuesAsync, programsAsync, studentsAsync, registrationsAsync, teamsAsync),
        // 5. Result Upload & Verification Workflow
        _buildResultUploadSection(programsAsync, studentsAsync, teamsAsync, resultsAsync),
        // 6. TV Control & Announcements
        _buildTvControlSection(),
        // 7. Excel Import
        _buildExcelImportSection(),
        // 8. User Logins Management (Team Leaders & Jury)
        _buildUserManagementSection(usersAsync, leadersAsync, juriesAsync, teamsAsync, programsAsync),
        // 9. Settings & Demo Data Generator
        _buildSettingsSection(),
      ],
    );

    final actions = [
      if (!isMobile) ...[
        Chip(
          avatar: const Icon(Icons.person, size: 16, color: AppTheme.ink),
          label: Text(currentUser?.name ?? 'Controller Admin', style: GoogleFonts.workSans(color: AppTheme.ink, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.cream,
          side: const BorderSide(color: AppTheme.line),
        ),
        const SizedBox(width: 8),
      ],
      IconButton(
        icon: const Icon(Icons.refresh, color: AppTheme.ink),
        onPressed: () => triggerDataRefresh(ref),
        tooltip: 'Refresh Data',
      ),
      IconButton(
        icon: const Icon(Icons.logout, color: AppTheme.red),
        tooltip: 'Logout',
        onPressed: () {
          ref.read(authServiceProvider).logout();
          context.go('/public');
        },
      ),
      const SizedBox(width: 8),
    ];

    return AppResponsiveLayout(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      items: navItems,
      headerTitle: currentUser?.name ?? 'Fest Controller',
      headerSubtitle: 'Fest Controller Portal',
      headerIcon: Icons.admin_panel_settings_rounded,
      headerColor: AppTheme.red,
      appBarActions: actions,
      body: mainContent,
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
            separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Text('Registered Students (${students.length})', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildExcelFormatButton(onTap: _showStudentTemplateDialog),
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

  Widget _buildExcelFormatButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F5EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E1E1E), width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF9E2A2B),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Excel Format',
              style: GoogleFonts.inter(
                color: const Color(0xFF9E2A2B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgramExcelFormatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F5EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded, color: Color(0xFF9E2A2B), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Program Excel Format (3 Columns)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F5EE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF9E2A2B), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Program Types Supported:',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF9E2A2B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1. Stage — Stage event\n'
                          '2. Non-Stage — Off-stage event\n'
                          '3. General — General event',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF333333)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'When importing programs using Excel, your spreadsheet (.xlsx or .xls) must include these 3 columns in order:',
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.inkSoft),
                  ),
                  const SizedBox(height: 12),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(2.0),
                      1: FlexColumnWidth(1.4),
                      2: FlexColumnWidth(1.4),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text('Program Name', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('Section', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('Program Type', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      const TableRow(
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text('Elocution English')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Sub Junior')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Stage')),
                        ],
                      ),
                      const TableRow(
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text('Group Song')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Senior')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Stage')),
                        ],
                      ),
                      const TableRow(
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text('Pencil Drawing')),
                          Padding(padding: EdgeInsets.all(8), child: Text('General')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Non-Stage')),
                        ],
                      ),
                      const TableRow(
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text('General Quiz')),
                          Padding(padding: EdgeInsets.all(8), child: Text('General')),
                          Padding(padding: EdgeInsets.all(8), child: Text('Stage')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rules & Guidelines:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF92400E))),
                        const SizedBox(height: 4),
                        Text('• Program Code is auto-generated automatically.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78350F))),
                        Text('• Section values: Sub Junior, Senior, Super Senior, General.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78350F))),
                        Text('• Program Type: Enter "Stage" or "Non-Stage".', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78350F))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Download Sample Template'),
              onPressed: () async {
                final excelService = ref.read(excelServiceProvider);
                final bytes = excelService.generateProgramTemplate();
                await Printing.sharePdf(bytes: bytes, filename: 'program_excel_template.xlsx');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloaded Program Excel Template.')),
                  );
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Excel Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _importProgramsFromExcel();
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showStudentTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.table_chart, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              const Text('Student Excel Format (4 Columns)'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('When importing students using Excel, your file must have these 4 columns:'),
                const SizedBox(height: 16),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.5),
                  },
                  children: const [
                    TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('Chase Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Team Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('101')),
                        Padding(padding: EdgeInsets.all(8), child: Text('John Doe')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Sub Junior')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Tigrees')),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('102')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Sarah Smith')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Sub Junior')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Eagles')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Note: Section can be "Sub Junior", "Senior", "Super Senior", or "General". If the Team Name does not exist, it will be automatically created.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTeamTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.table_chart, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              const Text('Team Excel Format (4 Columns)'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('When importing teams using Excel, your file must have these 4 columns:'),
                const SizedBox(height: 16),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.4),
                  },
                  children: const [
                    TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('Team Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Mentor Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Leader Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Assistant Leader', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('Tigrees')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Dr. Alex')),
                        Padding(padding: EdgeInsets.all(8), child: Text('John Doe')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Sarah Smith')),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('Eagles')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Prof. David')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Michael Brown')),
                        Padding(padding: EdgeInsets.all(8), child: Text('Emma Watson')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  const CircularProgressIndicator(color: AppTheme.red),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(fontSize: 14),
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

  Future<void> _importStudentsFromExcel() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (files.isNotEmpty) {
        if (!mounted) return;
        _showLoadingDialog('Importing Students', 'Processing Excel file and adding students...\nPlease wait.');

        try {
          final bytes = await files.first.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importStudents(bytes);
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog('Students Excel Import Summary', importResult);
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to import Excel file: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select Excel file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importProgramsFromExcel() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (files.isNotEmpty) {
        if (!mounted) return;
        _showLoadingDialog('Importing Programs', 'Processing Excel file and adding programs...\nPlease wait.');

        try {
          final bytes = await files.first.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importPrograms(bytes);
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog('Programs Excel Import Summary', importResult);
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to import Excel file: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select Excel file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importSchedulesFromExcel() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'pdf'],
      );

      if (files.isNotEmpty) {
        if (!mounted) return;
        _showLoadingDialog('Importing Schedules', 'Processing PDF or Excel file with Date, Program, Time, Venue & Category...\nPlease wait.');

        try {
          final file = files.first;
          final bytes = await file.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importSchedules(bytes, file.name);
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog('Schedule Import Summary', importResult);
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to import file: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exportSchedulesToExcel(List<Schedule> schedules, Map<String, Program> progMap, Map<String, Venue> venMap) async {
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No schedules available to export.')),
      );
      return;
    }
    try {
      final excelService = ref.read(excelServiceProvider);
      final bytes = excelService.exportSchedulesToExcel(schedules, progMap, venMap);
      await Printing.sharePdf(bytes: bytes, filename: 'master_schedule_export.xlsx');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${schedules.length} schedules to Excel format.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _downloadScheduleTemplate() async {
    try {
      final excelService = ref.read(excelServiceProvider);
      final bytes = excelService.generateScheduleTemplate();
      await Printing.sharePdf(bytes: bytes, filename: 'schedule_excel_template.xlsx');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaded Schedule Excel Template (Date, Program, Time, Venue, Section).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showScheduleExcelFormatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Schedule Excel Format Instructions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload schedule data in standard Excel format (.xlsx / .xls). Expected sheet columns:',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.inkSoft),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Column 1: DATE (e.g. 2026-09-05)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Column 2: ITEM (e.g. ESSAY ARB / P-101)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Column 3: TIME (e.g. 6:00 TO 6:45 am)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Column 4: VENUE / VIWE (e.g. S1 / Main Auditorium)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Column 5: CATEGORY / CATOGARY (SENIOR / Sub Junior / General)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('• Programs and Venues not yet in system will be automatically created upon import.', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade900)),
                Text('• Start and End times are automatically parsed from time ranges.', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade900)),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Download Template'),
              onPressed: () {
                _downloadScheduleTemplate();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Excel Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.red,
                foregroundColor: AppTheme.cream,
              ),
              onPressed: () {
                Navigator.pop(context);
                _importSchedulesFromExcel();
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearSchedules() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 28),
              const SizedBox(width: 10),
              Text('Clear All Dummy Schedules?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'This action will clear all current schedules from the system. You can then upload your clean schedule via Excel import.',
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.ink),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Schedules'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(scheduleRepositoryProvider).clearSchedules();
                triggerDataRefresh(ref);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All dummy schedule data cleared.'), backgroundColor: AppTheme.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
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
                AppTextField(label: 'Chase Number', controller: _studentChaseController, hint: 'e.g. 101'),
                const SizedBox(height: 10),
                AppTextField(label: 'Full Name', controller: _studentNameController),
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
                  dateOfBirth: '2010-01-01',
                  section: _studentSection,
                  teamId: _studentTeamId ?? (teams.isNotEmpty ? teams.first.id : 'default'),
                  phone: '',
                  className: '',
                  schoolName: '',
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Text('Registered Teams (${teams.length})', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.help_outline),
                          label: const Text('Excel Format'),
                          onPressed: _showTeamTemplateDialog,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Import Teams (Excel)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _importTeamsFromExcel,
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Export Teams (Excel)'),
                          onPressed: () {
                            final excelService = ref.read(excelServiceProvider);
                            excelService.exportTeamsToExcel(teams);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Exported ${teams.length} teams to Excel format.')),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.group_add),
                          label: const Text('Add New Team'),
                          onPressed: _showAddTeamDialog,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: teams.length,
                    itemBuilder: (context, idx) {
                      final t = teams[idx];
                      final mentorStr = t.mentorName ?? '—';
                      final leaderStr = t.leaderName ?? '—';
                      final asstStr = t.assistantLeaderName ?? '—';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text('#${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(t.teamName),
                          subtitle: Text('Mentor: $mentorStr • Leader: $leaderStr • Asst: $asstStr'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Rank #${t.rank > 0 ? t.rank : idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                tooltip: 'Edit Team',
                                onPressed: () => _showEditTeamDialog(t),
                              ),
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
          content: Text('Are you sure you want to delete team "${team.teamName}"? This action cannot be undone.'),
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

  Future<void> _importTeamsFromExcel() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (files.isNotEmpty) {
        if (!mounted) return;
        _showLoadingDialog('Importing Teams', 'Processing Excel file and adding teams...\nPlease wait.');

        try {
          final bytes = await files.first.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importTeams(bytes);
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog('Teams Excel Import Summary', importResult);
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to import Excel file: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select Excel file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importRegistrationsFromExcel() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (files.isNotEmpty) {
        if (!mounted) return;
        _showLoadingDialog('Importing Registrations', 'Processing Excel file and adding registrations...\nPlease wait.');

        try {
          final bytes = await files.first.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importRegistrations(bytes);
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog('Registrations Excel Import Summary', importResult);
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to import Excel file: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select Excel file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddTeamDialog() {
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Team'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Team Name',
                      controller: _teamNameController,
                      hint: 'e.g. Tigrees',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Mentor Name',
                      controller: _teamMentorController,
                      hint: 'e.g. Dr. Alex',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Leader Name',
                      controller: _teamLeaderNameController,
                      hint: 'e.g. John Doe',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Assistant Leader Name',
                      controller: _teamAssistantLeaderController,
                      hint: 'e.g. Sarah Smith',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Save Team',
                  isLoading: isSubmitting,
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = _teamNameController.text.trim();
                          final mentor = _teamMentorController.text.trim();
                          final inputLeaderName = _teamLeaderNameController.text.trim();
                          final assistant = _teamAssistantLeaderController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Team Name is required!'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          final code = 'T-${name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}';

                          final currentTeams = ref.read(teamsProvider).value ?? [];
                          final isDuplicate = currentTeams.any((t) => t.teamName.trim().toLowerCase() == name.toLowerCase() || t.teamCode.toUpperCase() == code.toUpperCase());

                          if (isDuplicate) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('A team named "$name" already exists! Please enter a unique team name.'), backgroundColor: Colors.orange),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

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
                            mentorName: mentor.isNotEmpty ? mentor : null,
                            leaderName: leaderName,
                            assistantLeaderName: assistant.isNotEmpty ? assistant : null,
                            leaderId: leaderId,
                          );

                          final leaderProfile = TeamLeader(
                            id: leaderId,
                            name: leaderName,
                            phone: '',
                            email: '',
                            username: leaderUsername,
                            password: leaderPassword,
                            teamId: teamId,
                          );

                          final leaderUser = User(
                            id: 'usr_leader_$teamId',
                            username: leaderUsername,
                            password: leaderPassword,
                            name: leaderName,
                            role: UserRole.teamLeader,
                            teamId: teamId,
                          );

                          try {
                            // Execute database operations in parallel for maximum speed
                            await Future.wait([
                              ref.read(teamRepositoryProvider).addTeam(team),
                              ref.read(leaderRepositoryProvider).addLeader(leaderProfile),
                              ref.read(userRepositoryProvider).saveUser(leaderUser),
                            ]);

                            triggerDataRefresh(ref);

                            _teamNameController.clear();
                            _teamMentorController.clear();
                            _teamLeaderNameController.clear();
                            _teamAssistantLeaderController.clear();

                            if (context.mounted) Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Team "$name" added! Leader: $leaderUsername | Pass: $leaderPassword'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (context.mounted) {
                              final errStr = e.toString();
                              final isDup = errStr.contains('23505') || errStr.contains('duplicate key') || errStr.contains('teams_teamCode_key');
                              final displayMsg = isDup
                                  ? 'A team with name/code "$name" already exists in database! Please choose a unique name.'
                                  : 'Error adding team to database: $e';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(displayMsg),
                                  backgroundColor: isDup ? Colors.orange : Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTeamDialog(Team team) {
    final nameController = TextEditingController(text: team.teamName);
    final mentorController = TextEditingController(text: team.mentorName ?? '');
    final leaderController = TextEditingController(text: team.leaderName ?? '');
    final assistantController = TextEditingController(text: team.assistantLeaderName ?? '');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Team: ${team.teamName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Team Name',
                      controller: nameController,
                      hint: 'e.g. Tigrees',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Mentor Name',
                      controller: mentorController,
                      hint: 'e.g. Dr. Alex',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Leader Name',
                      controller: leaderController,
                      hint: 'e.g. John Doe',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Assistant Leader Name',
                      controller: assistantController,
                      hint: 'e.g. Sarah Smith',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Update Team',
                  isLoading: isSubmitting,
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          final newMentor = mentorController.text.trim();
                          final newLeader = leaderController.text.trim();
                          final newAssistant = assistantController.text.trim();

                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Team Name is required!'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final updatedTeam = team.copyWith(
                            teamName: newName,
                            mentorName: newMentor.isNotEmpty ? newMentor : null,
                            leaderName: newLeader.isNotEmpty ? newLeader : null,
                            assistantLeaderName: newAssistant.isNotEmpty ? newAssistant : null,
                          );

                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            await ref.read(teamRepositoryProvider).updateTeam(updatedTeam);
                            ref.invalidate(teamsProvider);
                            triggerDataRefresh(ref);

                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Team "$newName" updated successfully!'), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            final cleanErr = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(cleanErr), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Text('Fest Programs (${programs.length})', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildExcelFormatButton(onTap: _showProgramExcelFormatDialog),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Import Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _importProgramsFromExcel,
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Export Excel'),
                          onPressed: () async {
                            final excelService = ref.read(excelServiceProvider);
                            final bytes = excelService.exportProgramsToExcel(programs);
                            await Printing.sharePdf(bytes: bytes, filename: 'programs_export.xlsx');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Exported ${programs.length} programs to Excel format.')),
                              );
                            }
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('Add New Program'),
                          onPressed: _showAddProgramDialog,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Delete All Programs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _confirmDeleteAllPrograms(programs),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: programs.isEmpty
                      ? Center(
                          child: Text(
                            'No programs created yet.',
                            style: GoogleFonts.inter(color: AppTheme.inkSoft, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          itemCount: programs.length,
                          itemBuilder: (context, idx) {
                            final p = programs[idx];
                            final isGroupEvent = p.maxParticipants > 1;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isGroupEvent ? Colors.purple.shade50 : Colors.blue.shade50,
                                  child: Icon(
                                    isGroupEvent ? Icons.groups_rounded : Icons.person_rounded,
                                    color: isGroupEvent ? Colors.purple : Colors.blue,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(p.programName, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isGroupEvent ? Colors.purple.shade100 : Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isGroupEvent ? 'Group (${p.maxParticipants} max)' : 'Single',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isGroupEvent ? Colors.purple.shade900 : Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Section: ${p.section.label} • ${p.isStageProgram ? "Stage Program" : "Non-Stage Program"}',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                      tooltip: 'Edit Program',
                                      onPressed: () => _showEditProgramDialog(p),
                                    ),
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
    String progType = 'STAGE'; // 'STAGE', 'NON_STAGE'

    final availableSections = [
      FestSection.subJunior,
      FestSection.senior,
      FestSection.superSenior,
      FestSection.general,
    ];
    if (!availableSections.contains(_progSection)) {
      _progSection = FestSection.subJunior;
    }

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
                      label: 'Program Name',
                      controller: _progNameController,
                      hint: 'e.g. Solo Violin',
                    ),
                    const SizedBox(height: 10),
                    AppDropdown<FestSection>(
                      label: 'Section',
                      value: _progSection,
                      items: availableSections
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _progSection = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    AppDropdown<String>(
                      label: 'Program Type',
                      value: progType,
                      items: const [
                        DropdownMenuItem(value: 'STAGE', child: Text('Stage')),
                        DropdownMenuItem(value: 'NON_STAGE', child: Text('Non-Stage')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            progType = val;
                          });
                        }
                      },
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
                    final name = _progNameController.text.trim();
                    final isStage = progType == 'STAGE';
                    final isGeneral = _progSection == FestSection.general;
                    final category = isGeneral
                        ? ProgramCategory.general
                        : (isStage ? ProgramCategory.stage : ProgramCategory.nonStage);

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Program Name is required!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // Auto-generate code
                    final programs = ref.read(programsProvider).value ?? [];
                    final existingCodes = programs.map((p) => p.programCode.trim().toLowerCase()).toSet();
                    int codeCounter = 101;
                    String code = 'P-$codeCounter';
                    while (existingCodes.contains(code.toLowerCase())) {
                      codeCounter++;
                      code = 'P-$codeCounter';
                    }

                    final program = Program(
                      id: 'prog_${const Uuid().v4()}',
                      programCode: code,
                      programName: name,
                      section: _progSection,
                      category: category,
                      isStageProgram: isStage,
                      isGeneral: isGeneral,
                      maxParticipants: 1,
                      duration: '30 mins',
                    );

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      print('[Flutter UI] Adding program: ${program.toMap()}');
                      await ref.read(programRepositoryProvider).addProgram(program);
                      print('[Flutter UI] addProgram succeeded, triggering data refresh');
                      triggerDataRefresh(ref);

                      _progNameController.clear();

                      if (mounted) navigator.pop();

                      messenger.showSnackBar(
                        SnackBar(content: Text('Program "$name" ($code) created successfully!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      print('[Flutter UI] addProgram failed: $e');
                      if (mounted) navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to save program: $e'), backgroundColor: Colors.red),
                      );
                    }
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

  void _showEditProgramDialog(Program program) {
    final availableSections = [
      FestSection.subJunior,
      FestSection.senior,
      FestSection.superSenior,
      FestSection.general,
    ];
    final nameController = TextEditingController(text: program.programName);
    FestSection section = availableSections.contains(program.section) ? program.section : FestSection.subJunior;
    String progType = program.isStageProgram ? 'STAGE' : 'NON_STAGE';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Program: ${program.programName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Program Name',
                      controller: nameController,
                      hint: 'e.g. Solo Violin',
                    ),
                    const SizedBox(height: 10),
                    AppDropdown<FestSection>(
                      label: 'Section',
                      value: section,
                      items: availableSections
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => section = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    AppDropdown<String>(
                      label: 'Program Type',
                      value: progType,
                      items: const [
                        DropdownMenuItem(value: 'STAGE', child: Text('Stage')),
                        DropdownMenuItem(value: 'NON_STAGE', child: Text('Non-Stage')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            progType = val;
                          });
                        }
                      },
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
                    final name = nameController.text.trim();
                    final isStage = progType == 'STAGE';
                    final isGeneral = section == FestSection.general;
                    final category = isGeneral
                        ? ProgramCategory.general
                        : (isStage ? ProgramCategory.stage : ProgramCategory.nonStage);

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Program Name is required!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    final updated = program.copyWith(
                      programName: name,
                      section: section,
                      category: category,
                      isStageProgram: isStage,
                      isGeneral: isGeneral,
                    );

                    try {
                      await ref.read(programRepositoryProvider).updateProgram(updated);
                      triggerDataRefresh(ref);

                      if (mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Program "$name" updated successfully!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      if (mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update program: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
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
                try {
                  await ref.read(programRepositoryProvider).deleteProgram(program.id);
                  triggerDataRefresh(ref);
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Program "${program.programName}" deleted successfully.')),
                  );
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete program: $e')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _confirmDeleteAllPrograms(List<Program> programs) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete All Programs'),
          content: Text('Are you sure you want to delete all ${programs.length} programs? This action cannot be undone and will delete associated schedules and results.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  final repo = ref.read(programRepositoryProvider);
                  for (final p in programs) {
                    await repo.deleteProgram(p.id);
                  }
                  triggerDataRefresh(ref);
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All programs deleted successfully.')),
                  );
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete programs: $e')),
                  );
                }
              },
              child: const Text('Delete All'),
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
                    final student = students.where((s) => s.id == _selectedResultStudentId).firstOrNull;
                    if (student == null) return;

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
    final excelService = ref.read(excelServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Excel Multi-Entity Import Center', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Bulk import programs, students, and teams directly from Excel spreadsheets (.xlsx / .xls)',
            style: GoogleFonts.inter(color: AppTheme.inkSoft, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // 1. Programs Import Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category_rounded, color: AppTheme.primaryColor, size: 24),
                    const SizedBox(width: 10),
                    Text('Import Programs from Excel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: Program Name, Section (Sub Junior / Senior / Super Senior / General), Program Type (Stage / Non-Stage / General)',
                  style: GoogleFonts.inter(color: AppTheme.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildExcelFormatButton(onTap: _showProgramExcelFormatDialog),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select & Upload Programs Excel File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _importProgramsFromExcel,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Download Programs Template'),
                      onPressed: () async {
                        final bytes = excelService.generateProgramTemplate();
                        await Printing.sharePdf(bytes: bytes, filename: 'program_excel_template.xlsx');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloaded Program Excel Template.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1.5. Registrations Import Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.app_registration_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 10),
                    Text('Import Program Registrations from Excel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: Chase Number, Student Name, Program Name, Section',
                  style: GoogleFonts.inter(color: AppTheme.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select & Upload Registrations Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _importRegistrationsFromExcel,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Download Registrations Template'),
                      onPressed: () async {
                        final bytes = excelService.generateRegistrationTemplate();
                        await Printing.sharePdf(bytes: bytes, filename: 'registration_excel_template.xlsx');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloaded Registrations Excel Template.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Students Import Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, color: Colors.blueAccent, size: 24),
                    const SizedBox(width: 10),
                    Text('Import Students from Excel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: Chase Number, Name, Section (Sub Junior / Senior / Super Senior / General), Team Name',
                  style: GoogleFonts.inter(color: AppTheme.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select & Upload Students Excel File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _importStudentsFromExcel,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Download Students Template'),
                      onPressed: () {
                        excelService.generateStudentTemplate();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloaded Student Excel Template.')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Teams Import Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: Colors.purple, size: 24),
                    const SizedBox(width: 10),
                    Text('Import Teams from Excel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: Team Name, Mentor Name, Leader Name, Assistant Leader Name',
                  style: GoogleFonts.inter(color: AppTheme.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select & Upload Teams Excel File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _importTeamsFromExcel,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Download Teams Template'),
                      onPressed: () async {
                        final bytes = excelService.generateTeamTemplate();
                        await Printing.sharePdf(bytes: bytes, filename: 'team_excel_template.xlsx');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloaded Team Excel Template.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Schedules & Venues Import Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: Colors.teal, size: 24),
                    const SizedBox(width: 10),
                    Text('Import Schedules & Venues from Excel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: DATE, ITEM, TIME, VENUE (VIWE), CATEGORY (CATOGARY)',
                  style: GoogleFonts.inter(color: AppTheme.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildExcelFormatButton(onTap: _showScheduleExcelFormatDialog),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select & Upload Schedule Excel File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _importSchedulesFromExcel,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Download Schedule Template'),
                      onPressed: _downloadScheduleTemplate,
                    ),
                  ],
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Credentials & Access Control', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Create and manage Login IDs & Passwords for Team Leaders and Jury members', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Team Leader Login'),
                      onPressed: () => _showAddEditTeamLeaderDialog(teams: teams),
                    ),
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
                            label: Text(team != null ? team.teamName : 'Unassigned Team', style: const TextStyle(fontSize: 12)),
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
                    if (juryProfile != null)
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.purple),
                        tooltip: 'View Login QR Codes',
                        onPressed: () => _showJuryQRDialog(context, juryProfile, programs),
                      ),
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
                        items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.teamName))).toList(),
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
                      _showJuryQRDialog(context, jury, programs);
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

  void _showJuryQRDialog(BuildContext context, Jury jury, List<Program> programs) {
    final assignedProgs = programs.where((p) => jury.assignedPrograms.contains(p.id)).toList();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Jury Login QR Codes - ${jury.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: assignedProgs.length,
              itemBuilder: (context, index) {
                final p = assignedProgs[index];
                final payload = QrService.generateJuryLoginProgramQrPayload(jury.username, jury.password, p.id);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text('${p.programName} (${p.programCode})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        QrImageView(
                          data: payload,
                          version: QrVersions.auto,
                          size: 150.0,
                        ),
                        const SizedBox(height: 8),
                        const Text('Scan this to login and mark this program directly.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
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

  int _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final min = int.parse(parts[1].split(' ')[0]);
        return hour * 60 + min;
      }
    } catch (_) {}
    return 0;
  }

  bool _checkTimeOverlap(String start1, String end1, String start2, String end2) {
    final s1 = _parseTimeToMinutes(start1);
    final e1 = _parseTimeToMinutes(end1);
    final s2 = _parseTimeToMinutes(start2);
    final e2 = _parseTimeToMinutes(end2);
    if (s1 == 0 || e1 == 0 || s2 == 0 || e2 == 0) return false;
    return (s1 < e2) && (s2 < e1);
  }

  List<ScheduleConflict> _analyzeScheduleConflicts({
    required List<Schedule> schedules,
    required List<Program> programs,
    required List<Venue> venues,
    required List<Student> students,
    required List<Registration> registrations,
    required List<Team> teams,
  }) {
    final List<ScheduleConflict> conflicts = [];
    final Map<String, Program> progMap = {for (var p in programs) p.id: p};
    final Map<String, Venue> venMap = {for (var v in venues) v.id: v};
    final Map<String, Student> studMap = {for (var s in students) s.id: s};
    final Map<String, Team> teamMap = {for (var t in teams) t.id: t};

    final Map<String, List<Registration>> regsByProg = {};
    for (var r in registrations) {
      regsByProg.putIfAbsent(r.programId, () => []).add(r);
    }

    final Set<String> checkedKeys = {};

    for (int i = 0; i < schedules.length; i++) {
      for (int j = i + 1; j < schedules.length; j++) {
        final s1 = schedules[i];
        final s2 = schedules[j];

        if (s1.date.trim() != s2.date.trim() || s1.date.isEmpty) continue;

        if (_checkTimeOverlap(s1.startTime, s1.endTime, s2.startTime, s2.endTime)) {
          final p1 = progMap[s1.programId];
          final p2 = progMap[s2.programId];
          if (p1 == null || p2 == null) continue;

          final v1 = venMap[s1.venueId];
          final v2 = venMap[s2.venueId];

          // 1. Venue Double-Booking Check
          if (s1.venueId.isNotEmpty && s1.venueId == s2.venueId) {
            final key = 'VENUE_${s1.id}_${s2.id}';
            if (!checkedKeys.contains(key)) {
              checkedKeys.add(key);
              final dummyStud = Student(
                id: 'venue_clash_${v1?.id}',
                chaseNumber: 'VENUE-CLASH',
                name: 'Venue Double Booking (${v1?.name ?? 'Venue'})',
                gender: '',
                dateOfBirth: '',
                section: p1.section,
                teamId: '',
                phone: '',
                className: '',
                schoolName: '',
                qrCode: '',
              );
              conflicts.add(ScheduleConflict(
                student: dummyStud,
                program1: p1,
                program2: p2,
                schedule1: s1,
                schedule2: s2,
                venue1: v1,
                venue2: v2,
                conflictType: 'VENUE_OVERLAP',
                description: 'Venue "${v1?.name ?? 'Venue'}" is double-booked for "${p1.programName}" (${s1.startTime}-${s1.endTime}) and "${p2.programName}" (${s2.startTime}-${s2.endTime}) on ${s1.date}.',
              ));
            }
          }

          // 2. Student Cross-Venue / Cross-Program Overlap Check
          final p1Regs = regsByProg[p1.id] ?? [];
          final p2Regs = regsByProg[p2.id] ?? [];
          final p1StudentIds = p1Regs.map((r) => r.studentId).toSet();

          for (var r2 in p2Regs) {
            if (p1StudentIds.contains(r2.studentId)) {
              final stud = studMap[r2.studentId];
              if (stud != null) {
                final key = 'STUD_${stud.id}_${s1.id}_${s2.id}';
                if (!checkedKeys.contains(key)) {
                  checkedKeys.add(key);
                  final tm = teamMap[stud.teamId];
                  final v1Name = v1?.name ?? 'Venue 1';
                  final v2Name = v2?.name ?? 'Venue 2';
                  final sameVenue = s1.venueId == s2.venueId;
                  final venueNotice = sameVenue ? 'the SAME venue ($v1Name)' : 'DIFFERENT venues ($v1Name vs $v2Name)';

                  conflicts.add(ScheduleConflict(
                    student: stud,
                    team: tm,
                    program1: p1,
                    program2: p2,
                    schedule1: s1,
                    schedule2: s2,
                    venue1: v1,
                    venue2: v2,
                    conflictType: 'STUDENT_OVERLAP',
                    description: 'Student ${stud.name} (Chase #${stud.chaseNumber}, Team: ${tm?.teamName ?? 'N/A'}) already has program "${p1.programName}" scheduled at $v1Name (${s1.startTime}-${s1.endTime}), but is also registered for "${p2.programName}" at $v2Name (${s2.startTime}-${s2.endTime}) on ${s1.date} ($venueNotice).',
                  ));
                }
              }
            }
          }
        }
      }
    }

    return conflicts;
  }

  Widget _buildScheduleAndVenueSection(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Venue>> venuesAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Registration>> registrationsAsync,
    AsyncValue<List<Team>> teamsAsync,
  ) {
    final schedules = schedulesAsync.value ?? [];
    final venues = venuesAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    final students = studentsAsync.value ?? [];
    final registrations = registrationsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];

    final conflicts = _analyzeScheduleConflicts(
      schedules: schedules,
      programs: programs,
      venues: venues,
      students: students,
      registrations: registrations,
      teams: teams,
    );

    final Map<String, Program> progMap = {for (var p in programs) p.id: p};
    final Map<String, Venue> venMap = {for (var v in venues) v.id: v};

    final filteredSchedules = schedules.where((s) {
      final prog = progMap[s.programId];
      final ven = venMap[s.venueId];
      final matchesSearch = _scheduleSearchQuery.isEmpty ||
          (prog?.programName.toLowerCase().contains(_scheduleSearchQuery.toLowerCase()) ?? false) ||
          (prog?.programCode.toLowerCase().contains(_scheduleSearchQuery.toLowerCase()) ?? false) ||
          (ven?.name.toLowerCase().contains(_scheduleSearchQuery.toLowerCase()) ?? false);

      final matchesDate = _selectedScheduleDateFilter == 'ALL' || s.date == _selectedScheduleDateFilter;
      final matchesVenue = _selectedScheduleVenueFilter == 'ALL' || s.venueId == _selectedScheduleVenueFilter;
      final matchesSection = _selectedScheduleSectionFilter == 'ALL' || (prog?.section.name == _selectedScheduleSectionFilter);

      return matchesSearch && matchesDate && matchesVenue && matchesSection;
    }).toList();

    final availableDates = schedules.map((s) => s.date).where((d) => d.isNotEmpty).toSet().toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule & Venue Management',
                    style: GoogleFonts.rye(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage event dates, venues, program schedules, and inspect student timing clashes.',
                    style: GoogleFonts.workSans(color: AppTheme.inkSoft, fontSize: 13),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(
                      conflicts.isNotEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text('Check Clashes (${conflicts.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: conflicts.isNotEmpty ? AppTheme.red : Colors.teal,
                      foregroundColor: AppTheme.cream,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () {
                      _showConflictReportDialog(
                        context,
                        conflicts: conflicts,
                        schedules: schedules,
                        programs: programs,
                        venues: venues,
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('+ Add Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      foregroundColor: AppTheme.cream,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () {
                      _showAddEditScheduleDialog(
                        context,
                        programs: programs,
                        venues: venues,
                        schedules: schedules,
                        students: students,
                        registrations: registrations,
                        teams: teams,
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Import PDF / Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: _showScheduleExcelFormatDialog,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export Excel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      side: const BorderSide(color: AppTheme.line),
                    ),
                    onPressed: () => _exportSchedulesToExcel(schedules, progMap, venMap),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppTheme.red),
                    label: const Text('Clear Schedules', style: TextStyle(color: AppTheme.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      side: const BorderSide(color: AppTheme.red),
                    ),
                    onPressed: _confirmClearSchedules,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Scheduled',
                  value: '${schedules.length}',
                  icon: Icons.calendar_today_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Total Venues',
                  value: '0',
                  icon: Icons.place_rounded,
                  color: AppTheme.mustard,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Schedule Clashes',
                  value: '${conflicts.length}',
                  icon: Icons.error_outline_rounded,
                  color: conflicts.isNotEmpty ? AppTheme.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showConflictReportDialog(
    BuildContext context, {
    required List<ScheduleConflict> conflicts,
    required List<Schedule> schedules,
    required List<Program> programs,
    required List<Venue> venues,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                conflicts.isEmpty ? Icons.check_circle : Icons.warning_amber_rounded,
                color: conflicts.isEmpty ? Colors.teal : AppTheme.red,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  conflicts.isEmpty ? 'No Schedule Clashes Found' : 'Schedule & Venue Clash Analysis (${conflicts.length})',
                  style: GoogleFonts.workSans(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 720,
            child: conflicts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade300),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 48, color: Colors.teal),
                        const SizedBox(height: 12),
                        Text(
                          'Everything Looks Clear!',
                          style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No students are registered for overlapping programs on the same date and time, and no venues have double-bookings.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(fontSize: 13, color: Colors.teal.shade800),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'The following students or venues have overlapping program time slots on the same date. Review details below to adjust schedule dates or venues.',
                                  style: GoogleFonts.workSans(fontSize: 12.5, color: const Color(0xFF991B1B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: conflicts.length,
                          itemBuilder: (ctx, idx) {
                            final c = conflicts[idx];
                            final isVenueClash = c.conflictType == 'VENUE_OVERLAP';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isVenueClash ? Colors.orange.shade300 : AppTheme.line),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isVenueClash ? Colors.orange.shade100 : AppTheme.cream,
                                        child: Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isVenueClash ? Colors.orange.shade900 : AppTheme.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          isVenueClash
                                              ? '🚨 Venue Double-Booking: ${c.venue1?.name}'
                                              : '👤 Student: ${c.student.name} (${c.student.chaseNumber}) ${c.team != null ? '- Team ${c.team!.teamName}' : ''}',
                                          style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(c.schedule1.date),
                                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        backgroundColor: AppTheme.cream,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Program 1:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                              Text('${c.program1.programName} (${c.program1.programCode})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                              const SizedBox(height: 2),
                                              Text('📍 Venue: ${c.venue1?.name ?? 'TBA'}', style: const TextStyle(fontSize: 11.5)),
                                              Text('⏰ Time: ${c.schedule1.startTime} - ${c.schedule1.endTime}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Icon(Icons.swap_horiz_rounded, color: AppTheme.red),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Program 2:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                              Text('${c.program2.programName} (${c.program2.programCode})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                              const SizedBox(height: 2),
                                              Text('📍 Venue: ${c.venue2?.name ?? 'TBA'}', style: const TextStyle(fontSize: 11.5)),
                                              Text('⏰ Time: ${c.schedule2.startTime} - ${c.schedule2.endTime}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    c.description,
                                    style: GoogleFonts.workSans(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditScheduleDialog(
    BuildContext context, {
    Schedule? scheduleToEdit,
    required List<Program> programs,
    required List<Venue> venues,
    required List<Schedule> schedules,
    required List<Student> students,
    required List<Registration> registrations,
    required List<Team> teams,
  }) {
    String? selectedProgId = scheduleToEdit?.programId ?? (programs.isNotEmpty ? programs.first.id : null);
    String? selectedVenueId = scheduleToEdit?.venueId ?? (venues.isNotEmpty ? venues.first.id : null);
    final dateController = TextEditingController(text: scheduleToEdit?.date ?? '2026-09-05');
    final startTimeController = TextEditingController(text: scheduleToEdit?.startTime ?? '09:00');
    final endTimeController = TextEditingController(text: scheduleToEdit?.endTime ?? '10:30');
    String status = scheduleToEdit?.status ?? 'SCHEDULED';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<ScheduleConflict> liveConflicts = [];
            if (selectedProgId != null && selectedVenueId != null) {
              final testSchedule = Schedule(
                id: scheduleToEdit?.id ?? 'temp_sch',
                programId: selectedProgId!,
                venueId: selectedVenueId!,
                date: dateController.text.trim(),
                startTime: startTimeController.text.trim(),
                endTime: endTimeController.text.trim(),
                status: status,
              );

              final testSchedulesList = schedules.where((s) => s.id != (scheduleToEdit?.id ?? 'temp_sch')).toList()..add(testSchedule);

              liveConflicts = _analyzeScheduleConflicts(
                schedules: testSchedulesList,
                programs: programs,
                venues: venues,
                students: students,
                registrations: registrations,
                teams: teams,
              ).where((c) => c.schedule1.id == testSchedule.id || c.schedule2.id == testSchedule.id).toList();
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit_calendar_rounded, color: AppTheme.red),
                  const SizedBox(width: 10),
                  Text(scheduleToEdit == null ? 'Add Program Schedule' : 'Edit Program Schedule'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedProgId,
                        decoration: const InputDecoration(labelText: 'Select Program', border: OutlineInputBorder()),
                        items: programs.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text('[${p.programCode}] ${p.programName} (${p.section.label})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedProgId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedVenueId,
                        decoration: const InputDecoration(labelText: 'Select Venue', border: OutlineInputBorder()),
                        items: venues.map((v) {
                          return DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.name} (${v.location})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedVenueId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dateController,
                              decoration: const InputDecoration(
                                labelText: 'Date (YYYY-MM-DD)',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_month),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Start Time (HH:mm)',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: endTimeController,
                              decoration: const InputDecoration(
                                labelText: 'End Time (HH:mm)',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.access_time_filled),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Schedule Status', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'SCHEDULED', child: Text('SCHEDULED')),
                          DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN_PROGRESS')),
                          DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                          DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              status = val;
                            });
                          }
                        },
                      ),
                      if (liveConflicts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Warning: ${liveConflicts.length} Conflict(s) Detected!',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.red, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ...liveConflicts.map((lc) => Text('• ${lc.description}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D)))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (selectedProgId == null || selectedVenueId == null) return;
                    final sch = Schedule(
                      id: scheduleToEdit?.id ?? const Uuid().v4(),
                      programId: selectedProgId!,
                      venueId: selectedVenueId!,
                      date: dateController.text.trim(),
                      startTime: startTimeController.text.trim(),
                      endTime: endTimeController.text.trim(),
                      status: status,
                    );

                    if (scheduleToEdit == null) {
                      await ref.read(scheduleRepositoryProvider).addSchedule(sch);
                    } else {
                      await ref.read(scheduleRepositoryProvider).updateSchedule(sch);
                    }

                    triggerDataRefresh(ref);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(scheduleToEdit == null ? 'Schedule added successfully.' : 'Schedule updated successfully.')),
                      );
                    }
                  },
                  child: Text(scheduleToEdit == null ? 'Save Schedule' : 'Update Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }


}

class ScheduleConflict {
  final Student student;
  final Team? team;
  final Program program1;
  final Program program2;
  final Schedule schedule1;
  final Schedule schedule2;
  final Venue? venue1;
  final Venue? venue2;
  final String conflictType; // 'STUDENT_OVERLAP' or 'VENUE_OVERLAP'
  final String description;

  ScheduleConflict({
    required this.student,
    this.team,
    required this.program1,
    required this.program2,
    required this.schedule1,
    required this.schedule2,
    this.venue1,
    this.venue2,
    this.conflictType = 'STUDENT_OVERLAP',
    required this.description,
  });
}

class TeamScoreCard extends StatelessWidget {
  final int rank;
  final String teamName;
  final String teamCode;
  final num points;

  const TeamScoreCard({
    super.key,
    required this.rank,
    required this.teamName,
    required this.teamCode,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : (rank == 3 ? Colors.brown : Colors.blueGrey)),
            child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teamName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(teamCode, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${points.toStringAsFixed(1)} pts',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.red),
          ),
        ],
      ),
    );
  }
}
