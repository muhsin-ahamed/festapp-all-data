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
import '../../data/models/user_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../services/excel_service.dart';
import '../../services/qr_service.dart';
import '../../services/scoring_service.dart';
import '../../services/tv_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentTotalSummary {
  final Student student;
  final String teamName;
  final double totalMarks;
  final int totalPoints;
  final int programCount;
  final List<Result> results;
  int overallRank;
  int sectionRank;
  bool isOverallTop1;
  bool isSectionTop1;
  bool isSectionTop2;

  StudentTotalSummary({
    required this.student,
    required this.teamName,
    required this.totalMarks,
    required this.totalPoints,
    required this.programCount,
    required this.results,
    this.overallRank = 0,
    this.sectionRank = 0,
    this.isOverallTop1 = false,
    this.isSectionTop1 = false,
    this.isSectionTop2 = false,
  });

  String get topHighlightText {
    if (isOverallTop1) return '🏆 Fest Overall Top Scorer';
    if (isSectionTop1) return '🥇 1st in ${student.section.label}';
    if (isSectionTop2) return '🥈 2nd in ${student.section.label}';
    return '-';
  }
}

class ControllerPortalScreen extends ConsumerStatefulWidget {
  const ControllerPortalScreen({super.key});

  @override
  ConsumerState<ControllerPortalScreen> createState() =>
      _ControllerPortalScreenState();
}

