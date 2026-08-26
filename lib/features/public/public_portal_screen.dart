import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui_components.dart';
import '../../data/models/student_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/result_model.dart';
import '../../data/models/schedule_model.dart';
import '../../services/qr_service.dart';

class PublicPortalScreen extends ConsumerStatefulWidget {
  const PublicPortalScreen({super.key});

  @override
  ConsumerState<PublicPortalScreen> createState() => _PublicPortalScreenState();
}

class _PublicPortalScreenState extends ConsumerState<PublicPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Filters
  FestSection _selectedSectionFilter = FestSection.junior;
  Student? _searchedStudent;
  bool _isScanningQr = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performStudentSearch(WidgetRef ref, String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final repo = ref.read(studentRepositoryProvider);
    final student = await repo.getByChaseNumber(clean);
    setState(() {
      _searchedStudent = student;
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final publishedResultsAsync = ref.watch(publishedResultsProvider);
    final programsAsync = ref.watch(programsProvider);
    final schedulesAsync = ref.watch(schedulesProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final venuesAsync = ref.watch(venuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.festival, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text(
              'FEST 2026',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => triggerDataRefresh(ref),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.login, size: 16),
            label: const Text('Portal Login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.live_tv), text: 'Live Results'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Published Results'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Schedule & Venues'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Chase Search & QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Home Tab
          _buildHomeTab(teamsAsync, publishedResultsAsync, programsAsync, schedulesAsync),
          // 2. Live Tab
          _buildLiveTab(publishedResultsAsync, programsAsync, teamsAsync, studentsAsync),
          // 3. Published Results Tab
          _buildPublishedResultsTab(publishedResultsAsync, programsAsync, teamsAsync, studentsAsync),
          // 4. Schedule & Venues Tab
          _buildScheduleTab(schedulesAsync, programsAsync, venuesAsync),
          // 5. Chase Search & QR Tab
          _buildChaseSearchTab(ref, studentsAsync, teamsAsync, programsAsync, publishedResultsAsync),
        ],
      ),
    );
  }

  // --- 1. HOME TAB ---
  Widget _buildHomeTab(
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Schedule>> schedulesAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME TO FEST 2026',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Annual Competition & Championship',
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  onPressed: () => _tabController.animateTo(2),
                  child: const Text('View All Published Results'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Live Scoreboard Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE TEAM SCOREBOARD',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('View Full Scoreboard'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Scoreboard Cards Grid
          teamsAsync.when(
            data: (teams) {
              if (teams.isEmpty) {
                return const Center(child: Text('No teams registered yet.'));
              }
              final firstTeam = teams[0];
              final remainingTeams = teams.length > 1 ? teams.sublist(1) : <Team>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // First row: Only the 1st team
                  TeamScoreCard(
                    rank: firstTeam.rank > 0 ? firstTeam.rank : 1,
                    teamName: firstTeam.teamName,
                    teamCode: firstTeam.teamCode,
                    leaderName: firstTeam.leaderName,
                    points: firstTeam.totalPoints,
                    isHighlight: true,
                  ),
                  if (remainingTeams.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    // Second row and beyond: 2nd, 3rd (and remaining) teams side-by-side
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth > 600 ? 2 : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            mainAxisExtent: 90,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: remainingTeams.length,
                          itemBuilder: (context, index) {
                            final team = remainingTeams[index];
                            return TeamScoreCard(
                              rank: team.rank > 0 ? team.rank : index + 2,
                              teamName: team.teamName,
                              teamCode: team.teamCode,
                              leaderName: team.leaderName,
                              points: team.totalPoints,
                              isHighlight: false,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading teams: $e'),
          ),

          const SizedBox(height: 32),
          Text(
            'TODAYS HIGHLIGHTED SCHEDULE',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          schedulesAsync.when(
            data: (schedules) {
              if (schedules.isEmpty) return const Text('No schedules posted for today.');
              final sampleScheds = schedules.take(4).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sampleScheds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final sched = sampleScheds[idx];
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event, color: AppTheme.primaryColor),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Program #${sched.programId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${sched.date} • ${sched.startTime}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(sched.status, style: const TextStyle(fontSize: 11)),
                          backgroundColor: sched.status == 'COMPLETED' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  // --- 2. LIVE TAB ---
  Widget _buildLiveTab(
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return resultsAsync.when(
      data: (results) {
        final published = results.where((r) => r.status == ResultStatus.published || r.status == ResultStatus.announced).toList();
        if (published.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No published results yet. Check back soon!'),
              ],
            ),
          );
        }

        final progs = programsAsync.value ?? [];
        final teams = teamsAsync.value ?? [];
        final students = studentsAsync.value ?? [];

        final Map<String, Program> progMap = {for (var p in progs) p.id: p};
        final Map<String, Team> teamMap = {for (var t in teams) t.id: t};
        final Map<String, Student> studMap = {for (var s in students) s.id: s};

        // Group by Program
        final Map<String, List<Result>> progResults = {};
        for (var r in published) {
          progResults.putIfAbsent(r.programId, () => []).add(r);
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: progResults.entries.map((entry) {
            final prog = progMap[entry.key];
            final rList = entry.value;
            rList.sort((a, b) => (a.position ?? 99).compareTo(b.position ?? 99));

            final firstRes = rList.firstWhere((r) => r.position == 1, orElse: () => rList.first);
            final secondRes = rList.firstWhere((r) => r.position == 2, orElse: () => rList.first);
            final thirdRes = rList.firstWhere((r) => r.position == 3, orElse: () => rList.first);

            final firstStud = studMap[firstRes.studentId];
            final secondStud = studMap[secondRes.studentId];
            final thirdStud = studMap[thirdRes.studentId];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ResultCard(
                programName: prog?.programName ?? 'Program ${entry.key}',
                section: prog?.section.label ?? 'Junior',
                winnerName: firstStud?.name ?? '—',
                winnerTeam: teamMap[firstRes.teamId]?.teamName ?? '—',
                secondName: secondStud?.name ?? '—',
                secondTeam: teamMap[secondRes.teamId]?.teamName ?? '—',
                thirdName: thirdStud?.name ?? '—',
                thirdTeam: teamMap[thirdRes.teamId]?.teamName ?? '—',
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // --- 3. PUBLISHED RESULTS TAB ---
  Widget _buildPublishedResultsTab(
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by Section', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SectionSelector(
                selectedSection: _selectedSectionFilter,
                onSelected: (sec) {
                  setState(() {
                    _selectedSectionFilter = sec;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildLiveTab(resultsAsync, programsAsync, teamsAsync, studentsAsync),
        ),
      ],
    );
  }

  // --- 4. SCHEDULE & VENUES TAB ---
  Widget _buildScheduleTab(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<dynamic>> venuesAsync,
  ) {
    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) return const Center(child: Text('No stage schedules available.'));
        final progs = programsAsync.value ?? [];
        final Map<String, Program> progMap = {for (var p in progs) p.id: p};

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final sched = schedules[index];
            final prog = progMap[sched.programId];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.schedule, color: Colors.white),
                ),
                title: Text(prog?.programName ?? 'Program Code: ${sched.programId}'),
                subtitle: Text('Venue: ${sched.venueId} • Date: ${sched.date} • Time: ${sched.startTime} - ${sched.endTime}'),
                trailing: Chip(
                  label: Text(sched.status),
                  backgroundColor: sched.status == 'COMPLETED' ? Colors.green[100] : Colors.blue[100],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading schedules: $e')),
    );
  }

  // --- 5. CHASE NUMBER SEARCH & QR TAB ---
  Widget _buildChaseSearchTab(
    WidgetRef ref,
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Result>> resultsAsync,
  ) {
    final teamMap = {for (var t in teamsAsync.value ?? []) t.id: t.teamName};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 550),
            child: AppCard(
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, size: 48, color: AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  Text('Search Student by Chase Number or Scan QR', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. CHASE-1001 or 1001',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (val) => _performStudentSearch(ref, val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _performStudentSearch(ref, _searchController.text),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: Icon(_isScanningQr ? Icons.close : Icons.camera_alt),
                    label: Text(_isScanningQr ? 'Close Scanner' : 'Scan Student QR Code'),
                    onPressed: () {
                      setState(() {
                        _isScanningQr = !_isScanningQr;
                      });
                    },
                  ),
                  if (_isScanningQr) ...[
                    const SizedBox(height: 16),
                    QRScannerWidget(
                      onScanned: (payload) {
                        final res = QrService.parseQrPayload(payload);
                        _searchController.text = res.value;
                        _performStudentSearch(ref, res.value);
                        setState(() {
                          _isScanningQr = false;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_searchedStudent != null) ...[
            Container(
              constraints: const BoxConstraints(maxWidth: 550),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_searchedStudent!.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Chase #: ${_searchedStudent!.chaseNumber}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Chip(label: Text(_searchedStudent!.section.label)),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Team: ${teamMap[_searchedStudent!.teamId] ?? _searchedStudent!.teamId}'),
                    Text('Class: ${_searchedStudent!.className}'),
                    Text('School: ${_searchedStudent!.schoolName}'),
                  ],
                ),
              ),
            ),
          ] else if (_searchController.text.isNotEmpty) ...[
            const Text('No student found matching this chase number.', style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}
