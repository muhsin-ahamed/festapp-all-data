import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../../services/excel_service.dart';
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

class _LeaderPortalScreenState extends ConsumerState<LeaderPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _studentNameController = TextEditingController();
  final _studentChaseController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  FestSection _studentSection = FestSection.subJunior;

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
    final currentTeam = teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => Team(id: teamId, teamName: 'My Team', teamCode: 'MY-TEAM'),
    );

    final allStudents = studentsAsync.value ?? [];
    final myStudents = allStudents.where((s) => s.teamId == teamId).toList();
    final allPrograms = programsAsync.value ?? [];
    final allRegs = regsAsync.value ?? [];
    final myRegs = allRegs.where((r) => r.teamId == teamId).toList();
    final publishedResults = resultsAsync.value ?? [];
    final myResults = publishedResults
        .where((r) => r.teamId == teamId)
        .toList();

    final navItems = const [
      SidebarNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      SidebarNavItem(icon: Icons.person_add_outlined, label: 'Team Students'),
      SidebarNavItem(
        icon: Icons.app_registration_outlined,
        label: 'Program Registration',
      ),
      SidebarNavItem(icon: Icons.emoji_events_outlined, label: 'Team Results'),
    ];

    final actions = [
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
      selectedIndex: _tabController.index,
      onDestinationSelected: (idx) {
        setState(() {
          _tabController.animateTo(idx);
        });
      },
      items: navItems,
      headerTitle: currentTeam.teamName.toUpperCase(),
      headerSubtitle: 'Team Leader Portal',
      headerIcon: Icons.groups_rounded,
      headerColor: AppTheme.olive,
      appBarActions: actions,
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
  Widget _buildDashboard(
    Team team,
    List<Student> students,
    List<Registration> regs,
    List<Result> results,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Leader of ${team.teamName}',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 900
                  ? 4
                  : (constraints.maxWidth > 500 ? 2 : 1);
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
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: 'Approved Registrations',
                    value: '${regs.length}',
                    icon: Icons.how_to_reg,
                    color: Colors.green,
                  ),
                  StatCard(
                    title: 'Team Total Score',
                    value: '${team.totalPoints} PTS',
                    icon: Icons.stars,
                    color: Colors.amber,
                  ),
                  StatCard(
                    title: 'Current Rank',
                    value: '#${team.rank > 0 ? team.rank : "-"}',
                    icon: Icons.military_tech,
                    color: Colors.purple,
                  ),
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
    final teams = ref.watch(teamsProvider).value ?? [];
    final teamName = teams
        .firstWhere(
          (t) => t.id == teamId,
          orElse: () => Team(id: teamId, teamName: 'My Team', teamCode: ''),
        )
        .teamName;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Single Student'),
        onPressed: () => _showAddStudentDialog(teamId),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Title and Excel Action Buttons
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                return isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Team Members (${myStudents.length})',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _buildStudentActionButtons(
                              teamId,
                              myStudents,
                              teamName,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Team Members (${myStudents.length})',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _buildStudentActionButtons(
                              teamId,
                              myStudents,
                              teamName,
                            ),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 16),

            // Excel Format & Import Guidelines Banner Card
            AppCard(
              child: ExpansionTile(
                leading: const Icon(
                  Icons.file_upload_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: Text(
                  'Excel Import Format & Instructions',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Click to view required Excel column headers and sample format',
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Excel Sheet Column Format:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      defaultColumnWidth: const IntrinsicColumnWidth(),
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Col 1: Chase Number*',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Col 2: Name*',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Col 3: Section',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Col 4: Gender',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Col 5: Phone',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Col 6: Class',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Col 7: School',
                                style: TextStyle(
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
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'CHASE-101',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Muhammed Ali',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Sub-Junior',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Male',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '9876543210',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Class 5',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Al-Huda Academy',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Note: Valid sections are "Sub Junior", "Senior", "Super Senior", "General". All imported students will be automatically assigned to your team.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Students List
            myStudents.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No students added yet.',
                          style: GoogleFonts.inter(
                            color: AppTheme.inkSoft,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Import Students via Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showExcelImportDialog(teamId),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myStudents.length,
                    itemBuilder: (context, idx) {
                      final s = myStudents[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.olive.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              s.name.isNotEmpty
                                  ? s.name.substring(0, 1).toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.olive,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                s.name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  s.chaseNumber,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: Colors.blue.shade50,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Section: ${s.section.label} • Gender: ${s.gender} ${s.className.isNotEmpty ? "• Class: ${s.className}" : ""}',
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
                                tooltip: 'Remove Student',
                                onPressed: () async {
                                  await ref
                                      .read(studentRepositoryProvider)
                                      .deleteStudent(s.id);
                                  triggerDataRefresh(ref);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${s.name} removed.'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentActionButtons(
    String teamId,
    List<Student> myStudents,
    String teamName,
  ) {
    return [
      ElevatedButton.icon(
        icon: const Icon(Icons.upload_file, size: 18),
        label: const Text('Import Excel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _showExcelImportDialog(teamId),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.file_download_outlined, size: 18),
        label: const Text('Download Template'),
        onPressed: _downloadStudentTemplate,
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.download, size: 18),
        label: const Text('Export Excel'),
        onPressed: () => _exportStudentsToExcel(myStudents, teamName),
      ),
    ];
  }

  void _downloadStudentTemplate() async {
    final excelService = ref.read(excelServiceProvider);
    final bytes = excelService.generateTeamStudentTemplate();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'team_students_template.xlsx',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloaded Excel Student Template.')),
      );
    }
  }

  void _exportStudentsToExcel(List<Student> myStudents, String teamName) async {
    if (myStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students available to export.')),
      );
      return;
    }
    final excelService = ref.read(excelServiceProvider);
    final bytes = excelService.exportTeamStudentsToExcel(myStudents, teamName);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${teamName.replaceAll(' ', '_')}_students.xlsx',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${myStudents.length} students to Excel.'),
        ),
      );
    }
  }

  void _showExcelImportDialog(String teamId) {
    String? selectedFileName;
    ExcelImportResult<Student>? importResult;
    bool isParsing = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.upload_file, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  const Text('Import Team Students via Excel'),
                ],
              ),
              content: SizedBox(
                width: 650,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload an Excel file (.xlsx, .xls, .csv) with student data. Required columns: Chase Number, Name.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // File Picker Button Box
                      InkWell(
                        onTap: () async {
                          final pickerResult = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['xlsx', 'xls', 'csv'],
                          );
                          if (pickerResult.isNotEmpty) {
                            final file = pickerResult.first;
                            final bytes = await file.readAsBytes();
                            setDialogState(() {
                              isParsing = true;
                              selectedFileName = file.name;
                            });

                            final excelService = ref.read(excelServiceProvider);
                            final result = await excelService
                                .importTeamStudents(bytes, teamId);

                            setDialogState(() {
                              importResult = result;
                              isParsing = false;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.05,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  selectedFileName != null
                                      ? Icons.description
                                      : Icons.cloud_upload_outlined,
                                  size: 36,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selectedFileName ??
                                      'Click to Browse & Select Excel File',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                if (selectedFileName != null)
                                  const Text(
                                    'File loaded. Parsing preview below...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (isParsing) ...[
                        const SizedBox(height: 20),
                        const Center(child: CircularProgressIndicator()),
                      ],

                      if (importResult != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Import Summary Preview',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildSummaryBadge(
                              'Total Rows',
                              '${importResult!.totalRows}',
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildSummaryBadge(
                              'Valid',
                              '${importResult!.validRows}',
                              Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildSummaryBadge(
                              'Duplicates',
                              '${importResult!.duplicateRows}',
                              Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            _buildSummaryBadge(
                              'Invalid',
                              '${importResult!.invalidRows}',
                              Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Error Log
                        if (importResult!.errors.isNotEmpty) ...[
                          Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: importResult!.errors
                                    .map(
                                      (err) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4.0,
                                        ),
                                        child: Text(
                                          '• $err',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Parsed Students Table Preview
                        if (importResult!.validItems.isNotEmpty) ...[
                          Text(
                            'Students to be Added (${importResult!.validItems.length}):',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: importResult!.validItems.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final st = importResult!.validItems[idx];
                                return ListTile(
                                  dense: true,
                                  leading: const CircleAvatar(
                                    radius: 12,
                                    child: Icon(Icons.person, size: 14),
                                  ),
                                  title: Text(
                                    '${st.name} (${st.chaseNumber})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Section: ${st.section.label} • Gender: ${st.gender} ${st.phone.isNotEmpty ? "• Phone: ${st.phone}" : ""}',
                                  ),
                                  trailing: const Chip(
                                    label: Text('VALID'),
                                    backgroundColor: Colors.greenAccent,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      importResult == null || importResult!.validItems.isEmpty
                      ? null
                      : () {
                          triggerDataRefresh(ref);
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully imported ${importResult!.importedRows} students to your team!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  child: Text(
                    importResult != null
                        ? 'Done (${importResult!.importedRows} Imported)'
                        : 'Import Students',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryBadge(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Chase Number',
                  controller: _studentChaseController,
                  hint: 'e.g. CHASE-1088',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Student Name',
                  controller: _studentNameController,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Phone',
                  controller: _studentPhoneController,
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
                if (!mounted) return;
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
      activeStudent =
          myStudents.where((s) => s.id == _selectedStudentForReg).firstOrNull ??
          myStudents.firstOrNull;
    } else if (myStudents.isNotEmpty) {
      activeStudent = myStudents.first;
    }

    int nonStageUsed = 0;
    int stageUsed = 0;

    if (activeStudent != null) {
      final studentRegs = allRegs
          .where((r) => r.studentId == activeStudent!.id)
          .toList();
      for (final reg in studentRegs) {
        final prog = allPrograms.firstWhere(
          (p) => p.id == reg.programId,
          orElse: () => Program(
            id: '',
            programCode: '',
            programName: '',
            section: FestSection.subJunior,
            category: ProgramCategory.stage,
            isStageProgram: true,
            isGeneral: false,
          ),
        );
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
          Text(
            'Student Program Registration',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppDropdown<String>(
                  label: 'Select Student',
                  value: activeStudent?.id,
                  items: myStudents
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            '${s.name} (${s.chaseNumber}) - ${s.section.label}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedStudentForReg = val),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Non-Stage Slot Usage',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$nonStageUsed / ${AppConstants.maxNonStagePerStudent}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            'Remaining: $remainingNonStage',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Stage Slot Usage',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$stageUsed / ${AppConstants.maxStagePerStudent}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          Text(
                            'Remaining: $remainingStage',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppDropdown<String>(
                  label: 'Select Program to Apply',
                  value:
                      _selectedProgramForReg ??
                      (allPrograms.isNotEmpty ? allPrograms.first.id : null),
                  items: allPrograms
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.programName} (${p.section.label}) [${p.isStageProgram ? "Stage" : "Non-Stage"}]',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedProgramForReg = val),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Register Student for Program',
                  onPressed: () async {
                    if (activeStudent == null || _selectedProgramForReg == null)
                      return;
                    final targetProg = allPrograms.firstWhere(
                      (p) => p.id == _selectedProgramForReg,
                    );

                    // 1. Check duplicate registration
                    final isDuplicate = allRegs.any(
                      (r) =>
                          r.studentId == activeStudent!.id &&
                          r.programId == targetProg.id,
                    );
                    if (isDuplicate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Student is already registered for this program!',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 2. Validate section
                    if (!targetProg.isGeneral &&
                        targetProg.section != activeStudent.section) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Section mismatch! ${activeStudent.name} is in ${activeStudent.section.label}, but program is in ${targetProg.section.label}.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 3. Enforce slot limits
                    if (!targetProg.isGeneral) {
                      if (targetProg.isStageProgram && remainingStage <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Stage program limit reached (Max 3 stage programs allowed)!',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (!targetProg.isStageProgram &&
                          remainingNonStage <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Non-stage program limit reached (Max 4 non-stage programs allowed)!',
                            ),
                            backgroundColor: Colors.red,
                          ),
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

                    await ref
                        .read(registrationRepositoryProvider)
                        .addRegistration(reg);
                    triggerDataRefresh(ref);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Successfully registered ${activeStudent.name} for ${targetProg.programName}!',
                        ),
                        backgroundColor: Colors.green,
                      ),
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
  Widget _buildTeamResultsTab(
    List<Result> myResults,
    List<Program> allPrograms,
    List<Student> allStudents,
  ) {
    final progMap = {for (var p in allPrograms) p.id: p.programName};
    final studMap = {for (var s in allStudents) s.id: s.name};

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Published Team Results (${myResults.length})',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: myResults.length,
              itemBuilder: (context, idx) {
                final r = myResults[idx];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${progMap[r.programId] ?? "Program"} - ${studMap[r.studentId] ?? "Student"}',
                    ),
                    subtitle: Text('Grade: ${r.grade} • Marks: ${r.marks}'),
                    trailing: Text(
                      '+${r.points} PTS',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
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