class _ControllerPortalScreenState
    extends ConsumerState<ControllerPortalScreen> {
  int _selectedNavIndex = 0;

  // Student Form Controllers
  final _studentChaseController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  FestSection _studentSection = FestSection.subJunior;
  String? _studentTeamId;

  // Result Upload Form
  FestSection? _selectedResultSection;
  String? _selectedResultProgId;
  String? _selectedResultStudentId;
  final _resultMarksController = TextEditingController();
  final _resultGradeController = TextEditingController();
  final _resultStudentSearchController = TextEditingController();
  int _resultPosition = 1;
  String _resultsReviewFilter = 'ALL';
  bool _showAllSectionStudents = false;

  // Published Results Management State
  String _pubResultSearchQuery = '';
  String _pubResultSectionFilter = 'ALL';
  String? _pubResultProgramFilter;
  String _pubResultViewMode = 'program'; // 'program' or 'list'
  final _pubResultSearchController = TextEditingController();

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

  // Program Registrations State & Controllers
  String _regSearchQuery = '';
  String _selectedRegSectionFilter = 'ALL';
  String? _selectedRegProgramFilter;
  final _regChaseController = TextEditingController();
  final _regStudentNameController = TextEditingController();
  final _regProgramNameController = TextEditingController();
  FestSection _regSection = FestSection.subJunior;

  // TV Control State & Controllers
  String _tvDraftSearchQuery = '';
  String _tvDraftSectionFilter = 'ALL';
  final _tvDraftSearchController = TextEditingController();

  // Total Section State & Controllers
  String _totalSearchQuery = '';
  String _totalSectionFilter = 'ALL';
  String _totalSortBy = 'marks';
  final _totalSearchController = TextEditingController();


  // Schedule & Venue State & Controllers
  String _selectedScheduleDateFilter = 'ALL';
  String _selectedScheduleVenueFilter = 'ALL';
  String _selectedScheduleStatusFilter = 'ALL';
  final _scheduleSearchController = TextEditingController();
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
    _resultStudentSearchController.dispose();
    _teamNameController.dispose();
    _teamMentorController.dispose();
    _teamLeaderNameController.dispose();
    _teamAssistantLeaderController.dispose();
    _progCodeController.dispose();
    _progNameController.dispose();
    _progMaxParticipantsController.dispose();
    _scheduleSearchController.dispose();
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
    _regChaseController.dispose();
    _regStudentNameController.dispose();
    _regProgramNameController.dispose();
    _pubResultSearchController.dispose();
    _tvDraftSearchController.dispose();
    _totalSearchController.dispose();
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
      SidebarNavItem(
        icon: Icons.app_registration_rounded,
        label: 'Program Registrations',
      ),
      SidebarNavItem(
        icon: Icons.calendar_month_rounded,
        label: 'Schedule & Venue',
      ),
      SidebarNavItem(icon: Icons.rate_review_rounded, label: 'Result Upload'),
      SidebarNavItem(
        icon: Icons.emoji_events_rounded,
        label: 'Published Results',
      ),
      SidebarNavItem(
        icon: Icons.calculate_rounded,
        label: 'Total',
      ),
      SidebarNavItem(icon: Icons.tv_rounded, label: 'TV Control'),
      SidebarNavItem(icon: Icons.upload_file_rounded, label: 'Excel Import'),
      SidebarNavItem(icon: Icons.manage_accounts_rounded, label: 'User Logins'),
      SidebarNavItem(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    Widget mainContent = IndexedStack(
      index: _selectedNavIndex,
      children: [
        // 0. Dashboard
        _buildDashboard(
          studentsAsync,
          teamsAsync,
          programsAsync,
          resultsAsync,
          venuesAsync,
          registrationsAsync,
        ),
        // 1. Students Management
        _buildStudentsSection(studentsAsync, teamsAsync),
        // 2. Teams Management
        _buildTeamsSection(teamsAsync),
        // 3. Programs Management
        _buildProgramsSection(programsAsync, studentsAsync, teamsAsync),
        // 4. Program Registrations Management
        _buildProgramRegistrationsSection(
          registrationsAsync,
          studentsAsync,
          programsAsync,
          teamsAsync,
          schedulesAsync,
          venuesAsync,
          resultsAsync,
        ),
        // 5. Schedule & Venue Management
        _buildScheduleAndVenueSection(
          schedulesAsync,
          venuesAsync,
          programsAsync,
          studentsAsync,
          registrationsAsync,
          teamsAsync,
        ),
        // 6. Result Upload & Verification Workflow
        _buildResultUploadSection(
          programsAsync,
          studentsAsync,
          teamsAsync,
          resultsAsync,
          registrationsAsync,
        ),
        // 7. Published Results Management & Deletion
        _buildPublishedResultsSection(
          resultsAsync,
          programsAsync,
          teamsAsync,
          studentsAsync,
        ),
        // 8. Total Marks & Section Standings
        _buildTotalSection(
          studentsAsync,
          teamsAsync,
          resultsAsync,
          programsAsync,
        ),
        // 9. TV Control & Announcements
        _buildTvControlSection(
          programsAsync,
          resultsAsync,
          studentsAsync,
          teamsAsync,
        ),
        // 9. Excel Import
        _buildExcelImportSection(),
        // 10. User Logins Management (Team Leaders & Jury)
        _buildUserManagementSection(
          usersAsync,
          leadersAsync,
          juriesAsync,
          teamsAsync,
          programsAsync,
        ),
        // 11. Settings & Demo Data Generator
        _buildSettingsSection(),
      ],
    );

    final actions = [
      if (!isMobile) ...[
        Chip(
          avatar: const Icon(Icons.person, size: 16, color: AppTheme.ink),
          label: Text(
            currentUser?.name ?? 'Controller Admin',
            style: GoogleFonts.workSans(
              color: AppTheme.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    AsyncValue<List<Registration>> registrationsAsync,
  ) {
    final students = studentsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    final results = resultsAsync.value ?? [];
    final venues = venuesAsync.value ?? [];
    final registrations = registrationsAsync.value ?? [];

    final pendingDrafts = results
        .where(
          (r) =>
              r.status == ResultStatus.submitted ||
              r.status == ResultStatus.draft,
        )
        .length;
    final publishedCount = results
        .where(
          (r) =>
              r.status == ResultStatus.published ||
              r.status == ResultStatus.announced,
        )
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Performance & Overview',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 1100
                  ? 4
                  : (constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));
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
                  StatCard(
                    title: 'Total Students',
                    value: '${students.length}',
                    icon: Icons.person,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: 'Total Teams',
                    value: '${teams.length}',
                    icon: Icons.groups,
                    color: Colors.purple,
                  ),
                  StatCard(
                    title: 'Programs',
                    value: '${programs.length}',
                    icon: Icons.category,
                    color: Colors.orange,
                  ),
                  StatCard(
                    title: 'Registrations',
                    value: '${registrations.length}',
                    icon: Icons.app_registration_rounded,
                    color: Colors.deepOrange,
                  ),
                  StatCard(
                    title: 'Pending Drafts',
                    value: '$pendingDrafts',
                    icon: Icons.pending_actions,
                    color: Colors.amber,
                    onTap: () => setState(() {
                      _selectedNavIndex = 6;
                      _resultsReviewFilter = 'DRAFT';
                    }),
                  ),
                  StatCard(
                    title: 'Published Results',
                    value: '$publishedCount',
                    icon: Icons.emoji_events,
                    color: Colors.green,
                    onTap: () => setState(() => _selectedNavIndex = 7),
                  ),
                  StatCard(
                    title: 'Active Venues',
                    value: '${venues.length}',
                    icon: Icons.stadium,
                    color: Colors.teal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Program Registration Quick Action Center
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.app_registration_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Program Registration Center',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Register participants to events via Excel spreadsheet (chse no, name, program, setion) or manual entry.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildExcelFormatButton(
                      onTap: _showRegistrationExcelFormatDialog,
                      label: 'Understand Excel Format',
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Upload Registration Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _importRegistrationsFromExcel,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Manual Register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showAddRegistrationDialog(
                        students,
                        programs,
                        teams,
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download Template'),
                      onPressed: () async {
                        final excelService = ref.read(excelServiceProvider);
                        final bytes = excelService.generateRegistrationTemplate();
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: 'registration_excel_template.xlsx',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Downloaded Registrations Excel Template.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('View All Registrations'),
                      onPressed: () {
                        setState(() => _selectedNavIndex = 4);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Top Ranked Teams',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
  Widget _buildStudentsSection(
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Team>> teamsAsync,
  ) {
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
                    Text(
                      'Registered Students (${students.length})',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildExcelFormatButton(
                          onTap: _showStudentTemplateDialog,
                        ),
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
                            excelService.exportStudentsToExcel(
                              students,
                              teamMap,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Exported ${students.length} students to Excel format.',
                                ),
                              ),
                            );
                          },
                        ),
                        if (students.isNotEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_sweep_rounded),
                            label: const Text('Delete All Students'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _confirmDeleteAllStudents(students),
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
                          leading: CircleAvatar(
                            child: Text(s.name.substring(0, 1)),
                          ),
                          title: Text('${s.name} (${s.chaseNumber})'),
                          subtitle: Text(
                            'Team: ${teamMap[s.teamId] ?? s.teamId} • Section: ${s.section.label}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                tooltip: 'View QR Code',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => StudentQrDisplayDialog(
                                      studentName: s.name,
                                      chaseNumber: s.chaseNumber,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
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

  Widget _buildExcelFormatButton({
    required VoidCallback onTap,
    String label = 'Excel Format',
  }) {
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
              label,
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
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF9E2A2B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Program Excel Format (3 Columns)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F5EE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF9E2A2B),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Program Types Supported:',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: const Color(0xFF9E2A2B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1. Stage — Stage event\n'
                          '2. Non-Stage — Off-stage event\n'
                          '3. General — General event',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'When importing programs using Excel, your spreadsheet (.xlsx or .xls) must include these 3 columns in order:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.inkSoft,
                    ),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Program Name',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Section',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Program Type',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Elocution English'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Sub Junior'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Stage'),
                          ),
                        ],
                      ),
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Group Song'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Senior'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Stage'),
                          ),
                        ],
                      ),
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Pencil Drawing'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('General'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Non-Stage'),
                          ),
                        ],
                      ),
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('General Quiz'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('General'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Stage'),
                          ),
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
                        Text(
                          'Rules & Guidelines:',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Program Code is auto-generated automatically.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                        Text(
                          '• Section values: Sub Junior, Senior, Super Senior, General.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                        Text(
                          '• Program Type: Enter "Stage" or "Non-Stage".',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF78350F),
                          ),
                        ),
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
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'program_excel_template.xlsx',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloaded Program Excel Template.'),
                    ),
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

  void _showRegistrationExcelFormatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.table_chart, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Program Registration Excel Format (4 Columns)',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 580,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'To import program registrations, your Excel spreadsheet (.xlsx / .xls) must have these 4 columns in the header row:',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: Colors.grey.shade300),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.6),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.4),
                      },
                      children: const [
                        TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(
                                'chse no',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(
                                'name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(
                                'program',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(
                                'setion',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text('SB7882', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text('JIYAN'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text('QIRATH'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text('SUB JUNOR'),
                            ),
                          ],
                        ),
                        TableRow(
                          decoration: BoxDecoration(color: Color(0xFFFAFBFD)),
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text('SB7165', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text('SAEED ALI'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text('QIRATH'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text('SUB JUNOR'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Column Specifications:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildFormatBullet('chse no', 'Student Chest Number (e.g. SB7882, SB7165).'),
                        _buildFormatBullet('name', 'Candidate / Student full name (e.g. JIYAN, SAEED ALI).'),
                        _buildFormatBullet('program', 'Competition / Program name (e.g. QIRATH). Auto-created if new!'),
                        _buildFormatBullet('setion', 'Category (e.g. SUB JUNOR / Sub Junior, Senior, Super Senior, General).'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Auto-creates students and programs if they are not already in the system. Duplicate registrations are automatically skipped.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Download Template'),
              onPressed: () async {
                final excelService = ref.read(excelServiceProvider);
                final bytes = excelService.generateRegistrationTemplate();
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'registration_excel_template.xlsx',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloaded Registrations Excel Template.'),
                    ),
                  );
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('Upload Excel File Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _importRegistrationsFromExcel();
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

  Widget _buildFormatBullet(String colName, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $colName: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
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
                const Text(
                  'When importing students using Excel, your file must have these 4 columns:',
                ),
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
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Chase Number',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Section',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Team Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('101')),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('John Doe'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Sub Junior'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Tigrees'),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('102')),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Sarah Smith'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Sub Junior'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Eagles'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note: Section can be "Sub Junior", "Senior", "Super Senior", or "General". If the Team Name does not exist, it will be automatically created.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                const Text(
                  'When importing teams using Excel, your file must have these 4 columns:',
                ),
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
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Team Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Mentor Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Leader Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Assistant Leader',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Tigrees'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Dr. Alex'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('John Doe'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Sarah Smith'),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Eagles'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Prof. David'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Michael Brown'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Emma Watson'),
                        ),
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
            title: Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
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
        _showLoadingDialog(
          'Importing Students',
          'Processing Excel file and adding students...\nPlease wait.',
        );

        try {
          final bytes = await files.first.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importStudents(bytes);
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog(
              'Students Excel Import Summary',
              importResult,
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to import Excel file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select Excel file: $e'),
            backgroundColor: Colors.red,
          ),
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
        _showLoadingDialog(
          'Importing Programs',
          'Processing Excel file and adding programs...\nPlease wait.',
        );

        try {
          final bytes = await files.first.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importPrograms(bytes);
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog(
              'Programs Excel Import Summary',
              importResult,
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to import Excel file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select Excel file: $e'),
            backgroundColor: Colors.red,
          ),
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
        _showLoadingDialog(
          'Importing Schedules',
          'Processing PDF or Excel file with Date, Program, Time, Venue & Category...\nPlease wait.',
        );

        try {
          final file = files.first;
          final bytes = await file.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importSchedules(
            bytes,
            file.name,
          );
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog('Schedule Import Summary', importResult);
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to import file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportSchedulesToExcel(
    List<Schedule> schedules,
    Map<String, Program> progMap,
    Map<String, Venue> venMap,
  ) async {
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No schedules available to export.')),
      );
      return;
    }
    try {
      final excelService = ref.read(excelServiceProvider);
      final bytes = excelService.exportSchedulesToExcel(
        schedules,
        progMap,
        venMap,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'master_schedule_export.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${schedules.length} schedules to Excel format.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadScheduleTemplate() async {
    try {
      final excelService = ref.read(excelServiceProvider);
      final bytes = excelService.generateScheduleTemplate();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'schedule_excel_template.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Downloaded Schedule Excel Template (Date, Program, Time, Venue, Section).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showScheduleExcelFormatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Schedule Excel Format Instructions',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload schedule data in standard Excel format (.xlsx / .xls). Expected sheet columns:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.inkSoft,
                  ),
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
                      Text(
                        'Column 1: DATE (e.g. 2026-09-05)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Column 2: ITEM (e.g. ESSAY ARB / P-101)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Column 3: TIME (e.g. 6:00 TO 6:45 am)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Column 4: VENUE / VIWE (e.g. S1 / Main Auditorium)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Column 5: CATEGORY / CATOGARY (SENIOR / Sub Junior / General)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Programs and Venues not yet in system will be automatically created upon import.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  '• Start and End times are automatically parsed from time ranges.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                  ),
                ),
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
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.red,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Clear All Dummy Schedules?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
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
                    const SnackBar(
                      content: Text('All dummy schedule data cleared.'),
                      backgroundColor: AppTheme.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmResetOfficialVenues(
    List<Venue> currentVenues,
    List<Schedule> currentSchedules,
  ) {
    bool isProcessing = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(
                    Icons.cleaning_services_rounded,
                    color: Colors.teal,
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text('Reset Official Venues'),
                ],
              ),
              content: isProcessing
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Organizing venues... Please wait.'),
                      ],
                    )
                  : const Text(
                      'This will clean up any orphaned venue entries and ensure all 6 official festival venues (S1, S2, S8, S3, LIBRARY, Auditorium) are active in the system.',
                    ),
              actions: [
                if (!isProcessing)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                if (!isProcessing)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      setModalState(() => isProcessing = true);
                      try {
                        final venueRepo = ref.read(venueRepositoryProvider);
                        final usedVenueIds =
                            currentSchedules.map((s) => s.venueId).toSet();
                        final officialNames = [
                          'S1',
                          'S2',
                          'S8',
                          'S3',
                          'LIBRARY',
                          'Auditorium'
                        ];

                        // Delete orphaned venues not in official list and not in schedules
                        for (final v in currentVenues) {
                          final isUsed = usedVenueIds.contains(v.id);
                          final isOfficial = officialNames.any((name) =>
                              v.name.trim().toLowerCase() ==
                              name.toLowerCase());
                          if (!isUsed && !isOfficial) {
                            try {
                              await venueRepo.deleteVenue(v.id);
                            } catch (_) {}
                          }
                        }

                        // Ensure each official venue exists
                        for (final name in officialNames) {
                          final exists = currentVenues.any((v) =>
                              v.name.trim().toLowerCase() ==
                              name.toLowerCase());
                          if (!exists) {
                            try {
                              await venueRepo.addVenue(
                                Venue(
                                  id:
                                      'ven_${name.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                                  name: name,
                                  location: 'Main Site',
                                  capacity: name == 'Auditorium' ? 500 : 100,
                                  description: 'Official Fest Venue',
                                ),
                              );
                            } catch (_) {}
                          }
                        }
                      } finally {
                        triggerDataRefresh(ref);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Official venues verified: S1, S2, S8, S3, LIBRARY, Auditorium',
                              ),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Confirm Reset'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImportResultDialog(String title, ExcelImportResult result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.analytics, color: Colors.blue),
                  title: const Text('Total Rows Processed'),
                  trailing: Text(
                    '${result.totalRows}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Successfully Imported'),
                  trailing: Text(
                    '${result.importedRows}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                if (result.duplicateRows > 0)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.copy, color: Colors.orange),
                    title: const Text('Duplicates Skipped'),
                    trailing: Text(
                      '${result.duplicateRows}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                if (result.invalidRows > 0)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Invalid / Failed Rows'),
                    trailing: Text(
                      '${result.invalidRows}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                if (result.errors.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Error Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: result.errors
                            .map(
                              (err) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  '• $err',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Confirm Student Deletion'),
          content: Text(
            'Are you sure you want to delete student "${student.name}" (Chase #: ${student.chaseNumber})? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogCtx);
                await ref
                    .read(studentRepositoryProvider)
                    .deleteStudent(student.id);
                triggerDataRefresh(ref);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Student "${student.name}" deleted successfully.',
                    ),
                  ),
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
                AppTextField(
                  label: 'Chase Number',
                  controller: _studentChaseController,
                  hint: 'e.g. 101',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Full Name',
                  controller: _studentNameController,
                ),
                const SizedBox(height: 10),
                AppDropdown<FestSection>(
                  label: 'Section',
                  value: _studentSection,
                  items: FestSection.values
                      .where((s) => s != FestSection.general)
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _studentSection = val);
                  },
                ),
                const SizedBox(height: 10),
                AppDropdown<String>(
                  label: 'Team',
                  value:
                      _studentTeamId ??
                      (teams.isNotEmpty ? teams.first.id : null),
                  items: teams
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.teamName),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _studentTeamId = val),
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
                final student = Student(
                  id: const Uuid().v4(),
                  chaseNumber: _studentChaseController.text.trim(),
                  name: _studentNameController.text.trim(),
                  gender: 'Male',
                  dateOfBirth: '2010-01-01',
                  section: _studentSection,
                  teamId:
                      _studentTeamId ??
                      (teams.isNotEmpty ? teams.first.id : 'default'),
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

  void _confirmDeleteAllStudents(List<Student> students) {
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Confirm Delete All Students'),
              content: isDeleting
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Deleting students... Please wait.'),
                      ],
                    )
                  : Text(
                      'Are you sure you want to delete all ${students.length} students? This action cannot be undone and will delete associated candidate registrations.',
                    ),
              actions: [
                if (!isDeleting)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                if (!isDeleting)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      setModalState(() => isDeleting = true);
                      int successCount = 0;
                      int failCount = 0;
                      try {
                        final repo = ref.read(studentRepositoryProvider);
                        final uniqueStudents = {
                          for (var s in students) s.id: s,
                        }.values.toList();
                        for (final s in uniqueStudents) {
                          try {
                            await repo.deleteStudent(s.id);
                            successCount++;
                          } catch (_) {
                            failCount++;
                          }
                        }
                      } finally {
                        triggerDataRefresh(ref);
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (failCount == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All students deleted successfully.'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deleted $successCount students. $failCount failed.',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Delete All'),
                  ),
              ],
            );
          },
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
                    Text(
                      'Registered Teams (${teams.length})',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                              SnackBar(
                                content: Text(
                                  'Exported ${teams.length} teams to Excel format.',
                                ),
                              ),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.group_add),
                          label: const Text('Add New Team'),
                          onPressed: _showAddTeamDialog,
                        ),
                        if (teams.isNotEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_sweep_rounded),
                            label: const Text('Delete All Teams'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _confirmDeleteAllTeams(teams),
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
                            child: Text(
                              '#${idx + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(t.teamName),
                          subtitle: Text(
                            'Mentor: $mentorStr • Leader: $leaderStr • Asst: $asstStr',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rank #${t.rank > 0 ? t.rank : idx + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blueAccent,
                                ),
                                tooltip: 'Edit Team',
                                onPressed: () => _showEditTeamDialog(t),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
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
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Confirm Team Deletion'),
          content: Text(
            'Are you sure you want to delete team "${team.teamName}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogCtx);
                await ref.read(teamRepositoryProvider).deleteTeam(team.id);
                triggerDataRefresh(ref);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Team "${team.teamName}" deleted successfully.',
                    ),
                  ),
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
        _showLoadingDialog(
          'Importing Teams',
          'Processing Excel file and adding teams...\nPlease wait.',
        );

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
              SnackBar(
                content: Text('Failed to import Excel file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select Excel file: $e'),
            backgroundColor: Colors.red,
          ),
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
        _showLoadingDialog(
          'Importing Registrations',
          'Processing Excel file and adding registrations...\nPlease wait.',
        );

        try {
          final bytes = await files.first.readAsBytes();
          final excelService = ref.read(excelServiceProvider);
          final importResult = await excelService.importRegistrations(bytes);
          triggerDataRefresh(ref);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showImportResultDialog(
              'Registrations Excel Import Summary',
              importResult,
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to import Excel file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select Excel file: $e'),
            backgroundColor: Colors.red,
          ),
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
                          final inputLeaderName = _teamLeaderNameController.text
                              .trim();
                          final assistant = _teamAssistantLeaderController.text
                              .trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Team Name is required!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final code =
                              'T-${name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '')}';

                          final currentTeams =
                              ref.read(teamsProvider).value ?? [];
                          final isDuplicate = currentTeams.any(
                            (t) =>
                                t.teamName.trim().toLowerCase() ==
                                    name.toLowerCase() ||
                                t.teamCode.toUpperCase() == code.toUpperCase(),
                          );

                          if (isDuplicate) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'A team named "$name" already exists! Please enter a unique team name.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final teamId = 'team_${const Uuid().v4()}';
                          final leaderName = inputLeaderName.isNotEmpty
                              ? inputLeaderName
                              : '$name Leader';
                          final cleanUser =
                              (inputLeaderName.isNotEmpty
                                      ? inputLeaderName
                                      : name)
                                  .toLowerCase()
                                  .replaceAll(RegExp(r'[^a-z0-9]'), '');
                          final leaderUsername = cleanUser.isEmpty
                              ? 'team_${code.toLowerCase()}'
                              : cleanUser;
                          final leaderPassword = '${leaderUsername}123';
                          final leaderId = 'leader_$teamId';

                          final team = Team(
                            id: teamId,
                            teamName: name,
                            teamCode: code,
                            mentorName: mentor.isNotEmpty ? mentor : null,
                            leaderName: leaderName,
                            assistantLeaderName: assistant.isNotEmpty
                                ? assistant
                                : null,
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
                              ref
                                  .read(leaderRepositoryProvider)
                                  .addLeader(leaderProfile),
                              ref
                                  .read(userRepositoryProvider)
                                  .saveUser(leaderUser),
                            ]);

                            triggerDataRefresh(ref);

                            _teamNameController.clear();
                            _teamMentorController.clear();
                            _teamLeaderNameController.clear();
                            _teamAssistantLeaderController.clear();

                            if (context.mounted) Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Team "$name" added! Leader: $leaderUsername | Pass: $leaderPassword',
                                ),
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
                              final isDup =
                                  errStr.contains('23505') ||
                                  errStr.contains('duplicate key') ||
                                  errStr.contains('teams_teamCode_key');
                              final displayMsg = isDup
                                  ? 'A team with name/code "$name" already exists in database! Please choose a unique name.'
                                  : 'Error adding team to database: $e';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(displayMsg),
                                  backgroundColor: isDup
                                      ? Colors.orange
                                      : Colors.red,
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
    final assistantController = TextEditingController(
      text: team.assistantLeaderName ?? '',
    );
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
                              const SnackBar(
                                content: Text('Team Name is required!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final updatedTeam = team.copyWith(
                            teamName: newName,
                            mentorName: newMentor.isNotEmpty ? newMentor : null,
                            leaderName: newLeader.isNotEmpty ? newLeader : null,
                            assistantLeaderName: newAssistant.isNotEmpty
                                ? newAssistant
                                : null,
                          );

                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            await ref
                                .read(teamRepositoryProvider)
                                .updateTeam(updatedTeam);
                            ref.invalidate(teamsProvider);
                            triggerDataRefresh(ref);

                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Team "$newName" updated successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            final cleanErr = e.toString().replaceFirst(
                              RegExp(r'^Exception:\s*'),
                              '',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(cleanErr),
                                  backgroundColor: Colors.red,
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

  void _confirmDeleteAllTeams(List<Team> teams) {
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Confirm Delete All Teams'),
              content: isDeleting
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Deleting teams... Please wait.'),
                      ],
                    )
                  : Text(
                      'Are you sure you want to delete all ${teams.length} teams? This action cannot be undone.',
                    ),
              actions: [
                if (!isDeleting)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                if (!isDeleting)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      setModalState(() => isDeleting = true);
                      int successCount = 0;
                      int failCount = 0;
                      try {
                        final repo = ref.read(teamRepositoryProvider);
                        final uniqueTeams = {
                          for (var t in teams) t.id: t,
                        }.values.toList();
                        for (final t in uniqueTeams) {
                          try {
                            await repo.deleteTeam(t.id);
                            successCount++;
                          } catch (_) {
                            failCount++;
                          }
                        }
                      } finally {
                        triggerDataRefresh(ref);
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (failCount == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All teams deleted successfully.'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deleted $successCount teams. $failCount failed.',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Delete All'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 3. PROGRAMS SECTION ---
  Widget _buildProgramsSection(
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Team>> teamsAsync,
  ) {
    final students = studentsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];

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
                    Text(
                      'Fest Programs (${programs.length})',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PopupMenuButton<String>(
                          tooltip: 'Program Registration Options',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade400),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.app_registration_rounded,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Register Candidates',
                                  style: GoogleFonts.inter(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          onSelected: (val) {
                            if (val == 'format') {
                              _showRegistrationExcelFormatDialog();
                            } else if (val == 'upload') {
                              _importRegistrationsFromExcel();
                            } else if (val == 'manual') {
                              _showAddRegistrationDialog(
                                students,
                                programs,
                                teams,
                              );
                            } else if (val == 'view') {
                              setState(() => _selectedNavIndex = 4);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'format',
                              child: ListTile(
                                leading: Icon(
                                  Icons.help_outline,
                                  color: Colors.orange,
                                ),
                                title: Text('Understand Excel Format'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'upload',
                              child: ListTile(
                                leading: Icon(
                                  Icons.upload_file,
                                  color: Colors.blue,
                                ),
                                title: Text('Upload Registrations Excel'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'manual',
                              child: ListTile(
                                leading: Icon(
                                  Icons.person_add_alt_1,
                                  color: Colors.green,
                                ),
                                title: Text('Manual Register'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'view',
                              child: ListTile(
                                leading: Icon(
                                  Icons.table_rows,
                                  color: Colors.purple,
                                ),
                                title: Text('View All Registrations'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        _buildExcelFormatButton(
                          onTap: _showProgramExcelFormatDialog,
                        ),
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
                            final bytes = excelService.exportProgramsToExcel(
                              programs,
                            );
                            await Printing.sharePdf(
                              bytes: bytes,
                              filename: 'programs_export.xlsx',
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Exported ${programs.length} programs to Excel format.',
                                  ),
                                ),
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
                            style: GoogleFonts.inter(
                              color: AppTheme.inkSoft,
                              fontSize: 14,
                            ),
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
                                  backgroundColor: isGroupEvent
                                      ? Colors.purple.shade50
                                      : Colors.blue.shade50,
                                  child: Icon(
                                    isGroupEvent
                                        ? Icons.groups_rounded
                                        : Icons.person_rounded,
                                    color: isGroupEvent
                                        ? Colors.purple
                                        : Colors.blue,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      p.programName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isGroupEvent
                                            ? Colors.purple.shade100
                                            : Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isGroupEvent
                                            ? 'Group (${p.maxParticipants} max)'
                                            : 'Single',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isGroupEvent
                                              ? Colors.purple.shade900
                                              : Colors.blue.shade900,
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
                                      icon: const Icon(
                                        Icons.person_add_alt_1,
                                        color: Colors.green,
                                      ),
                                      tooltip: 'Register Candidate for this Program',
                                      onPressed: () => _showAddRegistrationDialog(
                                        students,
                                        programs,
                                        teams,
                                        defaultProgram: p,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blueAccent,
                                      ),
                                      tooltip: 'Edit Program',
                                      onPressed: () => _showEditProgramDialog(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
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
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => _progSection = val);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    AppDropdown<String>(
                      label: 'Program Type',
                      value: progType,
                      items: const [
                        DropdownMenuItem(value: 'STAGE', child: Text('Stage')),
                        DropdownMenuItem(
                          value: 'NON_STAGE',
                          child: Text('Non-Stage'),
                        ),
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
                        : (isStage
                              ? ProgramCategory.stage
                              : ProgramCategory.nonStage);

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Program Name is required!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Auto-generate code
                    final programs = ref.read(programsProvider).value ?? [];
                    final existingCodes = programs
                        .map((p) => p.programCode.trim().toLowerCase())
                        .toSet();
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
                      await ref
                          .read(programRepositoryProvider)
                          .addProgram(program);
                      print(
                        '[Flutter UI] addProgram succeeded, triggering data refresh',
                      );
                      triggerDataRefresh(ref);

                      _progNameController.clear();

                      if (mounted) navigator.pop();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Program "$name" ($code) created successfully!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      print('[Flutter UI] addProgram failed: $e');
                      if (mounted) navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to save program: $e'),
                          backgroundColor: Colors.red,
                        ),
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
    final codeController = TextEditingController(text: program.programCode);
    final nameController = TextEditingController(text: program.programName);
    final durationController = TextEditingController(text: program.duration);
    final maxParticipantsController =
        TextEditingController(text: program.maxParticipants.toString());

    FestSection section = availableSections.contains(program.section)
        ? program.section
        : FestSection.subJunior;
    String progType = program.isStageProgram ? 'STAGE' : 'NON_STAGE';
    String progStatus = program.status.isNotEmpty ? program.status : 'UPCOMING';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Program: ${program.programName}'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              label: 'Program Code',
                              controller: codeController,
                              hint: 'e.g. P101',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: AppDropdown<String>(
                              label: 'Status',
                              value: ['UPCOMING', 'IN_PROGRESS', 'COMPLETED']
                                      .contains(progStatus)
                                  ? progStatus
                                  : 'UPCOMING',
                              items: const [
                                DropdownMenuItem(
                                  value: 'UPCOMING',
                                  child: Text('Upcoming'),
                                ),
                                DropdownMenuItem(
                                  value: 'IN_PROGRESS',
                                  child: Text('In Progress'),
                                ),
                                DropdownMenuItem(
                                  value: 'COMPLETED',
                                  child: Text('Completed'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => progStatus = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'Program Name *',
                        controller: nameController,
                        hint: 'e.g. Solo Violin',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AppDropdown<FestSection>(
                              label: 'Section',
                              value: section,
                              items: availableSections
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => section = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Program Type',
                              value: progType,
                              items: const [
                                DropdownMenuItem(value: 'STAGE', child: Text('Stage')),
                                DropdownMenuItem(
                                  value: 'NON_STAGE',
                                  child: Text('Non-Stage'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    progType = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Duration',
                              controller: durationController,
                              hint: 'e.g. 15 mins',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              label: 'Max Candidates / Team',
                              controller: maxParticipantsController,
                              hint: 'e.g. 1 (Single) or 5 (Group)',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                    final code = codeController.text.trim();
                    final duration = durationController.text.trim();
                    final maxPart = int.tryParse(maxParticipantsController.text.trim()) ?? 1;
                    final isStage = progType == 'STAGE';
                    final isGeneral = section == FestSection.general;
                    final category = isGeneral
                        ? ProgramCategory.general
                        : (isStage
                            ? ProgramCategory.stage
                            : ProgramCategory.nonStage);

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Program Name is required!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final updated = program.copyWith(
                      programCode: code.isNotEmpty ? code : program.programCode,
                      programName: name,
                      section: section,
                      category: category,
                      isStageProgram: isStage,
                      isGeneral: isGeneral,
                      duration: duration.isNotEmpty ? duration : program.duration,
                      maxParticipants: maxPart,
                      status: progStatus,
                    );

                    try {
                      await ref
                          .read(programRepositoryProvider)
                          .updateProgram(updated);
                      triggerDataRefresh(ref);

                      if (mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Program "$name" updated successfully!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update program: $e'),
                          backgroundColor: Colors.red,
                        ),
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
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Confirm Program Deletion'),
          content: Text(
            'Are you sure you want to delete program "${program.programName}" (${program.programCode})? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(programRepositoryProvider)
                      .deleteProgram(program.id);
                  triggerDataRefresh(ref);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Program "${program.programName}" deleted successfully.',
                      ),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
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
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirm Delete All Programs'),
              content: isDeleting
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Deleting programs... This may take a while.'),
                      ],
                    )
                  : Text(
                      'Are you sure you want to delete all ${programs.length} programs? This action cannot be undone and will delete associated schedules and results.',
                    ),
              actions: [
                if (!isDeleting)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                if (!isDeleting)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      setState(() => isDeleting = true);
                      int successCount = 0;
                      int failCount = 0;
                      try {
                        final repo = ref.read(programRepositoryProvider);
                        final uniquePrograms = {
                          for (var p in programs) p.id: p,
                        }.values.toList();
                        for (final p in uniquePrograms) {
                          try {
                            await repo.deleteProgram(p.id);
                            successCount++;
                          } catch (e) {
                            failCount++;
                          }
                        }
                      } finally {
                        triggerDataRefresh(ref);
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (failCount == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'All programs deleted successfully.',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deleted $successCount programs. $failCount failed (maybe already deleted).',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Delete All'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // --- PROGRAM REGISTRATIONS MANAGEMENT SECTION ---
  Widget _buildProgramRegistrationsSection(
    AsyncValue<List<Registration>> registrationsAsync,
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Team>> teamsAsync, [
    AsyncValue<List<Schedule>>? schedulesAsync,
    AsyncValue<List<Venue>>? venuesAsync,
    AsyncValue<List<Result>>? resultsAsync,
  ]) {
    final students = studentsAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];
    final schedules = schedulesAsync?.value ?? ref.watch(schedulesProvider).value ?? [];
    final venues = venuesAsync?.value ?? ref.watch(venuesProvider).value ?? [];
    final results = resultsAsync?.value ?? ref.watch(resultsProvider).value ?? [];
    final studentMap = {for (var s in students) s.id: s};
    final programMap = {for (var p in programs) p.id: p};
    final teamMap = {for (var t in teams) t.id: t};

    Student? findStudent(String id) {
      if (studentMap.containsKey(id)) return studentMap[id];
      final lowerId = id.trim().toLowerCase();
      return students
          .where((s) =>
              s.id.toLowerCase() == lowerId ||
              s.chaseNumber.trim().toLowerCase() == lowerId)
          .firstOrNull;
    }

    Program? findProgram(String id) {
      if (programMap.containsKey(id)) return programMap[id];
      final lowerId = id.trim().toLowerCase();
      return programs
          .where((p) =>
              p.id.toLowerCase() == lowerId ||
              p.programCode.trim().toLowerCase() == lowerId ||
              p.programName.trim().toLowerCase() == lowerId)
          .firstOrNull;
    }

    return Scaffold(
      body: registrationsAsync.when(
        data: (registrations) {
          // Distinct counts
          final distinctStudentsCount =
              registrations.map((r) => r.studentId).toSet().length;
          final distinctProgramsCount =
              registrations.map((r) => r.programId).toSet().length;
          final subJuniorCount = registrations.where((r) {
            final s = findStudent(r.studentId);
            final p = findProgram(r.programId);
            return s?.section == FestSection.subJunior ||
                p?.section == FestSection.subJunior;
          }).length;
          final seniorCount = registrations.where((r) {
            final s = findStudent(r.studentId);
            final p = findProgram(r.programId);
            return s?.section == FestSection.senior ||
                p?.section == FestSection.senior;
          }).length;

          // Filter registrations
          final filtered = registrations.where((r) {
            final student = findStudent(r.studentId);
            final prog = findProgram(r.programId);

            String chase = student?.chaseNumber.toLowerCase() ?? '';
            String name = student?.name.toLowerCase() ?? '';
            String progName = prog?.programName.toLowerCase() ?? '';
            String regNum = r.registrationNumber.toLowerCase();

            if (chase.isEmpty && regNum.startsWith('reg-')) {
              final parts = regNum.split('-');
              if (parts.length >= 2) {
                chase = parts[1];
              }
            }

            final q = _regSearchQuery.trim().toLowerCase();
            if (q.isNotEmpty) {
              final match = chase.contains(q) ||
                  name.contains(q) ||
                  progName.contains(q) ||
                  regNum.contains(q);
              if (!match) return false;
            }

            if (_selectedRegSectionFilter != 'ALL') {
              final filterClean = _selectedRegSectionFilter
                  .replaceAll(RegExp(r'[\s\-_]'), '')
                  .toLowerCase();
              final progSecNameClean = prog?.section.name
                  .replaceAll(RegExp(r'[\s\-_]'), '')
                  .toLowerCase();
              final progSecLabelClean = prog?.section.label
                  .replaceAll(RegExp(r'[\s\-_]'), '')
                  .toLowerCase();
              final studSecNameClean = student?.section.name
                  .replaceAll(RegExp(r'[\s\-_]'), '')
                  .toLowerCase();
              final studSecLabelClean = student?.section.label
                  .replaceAll(RegExp(r'[\s\-_]'), '')
                  .toLowerCase();

              final matchProg = (progSecNameClean == filterClean ||
                  progSecLabelClean == filterClean);
              final matchStud = (studSecNameClean == filterClean ||
                  studSecLabelClean == filterClean);

              if (!matchProg && !matchStud) {
                return false;
              }
            }

            if (_selectedRegProgramFilter != null &&
                _selectedRegProgramFilter != 'ALL') {
              if (r.programId != _selectedRegProgramFilter &&
                  prog?.id != _selectedRegProgramFilter) {
                return false;
              }
            }

            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header & Action Buttons
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Text(
                      'Program Registrations (${registrations.length})',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildExcelFormatButton(
                          onTap: _showRegistrationExcelFormatDialog,
                          label: 'Understand Excel Format',
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Upload Registrations Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _importRegistrationsFromExcel,
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Template'),
                          onPressed: () async {
                            final excelService =
                                ref.read(excelServiceProvider);
                            final bytes =
                                excelService.generateRegistrationTemplate();
                            await Printing.sharePdf(
                              bytes: bytes,
                              filename: 'registration_excel_template.xlsx',
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Downloaded Registrations Excel Template.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.file_download),
                          label: const Text('Export Excel'),
                          onPressed: () async {
                            final excelService =
                                ref.read(excelServiceProvider);
                            final bytes =
                                excelService.exportRegistrationsToExcel(
                              registrations,
                              studentMap: studentMap,
                              programMap: programMap,
                              teamMap: teamMap,
                            );
                            await Printing.sharePdf(
                              bytes: bytes,
                              filename: 'program_registrations_export.xlsx',
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Exported ${registrations.length} registrations to Excel format.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Register Program'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showAddRegistrationDialog(
                            students,
                            programs,
                            teams,
                          ),
                        ),
                        if (registrations.isNotEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete_sweep_rounded),
                            label: const Text('Delete All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                _confirmDeleteAllRegistrations(registrations),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metric Cards
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildRegMetricCard(
                      'Total Registrations',
                      registrations.length.toString(),
                      Icons.app_registration_rounded,
                      Colors.blue,
                    ),
                    _buildRegMetricCard(
                      'Registered Students',
                      distinctStudentsCount.toString(),
                      Icons.people_rounded,
                      Colors.purple,
                    ),
                    _buildRegMetricCard(
                      'Active Programs',
                      distinctProgramsCount.toString(),
                      Icons.category_rounded,
                      Colors.teal,
                    ),
                    _buildRegMetricCard(
                      'Sub Junior Regs',
                      subJuniorCount.toString(),
                      Icons.child_care_rounded,
                      Colors.orange,
                    ),
                    _buildRegMetricCard(
                      'Senior Regs',
                      seniorCount.toString(),
                      Icons.school_rounded,
                      Colors.indigo,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search & Filter Bar
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search by Chest No (e.g. SB7886), Student Name, or Program...',
                                  prefixIcon: Icon(Icons.search),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _regSearchQuery = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Section:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            for (final sec in [
                              'ALL',
                              'SUB_JUNIOR',
                              'SENIOR',
                              'SUPER_SENIOR',
                              'GENERAL',
                              'GROUP'
                            ])
                              FilterChip(
                                label: Text(sec.replaceAll('_', ' ')),
                                selected: _selectedRegSectionFilter == sec,
                                onSelected: (sel) {
                                  setState(() {
                                    _selectedRegSectionFilter =
                                        sel ? sec : 'ALL';
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Registrations Data List
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.app_registration_outlined,
                            size: 54,
                            color: AppTheme.inkSoft,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            registrations.isEmpty
                                ? 'No program registrations found yet.'
                                : 'No registrations matching your search/filter.',
                            style: GoogleFonts.inter(
                              color: AppTheme.inkSoft,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildExcelFormatButton(
                                onTap: _showRegistrationExcelFormatDialog,
                                label: 'Understand Excel Format',
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.file_upload),
                                label: const Text('Upload Registrations Excel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _importRegistrationsFromExcel,
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Register Program'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _showAddRegistrationDialog(
                                  students,
                                  programs,
                                  teams,
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.download),
                                label: const Text('Download Template'),
                                onPressed: () async {
                                  final excelService =
                                      ref.read(excelServiceProvider);
                                  final bytes = excelService
                                      .generateRegistrationTemplate();
                                  await Printing.sharePdf(
                                    bytes: bytes,
                                    filename:
                                        'registration_excel_template.xlsx',
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final r = filtered[idx];
                      final s = findStudent(r.studentId);
                      final p = findProgram(r.programId);
                      final t = teamMap[r.teamId.isNotEmpty
                          ? r.teamId
                          : (s?.teamId ?? '')];
                      String chaseNo = s?.chaseNumber ?? '';
                      String studentName = s?.name ?? '';
                      String progName = p?.programName ?? '';

                      if (chaseNo.isEmpty && r.registrationNumber.startsWith('REG-')) {
                        final parts = r.registrationNumber.split('-');
                        if (parts.length >= 2) {
                          chaseNo = parts[1];
                        }
                        if (parts.length >= 3 && progName.isEmpty) {
                          progName = parts.sublist(2).join('-');
                        }
                      }
                      if (studentName.isEmpty) {
                        studentName = chaseNo.isNotEmpty
                            ? 'Student ($chaseNo)'
                            : 'Student #${r.studentId}';
                      }
                      if (progName.isEmpty) {
                        progName = 'Program #${r.programId}';
                      }
                      if (chaseNo.isEmpty) {
                        chaseNo = '-';
                      }
                      final sectionLabel = p?.section.label ??
                          s?.section.label ??
                          'Sub Junior';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _showEditRegistrationDialog(
                            r,
                            students,
                            programs,
                            teams,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            child: Text(
                              chaseNo,
                              style: GoogleFonts.workSans(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  studentName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                child: Text(
                                  r.status.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.category_rounded,
                                    size: 14,
                                    color: AppTheme.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    progName,
                                    style: GoogleFonts.workSans(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    labelPadding: EdgeInsets.zero,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    visualDensity:
                                        VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: AppTheme.cream,
                                    side: const BorderSide(
                                      color: AppTheme.line,
                                    ),
                                    label: Text(
                                      sectionLabel,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Schedule Details: Date, Day, Time, Venue
                              Builder(
                                builder: (ctx) {
                                  final sched = schedules.where((sc) {
                                    final scProg = sc.programId.trim().toLowerCase();
                                    final rProg = r.programId.trim().toLowerCase();
                                    if (scProg == rProg) return true;
                                    if (p != null) {
                                      if (scProg == p.id.trim().toLowerCase()) return true;
                                      if (scProg == p.programCode.trim().toLowerCase()) return true;
                                      if (scProg == p.programName.trim().toLowerCase()) return true;
                                    }
                                    return false;
                                  }).firstOrNull;

                                  final ven = sched != null
                                      ? venues.where((v) =>
                                          v.id.trim().toLowerCase() == sched.venueId.trim().toLowerCase() ||
                                          v.name.trim().toLowerCase() == sched.venueId.trim().toLowerCase()).firstOrNull
                                      : null;
                                  final venName = ven?.name ?? (sched?.venueId.isNotEmpty == true ? sched!.venueId : 'Venue TBA');

                                  if (sched != null) {
                                    String dateText = sched.date;
                                    String dayText = 'Day TBA';
                                    final parsedDt = DateTime.tryParse(sched.date);
                                    if (parsedDt != null) {
                                      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                      dateText = '${parsedDt.day} ${months[parsedDt.month - 1]} ${parsedDt.year}';
                                      dayText = weekdays[parsedDt.weekday - 1];
                                    } else if (sched.date.toLowerCase().contains('day')) {
                                      dayText = sched.date;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(top: 3, bottom: 3),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text('📅 Date: $dateText', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                          Text('🗓️ Day: $dayText', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo.shade900)),
                                          Text('⏰ ${sched.startTime} - ${sched.endTime}', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                          Text('📍 $venName', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                                      child: Text(
                                        '📅 Schedule: Date, Day, Time & Venue TBA',
                                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                      ),
                                    );
                                  }
                                },
                              ),
                              // Published Result (if available)
                              Builder(
                                builder: (ctx) {
                                  final pubRes = results.where((res) {
                                    final rStud = res.studentId.trim().toLowerCase();
                                    final sChase = s?.chaseNumber.trim().toLowerCase() ?? '';
                                    final sId = s?.id.trim().toLowerCase() ?? '';
                                    final matchStud = (sChase.isNotEmpty && rStud == sChase) ||
                                        (sId.isNotEmpty && rStud == sId) ||
                                        (rStud == r.studentId.trim().toLowerCase());
                                    final matchProg = res.programId.trim().toLowerCase() == r.programId.trim().toLowerCase() ||
                                        (p != null && res.programId.trim().toLowerCase() == p.id.trim().toLowerCase());
                                    final isPub = res.status == ResultStatus.published || res.publishedAt != null;
                                    return matchStud && matchProg && isPub;
                                  }).firstOrNull;

                                  if (pubRes != null) {
                                    return Container(
                                      margin: const EdgeInsets.only(top: 4, bottom: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.emoji_events, size: 13, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Result: Position #${pubRes.position ?? "-"} • Grade ${pubRes.grade} • +${pubRes.points} pts (Published)',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reg #: ${r.registrationNumber} • Team: ${t?.teamName ?? "-"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blueAccent,
                                ),
                                tooltip: 'Edit Registration Details',
                                onPressed: () => _showEditRegistrationDialog(
                                  r,
                                  students,
                                  programs,
                                  teams,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Registration',
                                onPressed: () => _confirmDeleteRegistration(
                                  r,
                                  studentName,
                                  progName,
                                ),
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading registrations: $err')),
      ),
    );
  }

  Widget _buildRegMetricCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRegistrationDialog(
    List<Student> students,
    List<Program> programs,
    List<Team> teams, {
    Program? defaultProgram,
  }) {
    _regChaseController.clear();
    _regStudentNameController.clear();
    _regProgramNameController.text = defaultProgram?.programName ?? '';
    _regSection = defaultProgram?.section ?? FestSection.subJunior;

    final availableSections = FestSection.values.toList();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.app_registration_rounded, color: AppTheme.red),
                  SizedBox(width: 8),
                  Text('Register Student to Program'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter student and program details matching the registration form:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),

                      // Chest No input with auto-matching existing student
                      AppTextField(
                        label: 'Chest No (chse no) *',
                        controller: _regChaseController,
                        hint: 'e.g. SB7882',
                        onChanged: (val) {
                          final clean = val.trim().toLowerCase();
                          final matched = students
                              .where((s) =>
                                  s.chaseNumber.trim().toLowerCase() == clean)
                              .firstOrNull;
                          if (matched != null) {
                            setDialogState(() {
                              _regStudentNameController.text = matched.name;
                              _regSection = matched.section;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Student Name
                      AppTextField(
                        label: 'Student Name (name) *',
                        controller: _regStudentNameController,
                        hint: 'e.g. JIYAN',
                      ),
                      const SizedBox(height: 10),

                      // Program Name with Quick Selection or Type
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Program Name (program) *',
                              controller: _regProgramNameController,
                              hint: 'e.g. QIRATH',
                            ),
                          ),
                          if (programs.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            PopupMenuButton<Program>(
                              icon: const Icon(
                                Icons.arrow_drop_down_circle_outlined,
                                color: AppTheme.red,
                              ),
                              tooltip: 'Pick existing program',
                              onSelected: (p) {
                                setDialogState(() {
                                  _regProgramNameController.text =
                                      p.programName;
                                  _regSection = p.section;
                                });
                              },
                              itemBuilder: (ctx) {
                                return programs.map((p) {
                                  return PopupMenuItem<Program>(
                                    value: p,
                                    child: Text(
                                      '${p.programName} (${p.section.label})',
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Section Dropdown
                      AppDropdown<FestSection>(
                        label: 'Section (setion)',
                        value: _regSection,
                        items: availableSections
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => _regSection = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final chase = _regChaseController.text.trim();
                          final sName = _regStudentNameController.text.trim();
                          final pName = _regProgramNameController.text.trim();
                          final section = _regSection;

                          if (chase.isEmpty || pName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chest number and program name are required.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            // 1. Find or create student
                            var student = students
                                .where((s) =>
                                    s.chaseNumber.trim().toLowerCase() ==
                                    chase.toLowerCase())
                                .firstOrNull;
                            if (student == null) {
                              final defaultTeamId =
                                  teams.isNotEmpty ? teams.first.id : 'team_01';
                              final newStudent = Student(
                                id: 'std_${const Uuid().v4()}',
                                chaseNumber: chase,
                                name: sName.isNotEmpty ? sName : 'Student $chase',
                                gender: 'Male',
                                dateOfBirth: '2010-01-01',
                                section: section,
                                teamId: defaultTeamId,
                                phone: '',
                                className: '',
                                schoolName: '',
                                qrCode: chase,
                              );
                              await ref
                                  .read(studentRepositoryProvider)
                                  .addStudent(newStudent);
                              final fetched = await ref
                                  .read(studentRepositoryProvider)
                                  .getByChaseNumber(chase);
                              student = fetched ?? newStudent;
                            } else if (sName.isNotEmpty &&
                                (student.name.startsWith('Student ') ||
                                    student.name.isEmpty)) {
                              student = student.copyWith(name: sName);
                              await ref
                                  .read(studentRepositoryProvider)
                                  .updateStudent(student);
                            }

                            // 2. Find or create program
                            var program = programs
                                .where((p) =>
                                    p.programName.trim().toLowerCase() ==
                                        pName.toLowerCase() &&
                                    p.section == section)
                                .firstOrNull ??
                                programs
                                    .where((p) =>
                                        p.programName.trim().toLowerCase() ==
                                        pName.toLowerCase())
                                    .firstOrNull;

                            if (program == null) {
                              final progIndex = programs.length + 1;
                              final codePart = pName
                                  .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                                  .toUpperCase();
                              final shortCode = codePart.length >= 4
                                  ? codePart.substring(0, 4)
                                  : codePart.padRight(4, 'X');
                              final progCode = 'P$shortCode-$progIndex';
                              final newProg = Program(
                                id: 'prog_${const Uuid().v4()}',
                                programCode: progCode,
                                programName: pName,
                                section: section,
                                category: ProgramCategory.stage,
                                isStageProgram: true,
                                isGeneral: false,
                                maxParticipants: 1,
                                duration: '10 min',
                                status: 'UPCOMING',
                              );
                              await ref
                                  .read(programRepositoryProvider)
                                  .addProgram(newProg);
                              final fetchedProg = await ref
                                  .read(programRepositoryProvider)
                                  .getByCode(progCode);
                              program = fetchedProg ?? newProg;
                            }

                            // 3. Check duplicate registration
                            final existingReg = await ref
                                .read(registrationRepositoryProvider)
                                .getByStudentAndProgram(student.id, program.id);
                            if (existingReg != null) {
                              setDialogState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Registration already exists for $chase in ${program.programName}.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }

                            // 4. Create registration
                            final newReg = Registration(
                              id: const Uuid().v4(),
                              studentId: student.id,
                              programId: program.id,
                              teamId: student.teamId,
                              registrationNumber:
                                  'REG-${student.chaseNumber}-${program.programCode}',
                              status: RegistrationStatus.approved,
                            );
                            await ref
                                .read(registrationRepositoryProvider)
                                .addRegistration(newReg);

                            triggerDataRefresh(ref);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Registered $chase (${student.name}) for ${program.programName}!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (err) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Registration failed: $err'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Register Program'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditRegistrationDialog(
    Registration reg,
    List<Student> students,
    List<Program> programs,
    List<Team> teams,
  ) {
    final studentMap = {for (var s in students) s.id: s};
    final programMap = {for (var p in programs) p.id: p};

    Student? currentStudent = studentMap[reg.studentId] ??
        students.where((s) =>
            s.id.toLowerCase() == reg.studentId.toLowerCase() ||
            s.chaseNumber.trim().toLowerCase() == reg.studentId.trim().toLowerCase()).firstOrNull;

    Program? currentProg = programMap[reg.programId] ??
        programs.where((p) =>
            p.id.toLowerCase() == reg.programId.toLowerCase() ||
            p.programCode.trim().toLowerCase() == reg.programId.trim().toLowerCase() ||
            p.programName.trim().toLowerCase() == reg.programId.trim().toLowerCase()).firstOrNull;

    String initialChase = currentStudent?.chaseNumber ?? '';
    String initialProgName = currentProg?.programName ?? '';
    if (initialChase.isEmpty && reg.registrationNumber.startsWith('REG-')) {
      final parts = reg.registrationNumber.split('-');
      if (parts.length >= 2) initialChase = parts[1];
      if (parts.length >= 3 && initialProgName.isEmpty) {
        initialProgName = parts.sublist(2).join('-');
      }
    }

    final chaseController = TextEditingController(text: initialChase);
    final studentNameController = TextEditingController(text: currentStudent?.name ?? '');
    final programNameController = TextEditingController(text: initialProgName);
    final regNumController = TextEditingController(text: reg.registrationNumber);

    FestSection selectedSection = currentProg?.section ??
        currentStudent?.section ??
        FestSection.subJunior;

    String selectedTeamId = reg.teamId.isNotEmpty
        ? reg.teamId
        : (currentStudent?.teamId ?? (teams.isNotEmpty ? teams.first.id : ''));

    RegistrationStatus selectedStatus = reg.status;

    final availableSections = FestSection.values.toList();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.edit_note_rounded, color: AppTheme.red),
                  SizedBox(width: 8),
                  Text('Edit Program Registration Details'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reg #: ${reg.registrationNumber.isNotEmpty ? reg.registrationNumber : reg.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Student Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Chest No input with auto-matching existing student & quick picker
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Chest No (chse no) *',
                              controller: chaseController,
                              hint: 'e.g. SB7882',
                              onChanged: (val) {
                                final clean = val.trim().toLowerCase();
                                final matched = students
                                    .where((s) =>
                                        s.chaseNumber.trim().toLowerCase() == clean)
                                    .firstOrNull;
                                if (matched != null) {
                                  setDialogState(() {
                                    studentNameController.text = matched.name;
                                    selectedSection = matched.section;
                                    if (matched.teamId.isNotEmpty) {
                                      selectedTeamId = matched.teamId;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          if (students.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            PopupMenuButton<Student>(
                              icon: const Icon(
                                Icons.person_search_rounded,
                                color: AppTheme.primaryColor,
                              ),
                              tooltip: 'Pick existing student',
                              onSelected: (s) {
                                setDialogState(() {
                                  chaseController.text = s.chaseNumber;
                                  studentNameController.text = s.name;
                                  selectedSection = s.section;
                                  if (s.teamId.isNotEmpty) {
                                    selectedTeamId = s.teamId;
                                  }
                                });
                              },
                              itemBuilder: (ctx) {
                                return students.take(50).map((s) {
                                  return PopupMenuItem<Student>(
                                    value: s,
                                    child: Text(
                                      '${s.chaseNumber} - ${s.name} (${s.section.label})',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Student Name
                      AppTextField(
                        label: 'Student Name (name) *',
                        controller: studentNameController,
                        hint: 'e.g. JIYAN',
                      ),
                      const SizedBox(height: 10),

                      // Team Selection
                      if (teams.isNotEmpty)
                        AppDropdown<String>(
                          label: 'Team',
                          value: teams.any((t) => t.id == selectedTeamId)
                              ? selectedTeamId
                              : teams.first.id,
                          items: teams
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text('${t.teamName} (${t.teamCode})'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedTeamId = val);
                            }
                          },
                        ),
                      const SizedBox(height: 16),

                      const Text(
                        'Program Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Program Name with Quick Selection
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Program Name (program) *',
                              controller: programNameController,
                              hint: 'e.g. QIRATH',
                            ),
                          ),
                          if (programs.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            PopupMenuButton<Program>(
                              icon: const Icon(
                                Icons.arrow_drop_down_circle_outlined,
                                color: AppTheme.red,
                              ),
                              tooltip: 'Pick existing program',
                              onSelected: (p) {
                                setDialogState(() {
                                  programNameController.text = p.programName;
                                  selectedSection = p.section;
                                });
                              },
                              itemBuilder: (ctx) {
                                return programs.map((p) {
                                  return PopupMenuItem<Program>(
                                    value: p,
                                    child: Text(
                                      '${p.programName} (${p.section.label})',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Section Dropdown
                      AppDropdown<FestSection>(
                        label: 'Section (setion)',
                        value: selectedSection,
                        items: availableSections
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedSection = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Registration Status & Code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Dropdown
                      AppDropdown<RegistrationStatus>(
                        label: 'Registration Status',
                        value: selectedStatus,
                        items: RegistrationStatus.values
                            .map(
                              (st) => DropdownMenuItem(
                                value: st,
                                child: Text(st.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStatus = val);
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Registration Number
                      AppTextField(
                        label: 'Registration Number',
                        controller: regNumController,
                        hint: 'e.g. REG-1001-P01',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final chase = chaseController.text.trim();
                          final sName = studentNameController.text.trim();
                          final pName = programNameController.text.trim();
                          final regNum = regNumController.text.trim();
                          final section = selectedSection;
                          final teamId = selectedTeamId.isNotEmpty
                              ? selectedTeamId
                              : (teams.isNotEmpty ? teams.first.id : 'team_01');

                          if (chase.isEmpty || pName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chest number and program name are required.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            // 1. Find or create/update student
                            var student = students
                                .where((s) =>
                                    s.chaseNumber.trim().toLowerCase() ==
                                    chase.toLowerCase())
                                .firstOrNull;

                            if (student == null) {
                              final newStudent = Student(
                                id: 'std_${const Uuid().v4()}',
                                chaseNumber: chase,
                                name: sName.isNotEmpty ? sName : 'Student $chase',
                                gender: 'Male',
                                dateOfBirth: '2010-01-01',
                                section: section,
                                teamId: teamId,
                                phone: '',
                                className: '',
                                schoolName: '',
                                qrCode: chase,
                              );
                              await ref
                                  .read(studentRepositoryProvider)
                                  .addStudent(newStudent);
                              final fetched = await ref
                                  .read(studentRepositoryProvider)
                                  .getByChaseNumber(chase);
                              student = fetched ?? newStudent;
                            } else {
                              bool needsUpdate = false;
                              var updatedStudent = student;
                              if (sName.isNotEmpty && student.name != sName) {
                                updatedStudent = updatedStudent.copyWith(name: sName);
                                needsUpdate = true;
                              }
                              if (teamId.isNotEmpty && student.teamId != teamId) {
                                updatedStudent = updatedStudent.copyWith(teamId: teamId);
                                needsUpdate = true;
                              }
                              if (needsUpdate) {
                                await ref
                                    .read(studentRepositoryProvider)
                                    .updateStudent(updatedStudent);
                                student = updatedStudent;
                              }
                            }

                            // 2. Find or create program
                            var program = programs
                                .where((p) =>
                                    p.programName.trim().toLowerCase() ==
                                        pName.toLowerCase() &&
                                    p.section == section)
                                .firstOrNull ??
                                programs
                                    .where((p) =>
                                        p.programName.trim().toLowerCase() ==
                                        pName.toLowerCase())
                                    .firstOrNull;

                            if (program == null) {
                              final progIndex = programs.length + 1;
                              final codePart = pName
                                  .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                                  .toUpperCase();
                              final shortCode = codePart.length >= 4
                                  ? codePart.substring(0, 4)
                                  : codePart.padRight(4, 'X');
                              final progCode = 'P$shortCode-$progIndex';
                              final newProg = Program(
                                id: 'prog_${const Uuid().v4()}',
                                programCode: progCode,
                                programName: pName,
                                section: section,
                                category: ProgramCategory.stage,
                                isStageProgram: true,
                                isGeneral: false,
                                maxParticipants: 1,
                                duration: '10 min',
                                status: 'UPCOMING',
                              );
                              await ref
                                  .read(programRepositoryProvider)
                                  .addProgram(newProg);
                              final fetchedProg = await ref
                                  .read(programRepositoryProvider)
                                  .getByCode(progCode);
                              program = fetchedProg ?? newProg;
                            }

                            // 3. Check duplicate registration if student or program changed
                            if (student.id != reg.studentId || program.id != reg.programId) {
                              final existingReg = await ref
                                  .read(registrationRepositoryProvider)
                                  .getByStudentAndProgram(student.id, program.id);
                              if (existingReg != null && existingReg.id != reg.id) {
                                setDialogState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Registration already exists for $chase in ${program.programName}.',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                                return;
                              }
                            }

                            // 4. Update registration
                            final finalRegNum = regNum.isNotEmpty
                                ? regNum
                                : (reg.registrationNumber.isNotEmpty
                                    ? reg.registrationNumber
                                    : 'REG-${student.chaseNumber}-${program.programCode}');

                            final updatedReg = reg.copyWith(
                              studentId: student.id,
                              programId: program.id,
                              teamId: teamId,
                              registrationNumber: finalRegNum,
                              status: selectedStatus,
                            );

                            await ref
                                .read(registrationRepositoryProvider)
                                .updateRegistration(updatedReg);

                            triggerDataRefresh(ref);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Updated registration for $chase (${student.name}) - ${program.programName}!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (err) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update registration: $err'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteRegistration(
    Registration reg,
    String studentName,
    String programName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Registration'),
        content: Text(
          'Are you sure you want to remove registration for $studentName in $programName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(registrationRepositoryProvider)
                  .deleteRegistration(reg.id);
              triggerDataRefresh(ref);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registration removed.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllRegistrations(List<Registration> registrations) {
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Delete All Registrations'),
              content: isDeleting
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Deleting registrations... Please wait.'),
                      ],
                    )
                  : Text(
                      'Are you sure you want to delete all ${registrations.length} registrations? This action cannot be undone.',
                    ),
              actions: [
                if (!isDeleting)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                if (!isDeleting)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      setModalState(() => isDeleting = true);
                      int successCount = 0;
                      int failCount = 0;
                      try {
                        final repo = ref.read(registrationRepositoryProvider);
                        final uniqueRegs = {
                          for (var r in registrations) r.id: r,
                        }.values.toList();
                        for (final r in uniqueRegs) {
                          try {
                            await repo.deleteRegistration(r.id);
                            successCount++;
                          } catch (_) {
                            failCount++;
                          }
                        }
                      } finally {
                        triggerDataRefresh(ref);
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (failCount == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All registrations deleted successfully.'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deleted $successCount registrations. $failCount failed.',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Delete All'),
                  ),
              ],
            );
          },
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
    AsyncValue<List<Registration>> registrationsAsync,
  ) {
    final progs = programsAsync.value ?? [];
    final students = studentsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];
    final results = resultsAsync.value ?? [];
    final registrations = registrationsAsync.value ?? [];

    // 1. Filter Programs by selected Section/Category
    final filteredProgs = _selectedResultSection == null
        ? progs
        : progs.where((p) {
            if (_selectedResultSection == FestSection.general) {
              return p.section == FestSection.general ||
                  p.isGeneral ||
                  p.category == ProgramCategory.general;
            }
            return p.section == _selectedResultSection;
          }).toList();

    // Ensure selected program ID is valid within filteredProgs
    String? currentProgId = _selectedResultProgId;
    if (currentProgId != null &&
        !filteredProgs.any((p) => p.id == currentProgId)) {
      currentProgId = filteredProgs.isNotEmpty ? filteredProgs.first.id : null;
    } else if (currentProgId == null && filteredProgs.isNotEmpty) {
      currentProgId = filteredProgs.first.id;
    }

    // 2. Filter Registered Students for selected Program
    final registeredStudentIds = currentProgId != null
        ? registrations
            .where((r) => r.programId == currentProgId)
            .expand((r) {
              final ids = <String>[r.studentId, r.studentId.trim().toLowerCase()];
              if (r.registrationNumber.toUpperCase().startsWith('REG-')) {
                final parts = r.registrationNumber.split('-');
                if (parts.length >= 2) {
                  ids.addAll([parts[1], parts[1].trim().toLowerCase()]);
                }
              }
              return ids;
            })
            .toSet()
        : <String>{};

    final registeredStudents = students
        .where((s) {
          if (registeredStudentIds.contains(s.id)) return true;
          if (registeredStudentIds.contains(s.id.toLowerCase())) return true;
          final cleanChase = s.chaseNumber.trim().toLowerCase();
          if (cleanChase.isNotEmpty && registeredStudentIds.contains(cleanChase)) {
            return true;
          }
          return false;
        })
        .toList();

    final selectedProg = progs.where((p) => p.id == currentProgId).firstOrNull;
    final isGenSectionOrProg = _selectedResultSection == FestSection.general ||
        (selectedProg != null && (selectedProg.isGeneral || selectedProg.section == FestSection.general));
    final sectionStudents = selectedProg != null
        ? (isGenSectionOrProg
            ? students
            : students.where((s) => s.section == selectedProg.section).toList())
        : students;

    final candidateStudents = (_showAllSectionStudents || registeredStudents.isEmpty)
        ? (sectionStudents.isNotEmpty ? sectionStudents : students)
        : registeredStudents;

    // Filter displayed candidate students based on quick search
    final studentQuery =
        _resultStudentSearchController.text.trim().toLowerCase();
    final studentQueryClean = studentQuery.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final displayedStudents = studentQuery.isEmpty
        ? candidateStudents
        : candidateStudents.where((s) {
            final sChase = s.chaseNumber.trim().toLowerCase();
            final sChaseClean = sChase.replaceAll(RegExp(r'[^a-z0-9]'), '');
            final sName = s.name.trim().toLowerCase();
            return sChase == studentQuery ||
                (studentQueryClean.isNotEmpty &&
                    (sChaseClean == studentQueryClean ||
                        sChaseClean.endsWith(studentQueryClean) ||
                        sChaseClean.contains(studentQueryClean))) ||
                sChase.contains(studentQuery) ||
                sName.contains(studentQuery);
          }).toList();

    // Ensure selected student ID is valid within displayedStudents
    String? currentStudentId = _selectedResultStudentId;
    if (currentStudentId != null &&
        !displayedStudents.any((s) => s.id == currentStudentId)) {
      currentStudentId = displayedStudents.isNotEmpty
          ? displayedStudents.first.id
          : null;
    } else if (currentStudentId == null && displayedStudents.isNotEmpty) {
      currentStudentId = displayedStudents.first.id;
    }

    final rawMarksVal = double.tryParse(_resultMarksController.text.trim());
    final scoring = ref.read(scoringServiceProvider);
    final calculatedPointsPreview = scoring.calculateResultPoints(
      position: _resultPosition > 0 ? _resultPosition : null,
      grade: _resultGradeController.text.trim(),
      marks: rawMarksVal,
    );

    final draftResultsCount = results
        .where((r) =>
            r.status == ResultStatus.draft ||
            r.status == ResultStatus.submitted)
        .length;
    final publishedResultsCount = results
        .where((r) =>
            r.status == ResultStatus.published ||
            r.status == ResultStatus.announced)
        .length;

    List<Result> displayedReviewResults = List.from(results);
    if (_resultsReviewFilter == 'DRAFT') {
      displayedReviewResults = displayedReviewResults
          .where((r) =>
              r.status == ResultStatus.draft ||
              r.status == ResultStatus.submitted)
          .toList();
    } else if (_resultsReviewFilter == 'PUBLISHED') {
      displayedReviewResults = displayedReviewResults
          .where((r) =>
              r.status == ResultStatus.published ||
              r.status == ResultStatus.announced)
          .toList();
    }

    // Sort: draft results first, then by updated date
    displayedReviewResults.sort((a, b) {
      final aIsDraft =
          a.status == ResultStatus.draft || a.status == ResultStatus.submitted;
      final bIsDraft =
          b.status == ResultStatus.draft || b.status == ResultStatus.submitted;
      if (aIsDraft && !bIsDraft) return -1;
      if (!aIsDraft && bIsDraft) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Result Upload & Publishing Workflow',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload New Result Draft',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),

                // 1st Dropdown: Section / Category Filter
                AppDropdown<FestSection?>(
                  label: '1. Select Section / Category',
                  value: _selectedResultSection,
                  items: [
                    const DropdownMenuItem<FestSection?>(
                      value: null,
                      child: Text('All Sections / Categories'),
                    ),
                    ...FestSection.values.map(
                      (sec) => DropdownMenuItem<FestSection?>(
                        value: sec,
                        child: Text(sec.label),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedResultSection = val;
                      _selectedResultProgId = null;
                      _selectedResultStudentId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 2nd Dropdown: Program Selection (Filtered by Section)
                AppDropdown<String>(
                  label: '2. Select Program (${filteredProgs.length} available)',
                  value: currentProgId,
                  items: filteredProgs.isEmpty
                      ? [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('No programs available for this section'),
                          ),
                        ]
                      : filteredProgs
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.programName} (${p.section.label})'),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedResultProgId = val;
                      _selectedResultStudentId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 3rd Dropdown: Registered Student Selection (Filtered by Program)
                // 3rd Dropdown: Student Selection (Filtered by Program / Section)
                if (currentProgId != null && registeredStudents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No pre-registered students found for this program. Showing all ${candidateStudents.length} students in ${selectedProg?.section.label ?? "this section"} so you can enter results directly.',
                              style: GoogleFonts.inter(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (currentProgId != null && registeredStudents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text(
                          'Student Source: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Registered (${registeredStudents.length})'),
                          selected: !_showAllSectionStudents,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _showAllSectionStudents = false;
                                _selectedResultStudentId = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('All in Section (${sectionStudents.length})'),
                          selected: _showAllSectionStudents,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _showAllSectionStudents = true;
                                _selectedResultStudentId = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                TextField(
                  controller: _resultStudentSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Chest No (e.g. SB7882) or Name...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _resultStudentSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _resultStudentSearchController.clear();
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      final q = val.trim().toLowerCase();
                      final qClean = q.replaceAll(RegExp(r'[^a-z0-9]'), '');
                      final autoMatch = displayedStudents.where((s) {
                        final sChase = s.chaseNumber.trim().toLowerCase();
                        final sChaseClean =
                            sChase.replaceAll(RegExp(r'[^a-z0-9]'), '');
                        return sChase == q ||
                            (qClean.isNotEmpty && sChaseClean == qClean);
                      }).firstOrNull;
                      if (autoMatch != null) {
                        _selectedResultStudentId = autoMatch.id;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                AppDropdown<String>(
                  label: '3. Select Student (${displayedStudents.length} of ${candidateStudents.length} available)',
                  value: currentStudentId,
                  items: displayedStudents.isEmpty
                      ? [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No students match your search'),
                          ),
                        ]
                      : displayedStudents.map((s) {
                          final team = teams.where((t) => t.id == s.teamId || t.teamCode.toLowerCase() == s.teamId.toLowerCase()).firstOrNull;
                          final teamName = team?.teamName.trim() ?? '';
                          final labelText = teamName.isNotEmpty
                              ? '${s.name} (${s.chaseNumber}) - $teamName'
                              : '${s.name} (${s.chaseNumber})';
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(labelText),
                          );
                        }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedResultStudentId = val),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      AppTextField(
                        label: 'Marks / Points Value',
                        controller: _resultMarksController,
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final m = double.tryParse(v.trim());
                          if (m != null && _resultGradeController.text.trim().isEmpty) {
                            if (m >= 80) {
                              _resultGradeController.text = 'A';
                            } else if (m >= 70) {
                              _resultGradeController.text = 'B';
                            } else if (m >= 60) {
                              _resultGradeController.text = 'C';
                            } else if (m >= 50) {
                              _resultGradeController.text = 'D';
                            }
                          }
                          setState(() {});
                        },
                      ),
                      AppTextField(
                        label: 'Grade (A, B, C)',
                        controller: _resultGradeController,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppDropdown<int>(
                        label: 'Position (1 Position per Student)',
                        value: _resultPosition,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1st Place')),
                          DropdownMenuItem(value: 2, child: Text('2nd Place')),
                          DropdownMenuItem(value: 3, child: Text('3rd Place')),
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Participant (No Position)'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _resultPosition = v);
                        },
                      ),
                    ];

                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: fields
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: f,
                              ),
                            )
                            .toList(),
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
                const SizedBox(height: 8),
                Text(
                  'Calculated Total Points: $calculatedPointsPreview PTS (Position: ${_resultPosition > 0 ? "$_resultPosition" : "None"} + Grade: ${_resultGradeController.text.trim().isEmpty ? "None" : _resultGradeController.text.trim().toUpperCase()})',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.red,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppButton(
                      label: 'Save & Publish Result',
                      onPressed: () => _submitResultForm(
                        asDraft: false,
                        currentProgId: currentProgId,
                        currentStudentId: currentStudentId,
                        students: students,
                        results: results,
                        scoring: scoring,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.drafts_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'Save as Draft',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _submitResultForm(
                        asDraft: true,
                        currentProgId: currentProgId,
                        currentStudentId: currentStudentId,
                        students: students,
                        results: results,
                        scoring: scoring,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Existing Results & Draft Reviews',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.green),
                label: Text(
                  'View Published Results (${results.where((r) => r.status == ResultStatus.published || r.status == ResultStatus.announced).length})',
                ),
                onPressed: () => setState(() => _selectedNavIndex = 7),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade800,
                  side: BorderSide(color: Colors.green.shade400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('All (${results.length})'),
                selected: _resultsReviewFilter == 'ALL',
                onSelected: (val) {
                  if (val) setState(() => _resultsReviewFilter = 'ALL');
                },
              ),
              ChoiceChip(
                avatar: const Icon(
                  Icons.drafts_outlined,
                  size: 16,
                  color: Colors.amber,
                ),
                label: Text('Pending Drafts ($draftResultsCount)'),
                selected: _resultsReviewFilter == 'DRAFT',
                selectedColor: Colors.amber.shade100,
                onSelected: (val) {
                  if (val) setState(() => _resultsReviewFilter = 'DRAFT');
                },
              ),
              ChoiceChip(
                avatar: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green,
                ),
                label: Text('Published ($publishedResultsCount)'),
                selected: _resultsReviewFilter == 'PUBLISHED',
                selectedColor: Colors.green.shade100,
                onSelected: (val) {
                  if (val) setState(() => _resultsReviewFilter = 'PUBLISHED');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayedReviewResults.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              child: Center(
                child: Text(
                  _resultsReviewFilter == 'DRAFT'
                      ? 'No pending draft results found. Submissions from Jury will appear here.'
                      : (_resultsReviewFilter == 'PUBLISHED'
                          ? 'No published results found.'
                          : 'No results recorded yet.'),
                  style: GoogleFonts.inter(
                    color: AppTheme.inkSoft,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedReviewResults.length,
              itemBuilder: (context, idx) {
                final r = displayedReviewResults[idx];
                final isDraft = r.status == ResultStatus.draft ||
                    r.status == ResultStatus.submitted;
                final stud =
                    students.where((s) => s.id == r.studentId).firstOrNull;
                final prog =
                    progs.where((p) => p.id == r.programId).firstOrNull;
                final tm = teams.where((t) => t.id == r.teamId).firstOrNull;

                final studentTitle = stud != null
                    ? '${stud.name} (${stud.chaseNumber})'
                    : r.studentId;
                final programTitle = prog != null
                    ? '${prog.programName} [${prog.programCode}]'
                    : r.programId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color:
                      isDraft ? Colors.amber.withValues(alpha: 0.05) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isDraft ? Colors.amber.shade400 : AppTheme.line,
                      width: isDraft ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    leading: isDraft
                        ? CircleAvatar(
                            backgroundColor: Colors.amber.shade100,
                            child: Icon(
                              Icons.drafts_rounded,
                              color: Colors.amber.shade900,
                              size: 20,
                            ),
                          )
                        : null,
                    title: Text(
                      '$studentTitle • $programTitle',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Team: ${tm?.teamName ?? "N/A"} • ${r.position != null ? "${r.position} Place" : "Participant"} • ${r.points} PTS (Marks: ${r.marks}, Grade: ${r.grade.isEmpty ? "N/A" : r.grade})${isDraft ? "\n[Draft Review - Submitted by Jury / Admin]" : ""}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.inkSoft,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(r.status.label),
                          backgroundColor: r.status == ResultStatus.published
                              ? Colors.green[100]
                              : Colors.amber[100],
                        ),
                        if (r.status != ResultStatus.published) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            tooltip: 'Verify & Publish Result',
                            onPressed: () async {
                              try {
                                final updated = r.copyWith(
                                  status: ResultStatus.published,
                                  publishedAt: DateTime.now(),
                                );
                                await ref
                                    .read(resultRepositoryProvider)
                                    .saveResult(updated);
                                try {
                                  final scoring = ref.read(scoringServiceProvider);
                                  await scoring.recalculateTeamScoresAndRanks();
                                } catch (scoringErr) {
                                  debugPrint('Team score recalculation warning: $scoringErr');
                                }
                                triggerDataRefresh(ref);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Result verified and published! Scores updated.',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Error verifying result: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to publish result: $e'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (r.status != ResultStatus.draft) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.drafts_outlined,
                              color: Colors.orange,
                            ),
                            tooltip: 'Move to Draft',
                            onPressed: () => _confirmMoveToDraft(r),
                          ),
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
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

  void _confirmMoveToDraft(Result result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.drafts_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Text('Move Result to Draft'),
            ],
          ),
          content: Text(
            'Are you sure you want to move this result (ID: ${result.id}) back to Draft? It will be unpublished and its points will be deducted from live team scores.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final updated = result.copyWith(
                    status: ResultStatus.draft,
                    publishedAt: null,
                    clearPublishedAt: true,
                    remarks: 'Moved to draft by Fest Controller',
                  );
                  await ref
                      .read(resultRepositoryProvider)
                      .saveResult(updated);
                  try {
                    final scoring = ref.read(scoringServiceProvider);
                    await scoring.recalculateTeamScoresAndRanks();
                  } catch (scoringErr) {
                    debugPrint('Team score recalculation warning: $scoringErr');
                  }
                  triggerDataRefresh(ref);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Result successfully moved to Draft. Scores recalculated.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error moving result to draft: $e');
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to move result to draft: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Move to Draft'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitResultForm({
    required bool asDraft,
    required String? currentProgId,
    required String? currentStudentId,
    required List<Student> students,
    required List<Result> results,
    required ScoringService scoring,
  }) async {
    if (currentStudentId == null || currentProgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a program and a registered student first.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final student =
        students.where((s) => s.id == currentStudentId).firstOrNull;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected student could not be found in records.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Position Uniqueness Validation per program
    final progResults =
        results.where((r) => r.programId == currentProgId).toList();

    if (_resultPosition > 0 && !asDraft) {
      final existingPosResults = progResults
          .where((r) =>
              r.position == _resultPosition &&
              r.studentId != currentStudentId &&
              r.status == ResultStatus.published)
          .toList();
      if (existingPosResults.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Position $_resultPosition is already assigned twice in this program (maximum 2 participants for ties).',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // Check if this student already has a result for this program
    final existingStudentResult = progResults
        .where((r) => r.studentId == currentStudentId)
        .firstOrNull;

    final rawMarksSubmitted = double.tryParse(_resultMarksController.text.trim());
    final points = scoring.calculateResultPoints(
      position: _resultPosition > 0 ? _resultPosition : null,
      grade: _resultGradeController.text.trim(),
      marks: rawMarksSubmitted,
    );

    final result = Result(
      id: existingStudentResult?.id ?? 'res_${const Uuid().v4()}',
      programId: currentProgId,
      studentId: student.id,
      teamId: student.teamId,
      marks: double.tryParse(_resultMarksController.text) ?? 85.0,
      grade: _resultGradeController.text.trim().toUpperCase(),
      position: _resultPosition > 0 ? _resultPosition : null,
      points: points,
      remarks: asDraft
          ? 'Draft saved by Fest Controller'
          : 'Published by Fest Controller',
      status: asDraft ? ResultStatus.draft : ResultStatus.published,
      publishedAt: asDraft ? null : DateTime.now(),
    );

    try {
      await ref.read(resultRepositoryProvider).saveResult(result);
      try {
        await scoring.recalculateTeamScoresAndRanks();
      } catch (scoringErr) {
        debugPrint('Team score recalculation warning: $scoringErr');
      }
      triggerDataRefresh(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asDraft
                  ? (existingStudentResult != null
                      ? 'Student result updated and saved to Draft!'
                      : 'Result successfully saved to Draft!')
                  : (existingStudentResult != null
                      ? 'Student result updated and republished!'
                      : 'Result successfully verified and published!'),
            ),
            backgroundColor: asDraft ? Colors.amber.shade800 : Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save result: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _confirmDeleteResult(Result result, [Student? student, Program? program, Team? team]) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('Confirm Result Deletion')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this result? Points will be automatically recalculated for all teams.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (student != null)
                      Text('• Student: ${student.name} (${student.chaseNumber})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (program != null)
                      Text('• Program: ${program.programName} (${program.programCode})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (team != null)
                      Text('• Team: ${team.teamName}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      '• Award: ${result.position != null ? "${result.position} Place" : "Participant"} (${result.points} PTS)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Delete Result'),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                await ref
                    .read(resultRepositoryProvider)
                    .deleteResult(result.id);
                final scoring = ref.read(scoringServiceProvider);
                await scoring.recalculateTeamScoresAndRanks();
                triggerDataRefresh(ref);
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Result deleted successfully. Team scores updated.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // --- 7. PUBLISHED RESULTS MANAGEMENT SECTION ---
  Widget _buildPublishedResultsSection(
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    final allResults = resultsAsync.value ?? [];
    final progs = programsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];
    final students = studentsAsync.value ?? [];

    final progMap = {for (var p in progs) p.id: p};
    final teamMap = {for (var t in teams) t.id: t};
    final studentMap = {
      for (var s in students) s.id: s,
      for (var s in students) s.chaseNumber.trim().toLowerCase(): s,
      for (var s in students) s.chaseNumber.trim(): s,
    };

    // Filter only published / announced results
    final publishedResults = allResults
        .where(
          (r) =>
              r.status == ResultStatus.published ||
              r.status == ResultStatus.announced,
        )
        .toList();

    // Calculate metrics
    final totalPublished = publishedResults.length;
    final publishedProgIds = publishedResults.map((r) => r.programId).toSet();
    final totalPoints = publishedResults.fold<int>(0, (sum, r) => sum + r.points);

    // Filter by Section
    List<Result> filteredResults = publishedResults;
    if (_pubResultSectionFilter != 'ALL') {
      filteredResults = filteredResults.where((r) {
        final prog = progMap[r.programId];
        return prog != null &&
            prog.section.name.toUpperCase() == _pubResultSectionFilter;
      }).toList();
    }

    // Filter by Program
    if (_pubResultProgramFilter != null && _pubResultProgramFilter!.isNotEmpty) {
      filteredResults = filteredResults
          .where((r) => r.programId == _pubResultProgramFilter)
          .toList();
    }

    // Filter by Search Query
    if (_pubResultSearchQuery.isNotEmpty) {
      final q = _pubResultSearchQuery.toLowerCase().trim();
      final qClean = q.replaceAll(RegExp(r'[^a-z0-9]'), '');
      filteredResults = filteredResults.where((r) {
        final stud = studentMap[r.studentId] ??
            studentMap[r.studentId.trim().toLowerCase()];
        final prog = progMap[r.programId];
        final tm = teamMap[r.teamId];

        final studName = stud?.name.toLowerCase() ?? '';
        final chase = stud?.chaseNumber.toLowerCase() ?? '';
        final chaseClean = chase.replaceAll(RegExp(r'[^a-z0-9]'), '');
        final progName = prog?.programName.toLowerCase() ?? '';
        final progCode = prog?.programCode.toLowerCase() ?? '';
        final teamName = tm?.teamName.toLowerCase() ?? '';
        final grade = r.grade.toLowerCase();

        return studName.contains(q) ||
            chase.contains(q) ||
            (qClean.isNotEmpty &&
                (chaseClean == qClean ||
                    chaseClean.endsWith(qClean) ||
                    chaseClean.contains(qClean))) ||
            progName.contains(q) ||
            progCode.contains(q) ||
            teamName.contains(q) ||
            grade.contains(q);
      }).toList();
    }

    // Program dropdown items based on section filter
    final availablePrograms = _pubResultSectionFilter == 'ALL'
        ? progs
        : progs
            .where((p) => p.section.name.toUpperCase() == _pubResultSectionFilter)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Published Results Management',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse, search, and delete officially published festival results. Deleting a result automatically recalculates team scores and rankings.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Upload Result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => setState(() => _selectedNavIndex = 6),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overview Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Published Results',
                      value: '$totalPublished',
                      icon: Icons.workspace_premium_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Programs With Results',
                      value: '${publishedProgIds.length} of ${progs.length}',
                      icon: Icons.category_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Total Points Awarded',
                        value: '$totalPoints PTS',
                        icon: Icons.stars_rounded,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Search & Filter Toolbar
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar and view toggle
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pubResultSearchController,
                        onChanged: (val) {
                          setState(() {
                            _pubResultSearchQuery = val.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by student name, chase no, program, team, or grade...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.inkSoft),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.inkSoft),
                          suffixIcon: _pubResultSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _pubResultSearchController.clear();
                                    setState(() {
                                      _pubResultSearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // View Mode Switcher
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'program',
                          icon: Icon(Icons.folder_special_outlined, size: 18),
                          label: Text('By Program'),
                        ),
                        ButtonSegment(
                          value: 'list',
                          icon: Icon(Icons.view_list_rounded, size: 18),
                          label: Text('All List'),
                        ),
                      ],
                      selected: {_pubResultViewMode},
                      onSelectionChanged: (val) {
                        setState(() {
                          _pubResultViewMode = val.first;
                        });
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStateProperty.all(
                          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Section Filter Chips & Program Dropdown
                LayoutBuilder(
                  builder: (context, constraints) {
                    final sectionChips = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChoiceChip(
                          label: 'All Sections',
                          selected: _pubResultSectionFilter == 'ALL',
                          onSelected: () => setState(() {
                            _pubResultSectionFilter = 'ALL';
                            _pubResultProgramFilter = null;
                          }),
                        ),
                        ...FestSection.values.map(
                          (sec) => _buildFilterChoiceChip(
                            label: sec.label,
                            selected: _pubResultSectionFilter == sec.name.toUpperCase(),
                            onSelected: () => setState(() {
                              _pubResultSectionFilter = sec.name.toUpperCase();
                              _pubResultProgramFilter = null;
                            }),
                          ),
                        ),
                      ],
                    );

                    final programDropdown = DropdownButtonFormField<String?>(
                      value: _pubResultProgramFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Filter by Program',
                        labelStyle: GoogleFonts.inter(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.line),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Programs (No Filter)'),
                        ),
                        ...availablePrograms.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(
                              '${p.programName} (${p.programCode})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _pubResultProgramFilter = val),
                    );

                    if (constraints.maxWidth < 750) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionChips,
                          const SizedBox(height: 12),
                          programDropdown,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: sectionChips),
                        const SizedBox(width: 16),
                        SizedBox(width: 280, child: programDropdown),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content rendering
          if (filteredResults.isEmpty)
            _buildEmptyPublishedResultsView(publishedResults.isEmpty)
          else if (_pubResultViewMode == 'program')
            _buildGroupedByProgramView(
              filteredResults,
              progMap,
              teamMap,
              studentMap,
            )
          else
            _buildFlatListView(
              filteredResults,
              progMap,
              teamMap,
              studentMap,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? Colors.white : AppTheme.ink,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.red,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppTheme.red : AppTheme.line),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildEmptyPublishedResultsView(bool hasNoResultsAtAll) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: AppTheme.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasNoResultsAtAll
                ? 'No Published Results Yet'
                : 'No Results Match Your Filter',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasNoResultsAtAll
                ? 'Results uploaded and published from "Result Upload" will appear here.'
                : 'Try adjusting your search query, section filter, or program selection.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (hasNoResultsAtAll)
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Go to Result Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => setState(() => _selectedNavIndex = 6),
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear All Filters'),
              onPressed: () {
                _pubResultSearchController.clear();
                setState(() {
                  _pubResultSearchQuery = '';
                  _pubResultSectionFilter = 'ALL';
                  _pubResultProgramFilter = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedByProgramView(
    List<Result> filteredResults,
    Map<String, Program> progMap,
    Map<String, Team> teamMap,
    Map<String, Student> studentMap,
  ) {
    // Group results by programId
    final Map<String, List<Result>> progGroups = {};
    for (final r in filteredResults) {
      progGroups.putIfAbsent(r.programId, () => []).add(r);
    }

    final progKeys = progGroups.keys.toList();
    // Sort programs by section then program name
    progKeys.sort((a, b) {
      final pa = progMap[a];
      final pb = progMap[b];
      final secComp = (pa?.section.index ?? 0).compareTo(pb?.section.index ?? 0);
      if (secComp != 0) return secComp;
      return (pa?.programName ?? '').compareTo(pb?.programName ?? '');
    });

    return Column(
      children: progKeys.map((pId) {
        final prog = progMap[pId];
        final resList = progGroups[pId]!;
        // Sort results: 1st, 2nd, 3rd, others
        resList.sort((a, b) => (a.position ?? 99).compareTo(b.position ?? 99));

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Program Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.category_rounded, color: AppTheme.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prog?.programName ?? 'Program ID: $pId',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.ink,
                            ),
                          ),
                          if (prog != null)
                            Text(
                              'Code: ${prog.programCode} • Section: ${prog.section.label} • Category: ${prog.category.label}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.inkSoft),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${resList.length} Awards',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Results in this program
                ...resList.map((r) {
                  final stud = studentMap[r.studentId];
                  final tm = teamMap[r.teamId];
                  return _buildResultAwardCard(
                    result: r,
                    student: stud,
                    program: prog,
                    team: tm,
                    showProgramHeader: false,
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlatListView(
    List<Result> filteredResults,
    Map<String, Program> progMap,
    Map<String, Team> teamMap,
    Map<String, Student> studentMap,
  ) {
    return Column(
      children: filteredResults.map((r) {
        final prog = progMap[r.programId];
        final stud = studentMap[r.studentId];
        final tm = teamMap[r.teamId];
        return _buildResultAwardCard(
          result: r,
          student: stud,
          program: prog,
          team: tm,
          showProgramHeader: true,
        );
      }).toList(),
    );
  }

  Widget _buildResultAwardCard({
    required Result result,
    required Student? student,
    required Program? program,
    required Team? team,
    bool showProgramHeader = false,
  }) {
    Color medalColor;
    IconData medalIcon;
    String positionLabel;

    if (result.position == 1) {
      medalColor = const Color(0xFFD4AF37); // Gold
      medalIcon = Icons.emoji_events;
      positionLabel = '1st Place (Winner)';
    } else if (result.position == 2) {
      medalColor = const Color(0xFFA0A0A0); // Silver
      medalIcon = Icons.military_tech;
      positionLabel = '2nd Place';
    } else if (result.position == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.military_tech_outlined;
      positionLabel = '3rd Place';
    } else {
      medalColor = Colors.blueGrey;
      medalIcon = Icons.star_border_rounded;
      positionLabel = 'Participant';
    }

    final dateStr = result.publishedAt != null
        ? DateFormat('MMM dd, yyyy · hh:mm a').format(result.publishedAt!)
        : 'Published';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: result.position == 1
              ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
              : AppTheme.line,
          width: result.position == 1 ? 1.5 : 1.0,
        ),
      ),
      color: result.position == 1
          ? const Color(0xFFFFFDF5)
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Medal / Position badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: medalColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(medalIcon, color: medalColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Student & details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showProgramHeader && program != null) ...[
                    Row(
                      children: [
                        Text(
                          program.programName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.red,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.cream2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            program.section.label,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          student?.name ?? 'Student #${result.studentId}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (student?.chaseNumber != null && student!.chaseNumber.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.cream,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Text(
                            'Chase #${student.chaseNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: medalColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          positionLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: medalColor,
                          ),
                        ),
                      ),
                      if (team != null)
                        Text(
                          'Team: ${team.teamName}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.inkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        '•  Marks: ${result.marks}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.inkSoft),
                      ),
                      if (result.grade.isNotEmpty)
                        Text(
                          '•  Grade: ${result.grade}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.inkSoft),
                        ),
                      Text(
                        '•  $dateStr',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                '+${result.points} PTS',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.green.shade800,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Delete Action Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
              tooltip: 'Delete Published Result',
              onPressed: () => _confirmDeleteResult(result, student, program, team),
            ),
          ],
        ),
      ),
    );
  }

  // --- 8. TV CONTROL & ANNOUNCEMENTS SECTION ---
  Widget _buildTvControlSection(
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Team>> teamsAsync,
  ) {
    final tvService = ref.watch(tvServiceProvider);
    final allPrograms = programsAsync.value ?? [];
    final allResults = resultsAsync.value ?? [];
    final allStudents = studentsAsync.value ?? [];
    final allTeams = teamsAsync.value ?? [];

    final studentMap = {for (var s in allStudents) s.id: s};
    final teamMap = {for (var t in allTeams) t.id: t};

    final currentMode = tvService.settings.screenMode;
    final activeProgId = tvService.settings.announcedProgramId;
    final activeProg = allPrograms.where((p) => p.id == activeProgId).firstOrNull;

    // Distinct published programs count for sequential numbering
    final publishedProgIds = allResults
        .where(
          (r) =>
              r.status == ResultStatus.published ||
              r.status == ResultStatus.announced,
        )
        .map((r) => r.programId)
        .toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TV / Projector Master Controller',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Broadcast live fest visuals, 30s auto-rotating slides, and interactive stage result announcements.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.inkSoft,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.tv_rounded, size: 20),
                label: const Text('Open TV Display Screen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  context.push('/tv');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top Mode Selection Grid (4 Primary Buttons)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live TV Display Mode',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.green,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE ON TV: ${_getModeLabel(currentMode)}',
                            style: GoogleFonts.workSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.55 : 1.25,
                      children: [
                        // Button 1: Auto Rotate With Scoreboard
                        _buildModeButton(
                          title: '1. Auto Rotate With Scoreboard',
                          subtitle: 'Rotates Main, Results & Scoreboard (30s)',
                          icon: Icons.scoreboard_rounded,
                          isActive: currentMode == 'AUTO_WITH_SCOREBOARD' || currentMode == 'AUTO',
                          activeColor: Colors.deepOrange,
                          onTap: () {
                            tvService.setScreenMode(
                              'AUTO_WITH_SCOREBOARD',
                              slideDuration: 30,
                              autoRotate: true,
                            );
                          },
                        ),

                        // Button 2: Auto Rotate Without Scoreboard
                        _buildModeButton(
                          title: '2. Auto Rotate Without Scoreboard',
                          subtitle: 'Rotates Main Screen & Results only (30s)',
                          icon: Icons.view_carousel_rounded,
                          isActive: currentMode == 'AUTO_WITHOUT_SCOREBOARD',
                          activeColor: Colors.indigo,
                          onTap: () {
                            tvService.setScreenMode(
                              'AUTO_WITHOUT_SCOREBOARD',
                              slideDuration: 30,
                              autoRotate: true,
                            );
                          },
                        ),

                        // Button 3: Announce Result
                        _buildModeButton(
                          title: '3. Announce Result',
                          subtitle: 'Draft results & position-by-position stage reveal',
                          icon: Icons.campaign_rounded,
                          isActive: currentMode == 'ANNOUNCE_RESULT',
                          activeColor: Colors.amber[900]!,
                          onTap: () {
                            tvService.setScreenMode('ANNOUNCE_RESULT');
                          },
                        ),

                        // Button 4: Only Main
                        _buildModeButton(
                          title: '4. Only Main',
                          subtitle: 'Shows static Main Fest Poster full screen',
                          icon: Icons.image_rounded,
                          isActive: currentMode == 'ONLY_MAIN' || currentMode == 'POSTER',
                          activeColor: Colors.teal[800]!,
                          onTap: () {
                            tvService.setScreenMode('ONLY_MAIN', autoRotate: false);
                          },
                        ),

                        // Button 5: Scoreboard Only
                        _buildModeButton(
                          title: '5. Scoreboard Only',
                          subtitle: 'Displays team leaderboard & standings',
                          icon: Icons.leaderboard_rounded,
                          isActive: currentMode == 'SCOREBOARD',
                          activeColor: Colors.purple[800]!,
                          onTap: () {
                            tvService.setScreenMode('SCOREBOARD', autoRotate: false);
                          },
                        ),

                        // Button 6: Results Only
                        _buildModeButton(
                          title: '6. Results Only',
                          subtitle: 'Displays published program results list',
                          icon: Icons.emoji_events_rounded,
                          isActive: currentMode == 'RESULTS',
                          activeColor: Colors.blue[800]!,
                          onTap: () {
                            tvService.setScreenMode('RESULTS', autoRotate: false);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Slide Controls (for auto-rotate modes)
                if (currentMode == 'AUTO_WITH_SCOREBOARD' ||
                    currentMode == 'AUTO_WITHOUT_SCOREBOARD' ||
                    currentMode == 'AUTO') ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next Slide'),
                        onPressed: () => tvService.nextSlide(),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: Icon(
                          tvService.settings.autoRotate
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          tvService.settings.autoRotate
                              ? 'Pause Rotation'
                              : 'Resume Rotation',
                        ),
                        onPressed: () => tvService.setAutoRotate(
                          !tvService.settings.autoRotate,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Slide Duration: ${tvService.settings.slideDuration}s per slide',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- SECTION: ANNOUNCE RESULT STAGE CONSOLE ---
          if (currentMode == 'ANNOUNCE_RESULT') ...[
            if (activeProg != null) ...[
              _buildActiveAnnouncementConsole(
                context,
                tvService,
                activeProg,
                allResults,
                studentMap,
                teamMap,
                publishedProgIds,
              ),
              const SizedBox(height: 24),
            ],

            // Draft Results Selector
            _buildDraftResultsSelector(
              context,
              tvService,
              allPrograms,
              allResults,
              publishedProgIds,
            ),
            const SizedBox(height: 24),
          ],

          // Live TV Screen Preview
          _buildTvLivePreviewCard(tvService, activeProg),
        ],
      ),
    );
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'AUTO_WITH_SCOREBOARD':
        return 'Auto Rotate With Scoreboard (30s)';
      case 'AUTO_WITHOUT_SCOREBOARD':
        return 'Auto Rotate Without Scoreboard (30s)';
      case 'ANNOUNCE_RESULT':
        return 'Result Announcement Poster';
      case 'ONLY_MAIN':
      case 'POSTER':
        return 'Main Poster';
      case 'SCOREBOARD':
        return 'Scoreboard Only';
      case 'RESULTS':
        return 'Results Only';
      default:
        return mode;
    }
  }

  Widget _buildModeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : AppTheme.cream2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.line,
            width: isActive ? 2.5 : 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : AppTheme.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : AppTheme.ink,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.inkSoft,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- INTERACTIVE STAGE CONSOLE FOR ACTIVE ANNOUNCEMENT ---
  Widget _buildActiveAnnouncementConsole(
    BuildContext context,
    TvService tvService,
    Program prog,
    List<Result> allResults,
    Map<String, Student> studentMap,
    Map<String, Team> teamMap,
    Set<String> publishedProgIds,
  ) {
    final progResults = allResults.where((r) => r.programId == prog.id).toList();
    final res1 = progResults.where((r) => r.position == 1).firstOrNull;
    final res2 = progResults.where((r) => r.position == 2).firstOrNull;
    final res3 = progResults.where((r) => r.position == 3).firstOrNull;

    final s1 = res1 != null ? studentMap[res1.studentId] : null;
    final t1 = res1 != null ? teamMap[res1.teamId] : null;
    final s2 = res2 != null ? studentMap[res2.studentId] : null;
    final t2 = res2 != null ? teamMap[res2.teamId] : null;
    final s3 = res3 != null ? studentMap[res3.studentId] : null;
    final t3 = res3 != null ? teamMap[res3.teamId] : null;

    final revealed = tvService.settings.revealedPositions;
    final isPos1Revealed = revealed.contains(1);
    final isPos2Revealed = revealed.contains(2);
    final isPos3Revealed = revealed.contains(3);

    final resNum = tvService.settings.announcedResultNumber ?? 1;
    final resNumStr = resNum < 10 ? '0$resNum' : '$resNum';

    final isPublished = publishedProgIds.contains(prog.id);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[900]!, Colors.deepOrange[800]!],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'RESULT #',
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber,
                        ),
                      ),
                      Text(
                        resNumStr,
                        style: GoogleFonts.rye(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prog.section.label.toUpperCase(),
                              style: GoogleFonts.workSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            prog.programCode,
                            style: GoogleFonts.workSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber[200],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prog.programName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                  label: const Text(
                    'Edit Result #',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                  ),
                  onPressed: () => _showEditResultNumberDialog(context, tvService, resNum),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Stage Position Reveal Console (Click to broadcast onto TV screen):',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Announce in traditional stage order: click 3rd Place first, then 2nd Place, then 1st Place to reveal winners across badges on TV.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.inkSoft),
          ),
          const SizedBox(height: 14),

          // 3 Position Cards
          _buildStagePositionCard(
            position: 3,
            badgeLabel: '3rd Place',
            badgeColor: const Color(0xFFDE1F33),
            student: s3,
            team: t3,
            result: res3,
            isRevealed: isPos3Revealed,
            onToggle: () => tvService.togglePositionReveal(3),
          ),
          const SizedBox(height: 10),

          _buildStagePositionCard(
            position: 2,
            badgeLabel: '2nd Place',
            badgeColor: const Color(0xFF8B2B38),
            student: s2,
            team: t2,
            result: res2,
            isRevealed: isPos2Revealed,
            onToggle: () => tvService.togglePositionReveal(2),
          ),
          const SizedBox(height: 10),

          _buildStagePositionCard(
            position: 1,
            badgeLabel: '1st Place (Winner)',
            badgeColor: const Color(0xFF5A8E33),
            student: s1,
            team: t1,
            result: res1,
            isRevealed: isPos1Revealed,
            onToggle: () => tvService.togglePositionReveal(1),
          ),
          const SizedBox(height: 16),

          // Action Buttons Bar
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('👁️ Reveal All Winners'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.olive,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => tvService.revealAllPositions(),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility_off_rounded, size: 18),
                label: const Text('🙈 Hide All (Suspense)'),
                onPressed: () => tvService.hideAllPositions(),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: Icon(
                  isPublished ? Icons.check_circle_rounded : Icons.publish_rounded,
                  size: 18,
                ),
                label: Text(
                  isPublished
                      ? 'Already Published (Re-publish)'
                      : '✅ Publish & Complete Result',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPublished ? Colors.green[800] : AppTheme.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  await _publishActiveProgramResults(context, prog, progResults);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStagePositionCard({
    required int position,
    required String badgeLabel,
    required Color badgeColor,
    required Student? student,
    required Team? team,
    required Result? result,
    required bool isRevealed,
    required VoidCallback onToggle,
  }) {
    final hasStudent = student != null || result != null;
    final studName = student?.name ?? (result != null ? 'Registered Student' : 'No result entered');
    final chaseNo = student?.chaseNumber ?? '';
    final teamName = team?.teamName ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isRevealed ? badgeColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRevealed ? badgeColor : AppTheme.line,
          width: isRevealed ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Position Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Winner Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      studName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: hasStudent ? AppTheme.ink : Colors.grey,
                      ),
                    ),
                    if (chaseNo.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.cream,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Text(
                          '#$chaseNo',
                          style: GoogleFonts.workSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (teamName.isNotEmpty || result != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${teamName.isNotEmpty ? teamName : "Team"} • ${result?.grade.isNotEmpty == true ? "Grade ${result?.grade}" : ""} • ${result?.points ?? 0} PTS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Live Broadcast Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isRevealed ? Colors.green.withValues(alpha: 0.15) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRevealed ? Colors.green : Colors.grey[400]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isRevealed ? Icons.visibility : Icons.visibility_off,
                  size: 14,
                  color: isRevealed ? Colors.green[800] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isRevealed ? 'ON TV' : 'HIDDEN',
                  style: GoogleFonts.workSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isRevealed ? Colors.green[800] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Reveal / Hide Action Button
          ElevatedButton(
            onPressed: onToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isRevealed ? Colors.grey[800] : badgeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              isRevealed ? 'Hide from TV' : 'Reveal on TV',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --- DRAFT RESULTS LIST / PICKER ---
  Widget _buildDraftResultsSelector(
    BuildContext context,
    TvService tvService,
    List<Program> allPrograms,
    List<Result> allResults,
    Set<String> publishedProgIds,
  ) {
    // Find programs with entered results
    final progResultsMap = <String, List<Result>>{};
    for (final r in allResults) {
      progResultsMap.putIfAbsent(r.programId, () => []).add(r);
    }

    final programsWithResults = allPrograms
        .where((p) => progResultsMap.containsKey(p.id) && progResultsMap[p.id]!.isNotEmpty)
        .toList();

    // Filter by Section
    var filtered = programsWithResults;
    if (_tvDraftSectionFilter != 'ALL') {
      filtered = filtered
          .where((p) => p.section.name.toUpperCase() == _tvDraftSectionFilter)
          .toList();
    }

    // Filter by Search Query
    if (_tvDraftSearchQuery.isNotEmpty) {
      final q = _tvDraftSearchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.programName.toLowerCase().contains(q) ||
              p.programCode.toLowerCase().contains(q))
          .toList();
    }

    // Sort: draft/unpublished first, then published
    filtered.sort((a, b) {
      final aPub = publishedProgIds.contains(a.id);
      final bPub = publishedProgIds.contains(b.id);
      if (!aPub && bPub) return -1;
      if (aPub && !bPub) return 1;
      return a.programName.compareTo(b.programName);
    });

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Draft Results Awaiting Announcement',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Text(
                  '${filtered.length} Programs Available',
                  style: GoogleFonts.workSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search and Section Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tvDraftSearchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search program by name or code (e.g. Song MLM)...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    isDense: true,
                    suffixIcon: _tvDraftSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _tvDraftSearchController.clear();
                                _tvDraftSearchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _tvDraftSearchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Section Filter Dropdown
              DropdownButton<String>(
                value: _tvDraftSectionFilter,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Sections')),
                  DropdownMenuItem(value: 'SUBJUNIOR', child: Text('Sub Junior')),
                  DropdownMenuItem(value: 'SENIOR', child: Text('Senior')),
                  DropdownMenuItem(value: 'SUPERSENIOR', child: Text('Super Senior')),
                  DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _tvDraftSectionFilter = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.inbox_rounded, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No draft results match filter criteria.',
                    style: GoogleFonts.inter(color: AppTheme.inkSoft),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final p = filtered[idx];
                final pResults = progResultsMap[p.id] ?? [];
                final isPublished = publishedProgIds.contains(p.id);
                final isCurrent = tvService.settings.announcedProgramId == p.id;

                final winnersCount = pResults.where((r) => r.position != null).length;

                return Container(
                  color: isCurrent
                      ? Colors.amber.withValues(alpha: 0.12)
                      : Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isPublished
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      child: Icon(
                        isPublished ? Icons.check : Icons.hourglass_top,
                        color: isPublished ? Colors.green[800] : Colors.orange[800],
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          p.programName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cream,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Text(
                            p.section.label,
                            style: GoogleFonts.workSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[800],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ON TV SCREEN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${p.programCode} • $winnersCount Winners Assigned • ${isPublished ? "PUBLISHED" : "DRAFT READY"}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.inkSoft,
                      ),
                    ),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.campaign, size: 16),
                      label: Text(
                        isCurrent ? 'Current' : 'Select for TV',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent ? Colors.grey[800] : AppTheme.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // Calculate next sequential published number
                        final nextNum = publishedProgIds.contains(p.id)
                            ? publishedProgIds.toList().indexOf(p.id) + 1
                            : publishedProgIds.length + 1;

                        tvService.startAnnouncement(
                          programId: p.id,
                          resultNumber: nextNum,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Now broadcasting ${p.programName} onto TV Screen as Result #${nextNum < 10 ? "0$nextNum" : nextNum}!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- LIVE TV SCREEN MINIATURE PREVIEW ---
  Widget _buildTvLivePreviewCard(TvService tvService, Program? activeProg) {
    final mode = tvService.settings.screenMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active TV Screen Live Preview',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Chip(
                label: Text(
                  _getModeLabel(mode),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                backgroundColor: AppTheme.cream,
                side: const BorderSide(color: AppTheme.line),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 220,
              width: double.infinity,
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: mode == 'ANNOUNCE_RESULT'
                      ? Image.asset(
                          'assets/images/announce_result_template.jpg',
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          'assets/images/tv_poster.png',
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditResultNumberDialog(
    BuildContext context,
    TvService tvService,
    int currentNum,
  ) {
    final controller = TextEditingController(text: currentNum.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Result Number for TV Poster'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This number replaces the "00" position on the TV announcement template (e.g. 01, 70).',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Result Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text.trim());
                if (val != null && val > 0) {
                  tvService.setAnnouncedResultNumber(val);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save & Update TV'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _publishActiveProgramResults(
    BuildContext context,
    Program prog,
    List<Result> progResults,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Publish Results for ${prog.programName}?'),
        content: Text(
          'This will publish ${progResults.length} winner results and recalculate team championship points.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(resultRepositoryProvider);
    final scoring = ref.read(scoringServiceProvider);

    for (final r in progResults) {
      final updated = r.copyWith(
        status: ResultStatus.published,
        publishedAt: DateTime.now(),
      );
      await repo.updateResult(updated);
    }

    await scoring.recalculateTeamScoresAndRanks();
    triggerDataRefresh(ref);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Results for ${prog.programName} officially published and team championship points recalculated!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- 6. EXCEL IMPORT SECTION ---
  Widget _buildExcelImportSection() {
    final excelService = ref.read(excelServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Excel Multi-Entity Import Center',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
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
                    const Icon(
                      Icons.category_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Import Programs from Excel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: Program Name, Section (Sub Junior / Senior / Super Senior / General), Program Type (Stage / Non-Stage / General)',
                  style: GoogleFonts.inter(
                    color: AppTheme.inkSoft,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildExcelFormatButton(
                      onTap: _showProgramExcelFormatDialog,
                    ),
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
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: 'program_excel_template.xlsx',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Downloaded Program Excel Template.',
                              ),
                            ),
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
                    const Icon(
                      Icons.app_registration_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Import Program Registrations from Excel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: chse no, name, program, setion',
                  style: GoogleFonts.inter(
                    color: AppTheme.inkSoft,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildExcelFormatButton(
                      onTap: _showRegistrationExcelFormatDialog,
                      label: 'Understand Excel Format',
                    ),
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
                        final bytes = excelService
                            .generateRegistrationTemplate();
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: 'registration_excel_template.xlsx',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Downloaded Registrations Excel Template.',
                              ),
                            ),
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
                    const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Import Students from Excel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: Chase Number, Name, Section (Sub Junior / Senior / Super Senior / General), Team Name',
                  style: GoogleFonts.inter(
                    color: AppTheme.inkSoft,
                    fontSize: 13,
                  ),
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
                          const SnackBar(
                            content: Text('Downloaded Student Excel Template.'),
                          ),
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
                    const Icon(
                      Icons.groups_rounded,
                      color: Colors.purple,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Import Teams from Excel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: Team Name, Mentor Name, Leader Name, Assistant Leader Name',
                  style: GoogleFonts.inter(
                    color: AppTheme.inkSoft,
                    fontSize: 13,
                  ),
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
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: 'team_excel_template.xlsx',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Downloaded Team Excel Template.'),
                            ),
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
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.teal,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Import Schedules & Venues from Excel',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected Sheet Columns: DATE, ITEM, TIME, VENUE (VIWE), CATEGORY (CATOGARY)',
                  style: GoogleFonts.inter(
                    color: AppTheme.inkSoft,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildExcelFormatButton(
                      onTap: _showScheduleExcelFormatDialog,
                    ),
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
                  Text(
                    'Import Summary Report',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
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
    final leaderUsers = users
        .where((u) => u.role == UserRole.teamLeader)
        .toList();
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
                    Text(
                      'User Credentials & Access Control',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Create and manage Login IDs & Passwords for Team Leaders and Jury members',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
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
                      onPressed: () =>
                          _showAddEditTeamLeaderDialog(teams: teams),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.assignment_ind),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                      label: const Text('Add Jury Login'),
                      onPressed: () =>
                          _showAddEditJuryDialog(programs: programs),
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

  Widget _buildTeamLeadersList(
    List<User> leaderUsers,
    List<TeamLeader> leaders,
    Map<String, Team> teamMap,
    List<Team> teams,
  ) {
    if (leaderUsers.isEmpty && leaders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No Team Leader user accounts created yet.',
              style: TextStyle(color: Colors.grey[600]),
            ),
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
          orElse: () => TeamLeader(
            id: '',
            name: u.name,
            phone: '',
            email: '',
            username: u.username,
            password: u.password,
            teamId: u.teamId ?? '',
          ),
        );
        final isPasswordVisible = _visiblePasswords.contains(u.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                      Text(
                        u.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            avatar: const Icon(
                              Icons.shield,
                              size: 14,
                              color: Colors.indigo,
                            ),
                            label: Text(
                              team != null ? team.teamName : 'Unassigned Team',
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          if (leaderProfile.phone.isNotEmpty)
                            Text(
                              '📞 ${leaderProfile.phone}  ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          if (leaderProfile.email.isNotEmpty)
                            Text(
                              '✉️ ${leaderProfile.email}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Credentials Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                          const Icon(
                            Icons.account_circle,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Login ID: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SelectableText(
                            u.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.key, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Password: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SelectableText(
                            isPasswordVisible ? u.password : '••••••••',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: isPasswordVisible
                                  ? null
                                  : 'monospace',
                              color: Colors.blue[900],
                            ),
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
                            child: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 16,
                              color: Colors.grey[700],
                            ),
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
                      onPressed: () => _showAddEditTeamLeaderDialog(
                        teams: teams,
                        existingUser: u,
                        existingLeader: leaderProfile,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete User Account',
                      onPressed: () => _confirmDeleteUser(
                        u,
                        leaderProfile.id,
                        isJury: false,
                      ),
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

  Widget _buildJuriesList(
    List<User> juryUsers,
    List<Jury> juries,
    List<Program> programs,
  ) {
    final juryMap = {for (var j in juries) j.id: j};
    final allJuryUsers = List<User>.from(juryUsers);
    for (final j in juries) {
      if (!allJuryUsers.any((u) => u.juryId == j.id || u.username.toLowerCase() == j.username.toLowerCase())) {
        allJuryUsers.add(
          User(
            id: 'usr_${j.id}',
            username: j.username,
            password: j.password,
            name: j.name,
            role: UserRole.jury,
            juryId: j.id,
          ),
        );
      }
    }

    return Column(
      children: [
        // Action Toolbar for Jury Excel & Creation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.secondaryColor.withValues(alpha: 0.25),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.gavel_rounded,
                    color: AppTheme.secondaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jury Logins & QR Code Hub',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.table_chart_outlined, size: 18),
                    label: const Text('Format of Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      side: const BorderSide(color: AppTheme.secondaryColor),
                    ),
                    onPressed: () => _showJuryExcelFormatDialog(programs),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Upload Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _importJuriesFromExcel(programs),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _exportJuriesToExcel(juries, programs),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Jury Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showAddEditJuryDialog(programs: programs),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: allJuryUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gavel, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No Jury user accounts created yet.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Jury Account'),
                        onPressed: () =>
                            _showAddEditJuryDialog(programs: programs),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: allJuryUsers.length,
                  itemBuilder: (context, index) {
                    final u = allJuryUsers[index];
                    final juryProfile = u.juryId != null
                        ? juryMap[u.juryId]
                        : juries.firstWhere(
                            (j) => j.username == u.username,
                            orElse: () => Jury(
                              id: '',
                              name: u.name,
                              username: u.username,
                              password: u.password,
                              juryCode: 'JURY-N/A',
                              assignedPrograms: [],
                            ),
                          );
                    final isPasswordVisible = _visiblePasswords.contains(u.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.secondaryColor
                                  .withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.rate_review,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        avatar: const Icon(
                                          Icons.badge,
                                          size: 14,
                                          color: Colors.purple,
                                        ),
                                        label: Text(
                                          'Code: ${juryProfile?.juryCode ?? "JURY"}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        avatar: const Icon(
                                          Icons.assignment,
                                          size: 14,
                                          color: Colors.teal,
                                        ),
                                        label: Text(
                                          '${juryProfile?.assignedPrograms.length ?? 0} Programs Assigned',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Credentials Box
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
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
                                      const Icon(
                                        Icons.account_circle,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Login ID: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SelectableText(
                                        u.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.key,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Password: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SelectableText(
                                        isPasswordVisible
                                            ? u.password
                                            : '••••••••',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          fontFamily: isPasswordVisible
                                              ? null
                                              : 'monospace',
                                          color: Colors.blue[900],
                                        ),
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
                                        child: Icon(
                                          isPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
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
                                    icon: const Icon(
                                      Icons.qr_code,
                                      color: Colors.purple,
                                    ),
                                    tooltip: 'View Login QR Codes',
                                    onPressed: () => _showJuryQRDialog(
                                      context,
                                      juryProfile,
                                      programs,
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Edit Login & Password',
                                  onPressed: () => _showAddEditJuryDialog(
                                    programs: programs,
                                    existingUser: u,
                                    existingJury: juryProfile,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete User Account',
                                  onPressed: () => _confirmDeleteUser(
                                    u,
                                    juryProfile?.id ?? '',
                                    isJury: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddEditTeamLeaderDialog({
    required List<Team> teams,
    User? existingUser,
    TeamLeader? existingLeader,
  }) {
    final isEditing = existingUser != null;
    _userLoginNameController.text =
        existingUser?.name ?? existingLeader?.name ?? '';
    _userUsernameController.text =
        existingUser?.username ?? existingLeader?.username ?? '';
    _userPasswordController.text =
        existingUser?.password ?? existingLeader?.password ?? '';
    _userPhoneController.text = existingLeader?.phone ?? '';
    _userEmailController.text = existingLeader?.email ?? '';
    _selectedLeaderTeamId =
        existingUser?.teamId ??
        existingLeader?.teamId ??
        (teams.isNotEmpty ? teams.first.id : null);

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit Team Leader Login Credentials'
                    : 'Create Team Leader Login ID & Password',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppDropdown<String>(
                        label: 'Select Team',
                        value: _selectedLeaderTeamId,
                        items: teams
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text('${t.teamName} (${t.teamCode})'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (isSaving) return;
                          setDialogState(() {
                            _selectedLeaderTeamId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Leader Name',
                        controller: _userLoginNameController,
                        hint: 'e.g. John Doe',
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
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = _userLoginNameController.text.trim();
                          final username = _userUsernameController.text.trim();
                          final password = _userPasswordController.text.trim();
                          final phone = _userPhoneController.text.trim();
                          final email = _userEmailController.text.trim();
                          final teamId = _selectedLeaderTeamId ?? '';

                          if (name.isEmpty ||
                              username.isEmpty ||
                              password.isEmpty ||
                              teamId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Leader Name, Team, Login ID, and Password are required!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            if (!isEditing || existingUser.username != username) {
                              final userRepo =
                                  ref.read(userRepositoryProvider);
                              final existing =
                                  await userRepo.getByUsername(username);
                              if (existing != null) {
                                setDialogState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Login ID "$username" is already taken. Please use a unique Login ID.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                            }

                            final leaderId = existingLeader?.id.isNotEmpty == true
                                ? existingLeader!.id
                                : 'leader_${const Uuid().v4()}';
                            final userId = existingUser?.id.isNotEmpty == true
                                ? existingUser!.id
                                : 'usr_$leaderId';

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
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Team Leader login credentials saved for "$name"! Login ID: $username',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to save Team Leader Account: ${e.toString().replaceAll("Exception: ", "")}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Create Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEditJuryDialog({
    required List<Program> programs,
    User? existingUser,
    Jury? existingJury,
  }) {
    final isEditing = existingUser != null;
    _userLoginNameController.text =
        existingUser?.name ?? existingJury?.name ?? '';
    _userJuryCodeController.text = existingJury?.juryCode ?? 'JURY-101';
    _userUsernameController.text =
        existingUser?.username ?? existingJury?.username ?? '';
    _userPasswordController.text =
        existingUser?.password ?? existingJury?.password ?? '';
    _selectedJuryProgramIds = List<String>.from(
      existingJury?.assignedPrograms ?? [],
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit Jury Member Login Credentials'
                    : 'Create Jury Login ID & Password',
              ),
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
                      Text(
                        'Assigned Programs (${_selectedJuryProgramIds.length} selected):',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
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
                            final isChecked = _selectedJuryProgramIds.contains(
                              p.id,
                            );
                            return CheckboxListTile(
                              dense: true,
                              title: Text(
                                '${p.programName} (${p.programCode})',
                              ),
                              subtitle: Text(
                                '${p.section.label} • ${p.isStageProgram ? "Stage" : "Non-Stage"}',
                              ),
                              value: isChecked,
                              onChanged: isSaving
                                  ? null
                                  : (val) {
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
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = _userLoginNameController.text.trim();
                          final juryCode = _userJuryCodeController.text
                              .trim()
                              .toUpperCase();
                          final username = _userUsernameController.text.trim();
                          final password = _userPasswordController.text.trim();

                          if (name.isEmpty ||
                              juryCode.isEmpty ||
                              username.isEmpty ||
                              password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Jury Name, Jury Code, Login ID, and Password are required!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            if (!isEditing || existingUser.username != username) {
                              final userRepo =
                                  ref.read(userRepositoryProvider);
                              final existing =
                                  await userRepo.getByUsername(username);
                              if (existing != null) {
                                setDialogState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Login ID "$username" is already taken. Please use a unique Login ID.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                            }

                            final juryId = existingJury?.id.isNotEmpty == true
                                ? existingJury!.id
                                : 'jury_${const Uuid().v4()}';
                            final userId = existingUser?.id.isNotEmpty == true
                                ? existingUser!.id
                                : 'usr_$juryId';

                            final jury = Jury(
                              id: juryId,
                              name: name,
                              username: username,
                              password: password,
                              juryCode: juryCode,
                              assignedPrograms: List<String>.from(
                                _selectedJuryProgramIds,
                              ),
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
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Jury credentials saved for "$name" ($juryCode)! Login ID: $username',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _showJuryQRDialog(context, jury, programs);
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to save Jury Account: ${e.toString().replaceAll("Exception: ", "")}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Create Jury Account',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJuryExcelFormatDialog(List<Program> programs) {
    final excelService = ref.read(excelServiceProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.table_chart, color: Colors.purple),
              SizedBox(width: 10),
              Text('Excel Format for Jury Logins'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload an Excel file (.xlsx or .xls) with the following column structure:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '• Column A (1): Jury Name (e.g., Prof. Sarah Jenkins)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Column B (2): Jury Code (e.g., JURY-101)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Column C (3): Username / Login ID (e.g., jury_singing)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Column D (4): Password (e.g., pass1234)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Column E (5): Assigned Program Name or Code (comma-separated if multiple)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note: When uploaded, Jury accounts will be created and QR login codes will be automatically generated for instant QR scanning.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Download Sample Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final bytes = excelService.generateJuryTemplate();
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'jury_logins_template.xlsx',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloaded Jury Logins Excel Template.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _importJuriesFromExcel(List<Program> programs) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (files.isEmpty) return;

    final bytes = await files.first.readAsBytes();
    if (bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read selected Excel file bytes.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final excelService = ref.read(excelServiceProvider);
      final importRes = await excelService.importJuriesFromExcel(bytes);

      triggerDataRefresh(ref);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Jury Excel Import Summary'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Rows Processed: ${importRes.totalRows}'),
                    Text(
                      'Valid Logins Imported: ${importRes.validRows}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Invalid Rows: ${importRes.invalidRows}',
                      style: TextStyle(
                        color: importRes.invalidRows > 0
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      'Duplicates Skipped: ${importRes.duplicateRows}',
                      style: TextStyle(
                        color: importRes.duplicateRows > 0
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'QR Login codes have been auto-generated for all imported Jury accounts!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                    if (importRes.errors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Errors / Warnings:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: importRes.errors.length,
                          itemBuilder: (c, i) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              importRes.errors[i],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import Jury Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportJuriesToExcel(
    List<Jury> juries,
    List<Program> programs,
  ) async {
    if (juries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Jury user accounts to export.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final excelService = ref.read(excelServiceProvider);
      final bytes = excelService.exportJuriesToExcel(juries, programs);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'jury_credentials_and_qrs.xlsx',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exported Jury credentials & QR data to Excel!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Jury Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showJuryQRDialog(
    BuildContext context,
    Jury jury,
    List<Program> programs,
  ) {
    final assignedProgs = programs
        .where((p) => jury.assignedPrograms.contains(p.id))
        .toList();
    final generalPayload = QrService.generateJuryLoginProgramQrPayload(
      jury.username,
      jury.password,
      '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Jury Login QR Codes - ${jury.name} (${jury.juryCode})'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // General Login QR Card
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.purple[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.purple[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.qr_code_2, color: Colors.purple),
                              SizedBox(width: 8),
                              Text(
                                'General Jury Login QR Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          QrImageView(
                            data: generalPayload,
                            version: QrVersions.auto,
                            size: 160.0,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Username: ${jury.username}  |  Password: ${jury.password}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Scan this on the login page to log in as Jury.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Program-Specific QR Cards
                  if (assignedProgs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Program Direct-Access QR Codes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    ...assignedProgs.map((p) {
                      final pPayload = QrService.generateJuryLoginProgramQrPayload(
                        jury.username,
                        jury.password,
                        p.id,
                      );
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            children: [
                              Text(
                                '${p.programName} (${p.programCode})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              QrImageView(
                                data: pPayload,
                                version: QrVersions.auto,
                                size: 140.0,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Scan to log in & open ${p.programName} directly.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Export Excel for this Jury'),
              onPressed: () {
                _exportJuriesToExcel([jury], programs);
              },
            ),
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
          content: Text(
            'Are you sure you want to delete user account "${user.name}" (Login ID: ${user.username})? This user will no longer be able to log in.',
          ),
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
                    await ref
                        .read(leaderRepositoryProvider)
                        .deleteLeader(modelId);
                  }
                }
                triggerDataRefresh(ref);
                if (mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'User account "${user.username}" deleted successfully.',
                      ),
                    ),
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
          Text(
            'System Administration',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Database Management',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reset or purge all database entries to start a fresh competition session.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text(
                        'Reset All Database Data',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        final demo = ref.read(demoDataServiceProvider);
                        await demo.clearAllData();
                        final auth = ref.read(authServiceProvider);
                        await auth.seedDefaultUsers();
                        triggerDataRefresh(ref);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Database reset completely.'),
                          ),
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

    final Map<String, Program> progMap = {for (var p in programs) p.id: p};
    final Map<String, Venue> venMap = {for (var v in venues) v.id: v};

    // Official festival venues
    final officialVenues = ['S1', 'S2', 'S8', 'S3', 'LIBRARY', 'Auditorium'];
    final displayVenues = <String>[];
    for (final ov in officialVenues) {
      if (!displayVenues.contains(ov)) displayVenues.add(ov);
    }
    for (final v in venues) {
      final vName = v.name.trim();
      if (vName.isNotEmpty &&
          !displayVenues.any((dv) => dv.toLowerCase() == vName.toLowerCase())) {
        displayVenues.add(vName);
      }
    }

    // Schedule counts per venue
    final Map<String, int> venueScheduleCount = {};
    for (final s in schedules) {
      final ven = venMap[s.venueId];
      final vName = (ven?.name ?? s.venueId).trim();
      venueScheduleCount[vName.toUpperCase()] =
          (venueScheduleCount[vName.toUpperCase()] ?? 0) + 1;
      venueScheduleCount[s.venueId] =
          (venueScheduleCount[s.venueId] ?? 0) + 1;
    }

    // Filter schedules
    final filteredSchedules = schedules.where((s) {
      if (_selectedScheduleDateFilter != 'ALL' &&
          s.date.trim() != _selectedScheduleDateFilter) {
        return false;
      }
      if (_selectedScheduleStatusFilter != 'ALL' &&
          s.status != _selectedScheduleStatusFilter) {
        return false;
      }
      if (_selectedScheduleVenueFilter != 'ALL') {
        final ven = venMap[s.venueId];
        final venName = (ven?.name ?? s.venueId).trim().toLowerCase();
        final selectedTarget =
            _selectedScheduleVenueFilter.trim().toLowerCase();
        if (s.venueId.toLowerCase() != selectedTarget &&
            venName != selectedTarget) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort chronologically by date and start time
    filteredSchedules.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      return _parseTimeToMinutes(a.startTime).compareTo(
        _parseTimeToMinutes(b.startTime),
      );
    });

    // Unique dates from schedules
    final uniqueDates =
        schedules
            .map((s) => s.date.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final paddingH = isMobile ? 14.0 : 24.0;
        final paddingV = isMobile ? 16.0 : 24.0;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(paddingH, paddingV, paddingH, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
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
                              style: GoogleFonts.rye(
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage festival dates, stages, venues, and program schedules.',
                              style: GoogleFonts.workSans(
                                color: AppTheme.inkSoft,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('+ Add Schedule'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.red,
                                foregroundColor: AppTheme.cream,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                _showAddEditScheduleDialog(
                                  context,
                                  programs: programs,
                                  venues: venues,
                                  schedules: schedules,
                                );
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                              label: const Text('+ Add Venue'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => _showAddVenueDialog(context),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file_rounded, size: 18),
                              label: const Text('Upload Schedule'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _importSchedulesFromExcel,
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.help_outline_rounded, size: 18),
                              label: const Text('Format / Template'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                side: const BorderSide(color: AppTheme.line),
                              ),
                              onPressed: _showScheduleExcelFormatDialog,
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.file_download_outlined, size: 18),
                              label: const Text('Export Excel'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                side: const BorderSide(color: AppTheme.line),
                              ),
                              onPressed:
                                  () => _exportSchedulesToExcel(
                                    schedules,
                                    progMap,
                                    venMap,
                                  ),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.delete_sweep_rounded,
                                size: 18,
                                color: AppTheme.red,
                              ),
                              label: const Text(
                                'Clear Schedules',
                                style: TextStyle(color: AppTheme.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                side: const BorderSide(color: AppTheme.red),
                              ),
                              onPressed: _confirmClearSchedules,
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.cleaning_services_rounded,
                                size: 18,
                                color: Colors.teal,
                              ),
                              label: const Text(
                                'Clean & Reset Venues',
                                style: TextStyle(color: Colors.teal),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                side: const BorderSide(color: Colors.teal),
                              ),
                              onPressed: () => _confirmResetOfficialVenues(venues, schedules),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Responsive Stat Cards
                    if (!isMobile)
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: StatCard(
                              title: 'Total Venues',
                              value: '${venues.length}',
                              icon: Icons.place_rounded,
                              color: AppTheme.mustard,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: StatCard(
                              title: 'In Progress / Live',
                              value:
                                  '${schedules.where((s) => s.status == 'IN_PROGRESS').length}',
                              icon: Icons.play_circle_outline_rounded,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: StatCard(
                              title: 'Completed',
                              value:
                                  '${schedules.where((s) => s.status == 'COMPLETED').length}',
                              icon: Icons.check_circle_outline_rounded,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  title: 'Total Venues',
                                  value: '${venues.length}',
                                  icon: Icons.place_rounded,
                                  color: AppTheme.mustard,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  title: 'In Progress / Live',
                                  value:
                                      '${schedules.where((s) => s.status == 'IN_PROGRESS').length}',
                                  icon: Icons.play_circle_outline_rounded,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  title: 'Completed',
                                  value:
                                      '${schedules.where((s) => s.status == 'COMPLETED').length}',
                                  icon: Icons.check_circle_outline_rounded,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Search and Filters Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Status:',
                                style: GoogleFonts.workSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.inkSoft,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status Filter Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.line),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedScheduleStatusFilter,
                                    isDense: true,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'ALL',
                                        child: Text('All Status'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'SCHEDULED',
                                        child: Text('SCHEDULED'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'IN_PROGRESS',
                                        child: Text('IN_PROGRESS'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'COMPLETED',
                                        child: Text('COMPLETED'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'CANCELLED',
                                        child: Text('CANCELLED'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedScheduleStatusFilter = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_selectedScheduleStatusFilter != 'ALL' ||
                                  _selectedScheduleDateFilter != 'ALL' ||
                                  _selectedScheduleVenueFilter != 'ALL')
                                TextButton.icon(
                                  icon: const Icon(Icons.clear_all, size: 16),
                                  label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    setState(() {
                                      _selectedScheduleStatusFilter = 'ALL';
                                      _selectedScheduleDateFilter = 'ALL';
                                      _selectedScheduleVenueFilter = 'ALL';
                                    });
                                  },
                                ),
                            ],
                          ),
                          if (uniqueDates.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  Text(
                                    'Dates:',
                                    style: GoogleFonts.workSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.inkSoft,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('All Dates'),
                                    selected: _selectedScheduleDateFilter == 'ALL',
                                    visualDensity: VisualDensity.compact,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedScheduleDateFilter = 'ALL';
                                      });
                                    },
                                  ),
                                  ...uniqueDates.map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: ChoiceChip(
                                        label: Text(formatAppDate(d)),
                                        selected: _selectedScheduleDateFilter == d,
                                        visualDensity: VisualDensity.compact,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedScheduleDateFilter = d;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                Text(
                                  'Venues:',
                                  style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.inkSoft,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text('All Venues (${schedules.length})'),
                                  selected: _selectedScheduleVenueFilter == 'ALL',
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedScheduleVenueFilter = 'ALL';
                                    });
                                  },
                                ),
                                ...displayVenues.map((vName) {
                                  final count =
                                      venueScheduleCount[vName.toUpperCase()] ??
                                      venueScheduleCount[vName] ??
                                      0;
                                  final isSelected =
                                      _selectedScheduleVenueFilter.toLowerCase() ==
                                      vName.toLowerCase();
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: ChoiceChip(
                                      label: Text('$vName ($count)'),
                                      selected: isSelected,
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedScheduleVenueFilter =
                                              isSelected ? 'ALL' : vName;
                                        });
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Scheduled Programs Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SCHEDULED PROGRAMS (${filteredSchedules.length})',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppTheme.inkSoft,
                          ),
                        ),
                        Text(
                          'Showing ${filteredSchedules.length} of ${schedules.length} total',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            color: AppTheme.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (filteredSchedules.isEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(paddingH, 8, paddingH, 40),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: AppTheme.inkSoft,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          schedules.isEmpty
                              ? 'No Schedules Uploaded Yet'
                              : 'No schedules matching your filter',
                          style: GoogleFonts.workSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          schedules.isEmpty
                              ? 'Click "Upload Schedule" to import an Excel or PDF schedule file, or add schedules manually.'
                              : 'Try clearing your filters or search options to see all schedules.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(
                            fontSize: 13,
                            color: AppTheme.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (schedules.isEmpty)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.upload_file_rounded, size: 18),
                                label: const Text('Upload Schedule (Excel / PDF)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _importSchedulesFromExcel,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.help_outline_rounded, size: 18),
                                label: const Text('Format & Instructions'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _showScheduleExcelFormatDialog,
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('+ Add Manually'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.red,
                                  foregroundColor: AppTheme.cream,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  _showAddEditScheduleDialog(
                                    context,
                                    programs: programs,
                                    venues: venues,
                                    schedules: schedules,
                                  );
                                },
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear All Filters'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedScheduleStatusFilter = 'ALL';
                                _selectedScheduleDateFilter = 'ALL';
                                _selectedScheduleVenueFilter = 'ALL';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(paddingH, 8, paddingH, 60),
                sliver: SliverList.separated(
                  itemCount: filteredSchedules.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final sch = filteredSchedules[idx];
                    final prog = progMap[sch.programId];
                    final ven = venMap[sch.venueId];
                    final venName =
                        ven?.name ??
                        (sch.venueId.isNotEmpty ? sch.venueId : 'TBA');
                    final progName =
                        prog?.programName ?? 'Program #${sch.programId}';
                    final progCode = prog?.programCode ?? '';
                    final section = prog?.section.label ?? 'General';

                    Color statusColor = Colors.blue;
                    if (sch.status == 'IN_PROGRESS') statusColor = Colors.orange;
                    if (sch.status == 'COMPLETED') statusColor = Colors.green;
                    if (sch.status == 'CANCELLED') statusColor = Colors.red;

                    Widget buildStatusBadge() {
                      return PopupMenuButton<String>(
                        tooltip: 'Change Status',
                        initialValue: sch.status,
                        onSelected: (newStatus) async {
                          final updated = sch.copyWith(status: newStatus);
                          await ref
                              .read(scheduleRepositoryProvider)
                              .updateSchedule(updated);
                          triggerDataRefresh(ref);
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(
                                value: 'SCHEDULED',
                                child: Text('SCHEDULED'),
                              ),
                              PopupMenuItem(
                                value: 'IN_PROGRESS',
                                child: Text('IN_PROGRESS (Live)'),
                              ),
                              PopupMenuItem(
                                value: 'COMPLETED',
                                child: Text('COMPLETED'),
                              ),
                              PopupMenuItem(
                                value: 'CANCELLED',
                                child: Text('CANCELLED'),
                              ),
                            ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sch.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 14,
                                color: statusColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (isMobile) {
                      // Responsive mobile card layout
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.line),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cream2,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.line),
                                  ),
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
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
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (progCode.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.cream,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppTheme.line),
                                              ),
                                              child: Text(
                                                progCode,
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              section,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Colors.blueGrey,
                                      ),
                                      tooltip: 'Edit Schedule',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        _showAddEditScheduleDialog(
                                          context,
                                          scheduleToEdit: sch,
                                          programs: programs,
                                          venues: venues,
                                          schedules: schedules,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppTheme.red,
                                      ),
                                      tooltip: 'Delete Schedule',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _confirmDeleteSchedule(sch, prog),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 18, color: AppTheme.line),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_month,
                                            size: 13,
                                            color: AppTheme.red,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              formatAppDate(
                                                sch.date,
                                                fullMonth: true,
                                                includeWeekday: true,
                                              ),
                                              style: GoogleFonts.workSans(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: AppTheme.ink,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 13,
                                            color: Colors.blueGrey,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${formatAppTime(sch.startTime)} - ${formatAppTime(sch.endTime)}',
                                            style: GoogleFonts.workSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.inkSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place,
                                            size: 14,
                                            color: AppTheme.red,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              venName,
                                              style: GoogleFonts.workSans(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: AppTheme.ink,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                buildStatusBadge(),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    // Desktop / Tablet row layout
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Order Number
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.cream2,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Program Details
                          Expanded(
                            flex: 3,
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
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (progCode.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cream,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.line),
                                        ),
                                        child: Text(
                                          progCode,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        section,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Date & Time
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      size: 14,
                                      color: AppTheme.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        formatAppDate(
                                          sch.date,
                                          fullMonth: true,
                                          includeWeekday: true,
                                        ),
                                        style: GoogleFonts.workSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: AppTheme.ink,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${formatAppTime(sch.startTime)} - ${formatAppTime(sch.endTime)}',
                                      style: GoogleFonts.workSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Venue
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.place,
                                  size: 16,
                                  color: AppTheme.red,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    venName,
                                    style: GoogleFonts.workSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.ink,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status Dropdown / Badge
                          buildStatusBadge(),
                          const SizedBox(width: 12),
                          // Actions
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            tooltip: 'Edit Schedule',
                            onPressed: () {
                              _showAddEditScheduleDialog(
                                context,
                                scheduleToEdit: sch,
                                programs: programs,
                                venues: venues,
                                schedules: schedules,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppTheme.red,
                            ),
                            tooltip: 'Delete Schedule',
                            onPressed: () => _confirmDeleteSchedule(sch, prog),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAddVenueDialog(BuildContext context) {
    _venueNameController.clear();
    _venueLocationController.clear();
    _venueCapacityController.text = '100';
    _venueDescController.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.place_rounded, color: AppTheme.red),
              SizedBox(width: 10),
              Text('Add New Venue'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _venueNameController,
                    decoration: const InputDecoration(
                      labelText: 'Venue / Stage Name *',
                      hintText: 'e.g. Stage 1 (Main Auditorium)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _venueLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Floor',
                      hintText: 'e.g. Block A, 1st Floor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _venueCapacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Seating Capacity',
                      hintText: '100',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _venueDescController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = _venueNameController.text.trim();
                if (name.isEmpty) return;
                final venue = Venue(
                  id: 'ven_${const Uuid().v4()}',
                  name: name,
                  location:
                      _venueLocationController.text.trim().isEmpty
                          ? 'Main Site'
                          : _venueLocationController.text.trim(),
                  capacity:
                      int.tryParse(_venueCapacityController.text.trim()) ?? 100,
                  description: _venueDescController.text.trim(),
                );
                await ref.read(venueRepositoryProvider).addVenue(venue);
                triggerDataRefresh(ref);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Venue added successfully.')),
                  );
                }
              },
              child: const Text('Save Venue'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSchedule(Schedule schedule, Program? prog) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Schedule?'),
          content: Text(
            'Are you sure you want to remove the schedule for "${prog?.programName ?? 'this program'}" on ${schedule.date} at ${schedule.startTime}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await ref
                    .read(scheduleRepositoryProvider)
                    .deleteSchedule(schedule.id);
                triggerDataRefresh(ref);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schedule removed.')),
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

  void _showAddEditScheduleDialog(
    BuildContext context, {
    Schedule? scheduleToEdit,
    required List<Program> programs,
    required List<Venue> venues,
    required List<Schedule> schedules,
  }) {
    String? selectedProgId =
        scheduleToEdit?.programId ??
        (programs.isNotEmpty ? programs.first.id : null);
    String? selectedVenueId =
        scheduleToEdit?.venueId ?? (venues.isNotEmpty ? venues.first.id : null);
    final dateController = TextEditingController(
      text: scheduleToEdit?.date ?? '2026-09-05',
    );
    final startTimeController = TextEditingController(
      text: scheduleToEdit?.startTime ?? '09:00',
    );
    final endTimeController = TextEditingController(
      text: scheduleToEdit?.endTime ?? '10:30',
    );
    String status = scheduleToEdit?.status ?? 'SCHEDULED';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit_calendar_rounded, color: AppTheme.red),
                  const SizedBox(width: 10),
                  Text(
                    scheduleToEdit == null
                        ? 'Add Program Schedule'
                        : 'Edit Program Schedule',
                  ),
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
                        decoration: const InputDecoration(
                          labelText: 'Select Program',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            programs.map((p) {
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '[${p.programCode}] ${p.programName} (${p.section.label})',
                                ),
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
                        decoration: const InputDecoration(
                          labelText: 'Select Venue',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            venues.map((v) {
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
                              decoration: InputDecoration(
                                labelText: 'Date (YYYY-MM-DD)',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_month),
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final initial =
                                        DateTime.tryParse(dateController.text) ??
                                        now;
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: initial,
                                      firstDate: DateTime(now.year - 1),
                                      lastDate: DateTime(now.year + 5),
                                    );
                                    if (picked != null) {
                                      final yyyy = picked.year;
                                      final mm = picked.month.toString().padLeft(2, '0');
                                      final dd = picked.day.toString().padLeft(2, '0');
                                      dateController.text = '$yyyy-$mm-$dd';
                                      setDialogState(() {});
                                    }
                                  },
                                ),
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
                        decoration: const InputDecoration(
                          labelText: 'Schedule Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'SCHEDULED',
                            child: Text('SCHEDULED'),
                          ),
                          DropdownMenuItem(
                            value: 'IN_PROGRESS',
                            child: Text('IN_PROGRESS'),
                          ),
                          DropdownMenuItem(
                            value: 'COMPLETED',
                            child: Text('COMPLETED'),
                          ),
                          DropdownMenuItem(
                            value: 'CANCELLED',
                            child: Text('CANCELLED'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              status = val;
                            });
                          }
                        },
                      ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (selectedProgId == null || selectedVenueId == null) {
                      return;
                    }
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
                      await ref
                          .read(scheduleRepositoryProvider)
                          .addSchedule(sch);
                    } else {
                      await ref
                          .read(scheduleRepositoryProvider)
                          .updateSchedule(sch);
                    }

                    triggerDataRefresh(ref);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            scheduleToEdit == null
                                ? 'Schedule added successfully.'
                                : 'Schedule updated successfully.',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    scheduleToEdit == null
                        ? 'Save Schedule'
                        : 'Update Schedule',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTotalSection(
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Program>> programsAsync,
  ) {
    if (studentsAsync.isLoading ||
        teamsAsync.isLoading ||
        resultsAsync.isLoading ||
        programsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final students = studentsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];
    final results = resultsAsync.value ?? [];
    final programs = programsAsync.value ?? [];

    final Map<String, String> teamNamesMap = {};
    for (final t in teams) {
      teamNamesMap[t.id] = t.teamName;
      if (t.teamCode.isNotEmpty) {
        teamNamesMap[t.teamCode.trim().toLowerCase()] = t.teamName;
      }
    }

    final Map<String, Program> programsMap = {
      for (final p in programs) p.id: p
    };

    final validResults = results
        .where((r) => r.status == ResultStatus.published)
        .toList();

    final Map<String, List<Result>> studentResultsMap = {};
    for (final res in validResults) {
      studentResultsMap.putIfAbsent(res.studentId, () => []).add(res);
    }

    final List<StudentTotalSummary> allSummaries = [];

    for (final student in students) {
      final studentIdKey = student.id;
      final chaseKey = student.chaseNumber.trim().toLowerCase();

      final directResults = studentResultsMap[studentIdKey] ?? [];
      final chaseResults = studentResultsMap[chaseKey] ?? [];
      final combinedResults = <Result>{...directResults, ...chaseResults}.toList();

      double totalMarks = 0.0;
      int totalPoints = 0;

      for (final r in combinedResults) {
        totalMarks += r.marks;
        totalPoints += r.points;
      }

      final teamName = teamNamesMap[student.teamId] ??
          teamNamesMap[student.teamId.toLowerCase()] ??
          'Team ${student.teamId}';

      allSummaries.add(
        StudentTotalSummary(
          student: student,
          teamName: teamName,
          totalMarks: totalMarks,
          totalPoints: totalPoints,
          programCount: combinedResults.length,
          results: combinedResults,
        ),
      );
    }

    allSummaries.sort((a, b) {
      final markCmp = b.totalMarks.compareTo(a.totalMarks);
      if (markCmp != 0) return markCmp;
      return b.totalPoints.compareTo(a.totalPoints);
    });

    for (int i = 0; i < allSummaries.length; i++) {
      allSummaries[i].overallRank = i + 1;
    }

    if (allSummaries.isNotEmpty && allSummaries.first.totalMarks > 0) {
      allSummaries.first.isOverallTop1 = true;
    }

    final Map<FestSection, List<StudentTotalSummary>> sectionMap = {};
    for (final section in FestSection.values) {
      sectionMap[section] = allSummaries
          .where((s) => s.student.section == section)
          .toList();

      sectionMap[section]!.sort((a, b) {
        final markCmp = b.totalMarks.compareTo(a.totalMarks);
        if (markCmp != 0) return markCmp;
        return b.totalPoints.compareTo(a.totalPoints);
      });

      for (int i = 0; i < sectionMap[section]!.length; i++) {
        final item = sectionMap[section]![i];
        item.sectionRank = i + 1;
        if (i == 0 && item.totalMarks > 0) {
          item.isSectionTop1 = true;
        } else if (i == 1 && item.totalMarks > 0) {
          item.isSectionTop2 = true;
        }
      }
    }

    List<StudentTotalSummary> filteredSummaries = allSummaries.where((item) {
      if (_totalSectionFilter != 'ALL') {
        final matchSec = item.student.section.name == _totalSectionFilter ||
            item.student.section.label.toLowerCase() == _totalSectionFilter.toLowerCase();
        if (!matchSec) return false;
      }

      if (_totalSearchQuery.isNotEmpty) {
        final q = _totalSearchQuery.toLowerCase();
        final matchChase = item.student.chaseNumber.toLowerCase().contains(q);
        final matchName = item.student.name.toLowerCase().contains(q);
        final matchTeam = item.teamName.toLowerCase().contains(q);
        if (!matchChase && !matchName && !matchTeam) return false;
      }

      return true;
    }).toList();

    if (_totalSortBy == 'chase') {
      filteredSummaries.sort((a, b) => a.student.chaseNumber.compareTo(b.student.chaseNumber));
    } else if (_totalSortBy == 'name') {
      filteredSummaries.sort((a, b) => a.student.name.compareTo(b.student.name));
    } else if (_totalSortBy == 'points') {
      filteredSummaries.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    }

    final overallTopScorer = allSummaries.isNotEmpty && allSummaries.first.totalMarks > 0
        ? allSummaries.first
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Marks & Section Standings',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.wood,
                    ),
                  ),
                  Text(
                    'Aggregated student totals, top section rankers, and exportable reports',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.file_download_rounded),
                label: const Text(
                  'Download Excel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _exportStudentTotalsExcel(allSummaries),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (overallTopScorer != null) ...[
            _buildOverallTopScorerHeroCard(overallTopScorer, programsMap),
            const SizedBox(height: 24),
          ],

          Text(
            'Top 2 Performers by Section',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.wood,
            ),
          ),
          const SizedBox(height: 12),
          _buildSectionTopPerformersRow(sectionMap, programsMap),
          const SizedBox(height: 28),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _totalSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search by Chase No, Student Name, or Team...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _totalSearchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _totalSectionFilter,
                      decoration: InputDecoration(
                        labelText: 'Section Filter',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: 'ALL', child: Text('All Sections')),
                        ...FestSection.values.map(
                          (sec) => DropdownMenuItem(
                            value: sec.name,
                            child: Text(sec.label),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _totalSectionFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _totalSortBy,
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'marks', child: Text('Total Marks (High to Low)')),
                        DropdownMenuItem(value: 'points', child: Text('Total Points (High to Low)')),
                        DropdownMenuItem(value: 'chase', child: Text('Chase Number')),
                        DropdownMenuItem(value: 'name', child: Text('Student Name')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _totalSortBy = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student Totals List (${filteredSummaries.length})',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Click "SEE BIG" to view individual mark sheet breakdown',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text('Overall Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Sec Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Chase No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Programs', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Total Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Total Points', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Highlight', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filteredSummaries.map((summary) {
                      final isTop1 = summary.isSectionTop1 || summary.isOverallTop1;
                      final isTop2 = summary.isSectionTop2;

                      Color? rowBgColor;
                      if (summary.isOverallTop1) {
                        rowBgColor = Colors.amber.shade50;
                      } else if (isTop1) {
                        rowBgColor = Colors.yellow.shade50;
                      } else if (isTop2) {
                        rowBgColor = Colors.grey.shade50;
                      }

                      return DataRow(
                        color: rowBgColor != null ? WidgetStateProperty.all(rowBgColor) : null,
                        cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: summary.overallRank == 1
                                    ? Colors.amber
                                    : (summary.overallRank == 2
                                        ? Colors.grey.shade400
                                        : (summary.overallRank == 3
                                            ? Colors.brown.shade300
                                            : Colors.blueGrey.shade100)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#${summary.overallRank}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: summary.overallRank <= 3 ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '#${summary.sectionRank}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            Text(
                              summary.student.chaseNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            Text(
                              summary.student.name,
                              style: TextStyle(
                                fontWeight: isTop1 || isTop2 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          DataCell(
                            Chip(
                              label: Text(
                                summary.student.section.label,
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFF1E293B),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          DataCell(Text(summary.teamName)),
                          DataCell(Text('${summary.programCount}')),
                          DataCell(
                            Text(
                              summary.totalMarks.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.green,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${summary.totalPoints} pts',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(
                            summary.topHighlightText != '-'
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: summary.isOverallTop1
                                          ? Colors.amber.shade200
                                          : (summary.isSectionTop1
                                              ? Colors.amber.shade100
                                              : Colors.blue.shade50),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: summary.isOverallTop1 ? Colors.amber : Colors.blue.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      summary.topHighlightText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: summary.isOverallTop1 ? Colors.brown.shade900 : Colors.blue.shade900,
                                      ),
                                    ),
                                  )
                                : const Text('-'),
                          ),
                          DataCell(
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              icon: const Icon(Icons.open_in_full_rounded, size: 14),
                              label: const Text('SEE BIG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _showBigStudentMarksheetModal(summary, programsMap),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallTopScorerHeroCard(
    StudentTotalSummary topScorer,
    Map<String, Program> programsMap,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.amber, width: 2),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🏆 FEST OVERALL TOP MARK SCORER',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        topScorer.student.section.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${topScorer.student.name} (Chase: ${topScorer.student.chaseNumber})',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Team: ${topScorer.teamName}',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${topScorer.totalMarks.toStringAsFixed(1)} Marks',
                style: GoogleFonts.outfit(
                  color: Colors.amber,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${topScorer.totalPoints} Points (${topScorer.programCount} Programs)',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.open_in_full_rounded, size: 16),
                label: const Text(
                  'SEE BIG (FULL MARKSHEET)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _showBigStudentMarksheetModal(topScorer, programsMap),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTopPerformersRow(
    Map<FestSection, List<StudentTotalSummary>> sectionMap,
    Map<String, Program> programsMap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: FestSection.values.map((section) {
            final list = sectionMap[section] ?? [];
            final top1 = list.isNotEmpty && list[0].totalMarks > 0 ? list[0] : null;
            final top2 = list.length > 1 && list[1].totalMarks > 0 ? list[1] : null;

            return SizedBox(
              width: constraints.maxWidth > 900
                  ? (constraints.maxWidth - 48) / 3
                  : (constraints.maxWidth > 600 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            section.label,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.wood,
                            ),
                          ),
                          Chip(
                            label: Text(
                              '${list.length} Students',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF1E293B),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      if (top1 != null)
                        _buildTopStudentMiniTile('🥇 1st Top Mark', top1, Colors.amber, programsMap)
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No rank 1 results yet', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      const SizedBox(height: 8),
                      if (top2 != null)
                        _buildTopStudentMiniTile('🥈 2nd Top Mark', top2, Colors.grey.shade400, programsMap)
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No rank 2 results yet', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTopStudentMiniTile(
    String badgeLabel,
    StudentTotalSummary summary,
    Color badgeColor,
    Map<String, Program> programsMap,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: badgeColor == Colors.amber ? Colors.brown.shade800 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${summary.student.chaseNumber})',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  summary.student.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${summary.teamName} • ${summary.totalMarks.toStringAsFixed(1)} Marks',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_full_rounded, size: 18),
            tooltip: 'SEE BIG (Marksheet)',
            onPressed: () => _showBigStudentMarksheetModal(summary, programsMap),
          ),
        ],
      ),
    );
  }

  void _showBigStudentMarksheetModal(
    StudentTotalSummary summary,
    Map<String, Program> programsMap,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 750,
            constraints: const BoxConstraints(maxHeight: 650),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.wood,
                      child: Text(
                        summary.student.name.isNotEmpty ? summary.student.name[0].toUpperCase() : 'S',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                summary.student.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.wood,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Chip(
                                label: Text(
                                  'Chase: ${summary.student.chaseNumber}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                backgroundColor: AppTheme.green,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          Text(
                            'Section: ${summary.student.section.label}  •  Team: ${summary.teamName}',
                            style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetricBadge(
                        'Total Marks',
                        summary.totalMarks.toStringAsFixed(1),
                        Colors.amber.shade700,
                        Icons.star_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetricBadge(
                        'Total Points',
                        '${summary.totalPoints} pts',
                        AppTheme.green,
                        Icons.military_tech_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetricBadge(
                        'Overall Rank',
                        '#${summary.overallRank}',
                        Colors.blue.shade700,
                        Icons.leaderboard_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetricBadge(
                        'Section Rank',
                        '#${summary.sectionRank} in ${summary.student.section.label}',
                        Colors.purple.shade700,
                        Icons.workspace_premium_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  'Itemized Program Mark Sheet (${summary.results.length} Programs)',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.wood,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: summary.results.isEmpty
                      ? const Center(
                          child: Text('No published program results for this student yet.'),
                        )
                      : SingleChildScrollView(
                          child: Table(
                            border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                            columnWidths: const {
                              0: FlexColumnWidth(1.2),
                              1: FlexColumnWidth(2.5),
                              2: FlexColumnWidth(1.2),
                              3: FlexColumnWidth(1.0),
                              4: FlexColumnWidth(1.0),
                              5: FlexColumnWidth(1.0),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey.shade100),
                                children: const [
                                  Padding(padding: EdgeInsets.all(10), child: Text('Prog Code', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(10), child: Text('Program Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(10), child: Text('Position', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(10), child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(10), child: Text('Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(10), child: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                              ...summary.results.map((res) {
                                final prog = programsMap[res.programId];
                                final code = prog?.programCode ?? res.programId;
                                final name = prog?.programName ?? 'Program ${res.programId}';

                                String posStr = '-';
                                if (res.position == 1) posStr = '🥇 1st Place';
                                if (res.position == 2) posStr = '🥈 2nd Place';
                                if (res.position == 3) posStr = '🥉 3rd Place';

                                return TableRow(
                                  children: [
                                    Padding(padding: const EdgeInsets.all(10), child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Padding(padding: const EdgeInsets.all(10), child: Text(name)),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        posStr,
                                        style: TextStyle(
                                          fontWeight: res.position != null ? FontWeight.bold : FontWeight.normal,
                                          color: res.position == 1 ? Colors.amber.shade800 : (res.position == 2 ? Colors.grey.shade800 : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    Padding(padding: const EdgeInsets.all(10), child: Text(res.grade.isNotEmpty ? res.grade : '-')),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        res.marks.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.green),
                                      ),
                                    ),
                                    Padding(padding: const EdgeInsets.all(10), child: Text('${res.points} pts')),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close Marksheet'),
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

  Widget _buildSummaryMetricBadge(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportStudentTotalsExcel(List<StudentTotalSummary> summaries) {
    try {
      final excelService = ExcelService(
        studentRepository: ref.read(studentRepositoryProvider),
        teamRepository: ref.read(teamRepositoryProvider),
        programRepository: ref.read(programRepositoryProvider),
        venueRepository: ref.read(venueRepositoryProvider),
        scheduleRepository: ref.read(scheduleRepositoryProvider),
        registrationRepository: ref.read(registrationRepositoryProvider),
      );

      final exportData = summaries.map((s) {
        return {
          'overallRank': s.overallRank,
          'sectionRank': s.sectionRank,
          'chaseNumber': s.student.chaseNumber,
          'name': s.student.name,
          'section': s.student.section.label,
          'teamName': s.teamName,
          'totalPrograms': s.programCount,
          'totalMarks': s.totalMarks,
          'totalPoints': s.totalPoints,
          'topHighlight': s.topHighlightText,
        };
      }).toList();

      final bytes = excelService.exportStudentTotalsToExcel(
        studentTotalsData: exportData,
      );

      Printing.sharePdf(
        bytes: bytes,
        filename: 'Fest_Student_Totals_Summary.xlsx',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel summary exported successfully!'),
          backgroundColor: AppTheme.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
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
            backgroundColor: rank == 1
                ? Colors.amber
                : (rank == 2
                      ? Colors.grey
                      : (rank == 3 ? Colors.brown : Colors.blueGrey)),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  teamCode,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${points.toStringAsFixed(1)} pts',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.red,
            ),
          ),
        ],
      ),
    );
  }
}
