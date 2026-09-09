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
import '../../data/models/venue_model.dart';
import 'scan_and_qr_screen.dart';

class PublicPortalScreen extends ConsumerStatefulWidget {
  const PublicPortalScreen({super.key});

  @override
  ConsumerState<PublicPortalScreen> createState() => _PublicPortalScreenState();
}

class _PublicPortalScreenState extends ConsumerState<PublicPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  String _publicScheduleDate = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final publishedResultsAsync = ref.watch(publishedResultsProvider);
    final programsAsync = ref.watch(programsProvider);
    final schedulesAsync = ref.watch(schedulesProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final venuesAsync = ref.watch(venuesProvider);

    final navItems = const [
      SidebarNavItem(icon: Icons.home_outlined, label: 'Home'),
      SidebarNavItem(icon: Icons.live_tv, label: 'Live Results'),
      SidebarNavItem(
        icon: Icons.emoji_events_outlined,
        label: 'Published Results',
      ),
      SidebarNavItem(
        icon: Icons.calendar_month_outlined,
        label: 'Schedule & Venues',
      ),
      SidebarNavItem(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Search Chase / QR',
      ),
    ];

    final actions = [
      IconButton(
        icon: const Icon(Icons.refresh, color: AppTheme.ink),
        tooltip: 'Refresh Data',
        onPressed: () => triggerDataRefresh(ref),
      ),
      IconButton(
        icon: const Icon(Icons.login, color: AppTheme.red),
        tooltip: 'Portal Login',
        onPressed: () => context.go('/login'),
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
      headerTitle: 'ASKESIS FEST',
      headerSubtitle: 'Public Art Fest Portal',
      headerIcon: Icons.festival_outlined,
      headerColor: AppTheme.red,
      appBarActions: actions,
      brandHeader: AskesisBrandHeader(actions: actions),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Home Tab
          _buildHomeTab(
            teamsAsync,
            publishedResultsAsync,
            programsAsync,
            schedulesAsync,
            venuesAsync,
          ),
          // 2. Live Tab
          _buildLiveTab(
            publishedResultsAsync,
            programsAsync,
            teamsAsync,
            studentsAsync,
          ),
          // 3. Published Results Tab
          _buildPublishedResultsTab(
            publishedResultsAsync,
            programsAsync,
            teamsAsync,
            studentsAsync,
          ),
          // 4. Schedule & Venues Tab
          _buildScheduleTab(schedulesAsync, programsAsync, venuesAsync),
          // 5. Scan & QR Tab Page
          const ScanAndQrScreen(isEmbedded: true),
        ],
      ),
    );
  }

  void _navigateToScanPage([String? query]) {
    if (query != null && query.trim().isNotEmpty) {
      context.push('/scan?q=${Uri.encodeComponent(query.trim())}');
    } else {
      setState(() {
        _tabController.animateTo(4);
      });
    }
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cream2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, color: AppTheme.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SEARCH STUDENT BY CHASE NUMBER OR SCAN QR',
                  style: GoogleFonts.workSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
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
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.red,
                      ),
                      tooltip: 'Scan QR Code',
                      onPressed: () => _navigateToScanPage(),
                    ),
                  ),
                  onSubmitted: (val) => _navigateToScanPage(val),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: AppTheme.cream,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _navigateToScanPage(_searchController.text),
                child: const Text('Search'),
              ),
            ],
          ),
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
    AsyncValue<List<Venue>> venuesAsync,
  ) {
    final progs = programsAsync.value ?? [];
    final vens = venuesAsync.value ?? [];
    final progMap = {for (var p in progs) p.id: p};
    final venMap = {for (var v in vens) v.id: v};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Askesis Hero Banner with Top-Right Translucent Circle Overlay Design
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.red, AppTheme.redDeep],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.redDeep.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Translucent Circle Graphic Overlay (Top Right - Single Outline Circle)
                        Positioned(
                          top: -35,
                          right: -35,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                        // Banner Content
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 26,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WELCOME TO ASKESIS \'26',
                                style: GoogleFonts.workSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.cream.withValues(alpha: 0.75),
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Annual Art &\nCulture\nChampionship',
                                style: GoogleFonts.rye(
                                  fontSize: 26,
                                  height: 1.15,
                                  color: AppTheme.cream,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cream,
                                  foregroundColor: AppTheme.redDeep,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _tabController.animateTo(2),
                                child: Text(
                                  'View All Published Results',
                                  style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSearchCard(),
                const SizedBox(height: 24),

                // Live Team Scoreboard Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'LIVE TEAM SCOREBOARD',
                      style: GoogleFonts.workSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: AppTheme.ink,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _tabController.animateTo(2),
                      child: Text(
                        'Full Scoreboard →',
                        style: GoogleFonts.workSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Live VS Scoreboard Widget
                teamsAsync.when(
                  data: (teams) {
                    final leader = teams.isNotEmpty
                        ? {
                            'name': teams[0].teamName,
                            'leader': 'Leader: ${teams[0].leaderName ?? "—"}',
                            'pts': teams[0].totalPoints,
                          }
                        : {'name': "—", 'leader': '—', 'pts': 0};
                    final runner = teams.length > 1
                        ? {
                            'name': teams[1].teamName,
                            'leader': 'Leader: ${teams[1].leaderName ?? "—"}',
                            'pts': teams[1].totalPoints,
                          }
                        : {'name': "—", 'leader': '—', 'pts': 0};

                    return VsScoreboardWidget(
                      leaderTeam: leader,
                      runnerTeam: runner,
                    );
                  },
                  loading: () => const VsScoreboardWidget(
                    leaderTeam: {'name': "Loading...", 'leader': '', 'pts': 0},
                    runnerTeam: {'name': "Loading...", 'leader': '', 'pts': 0},
                  ),
                  error: (_, _) => const VsScoreboardWidget(
                    leaderTeam: {'name': "Error", 'leader': '', 'pts': 0},
                    runnerTeam: {'name': "Error", 'leader': '', 'pts': 0},
                  ),
                ),

                const SizedBox(height: 28),
                Text(
                  'TODAY\'S HIGHLIGHTED SCHEDULE',
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                schedulesAsync.when(
                  data: (schedules) {
                    if (schedules.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.cream2,
                          border: Border.all(color: AppTheme.line),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'No schedules posted for today.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(
                            color: AppTheme.inkSoft,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    final sampleScheds = schedules.take(4).toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sampleScheds.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final sched = sampleScheds[idx];
                        final prog = progMap[sched.programId];
                        final ven = venMap[sched.venueId];
                        final progTitle = prog?.programName ??
                            (sched.programId.isNotEmpty
                                ? sched.programId
                                : 'Scheduled Program');
                        final venName = ven?.name ??
                            (sched.venueId.isNotEmpty
                                ? sched.venueId
                                : 'Main Stage');

                        return AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event,
                                      color: AppTheme.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            progTitle,
                                            style: GoogleFonts.workSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${sched.date} • ${sched.startTime} • 📍 $venName',
                                            style: GoogleFonts.workSans(
                                              color: AppTheme.inkSoft,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: sched.status == 'COMPLETED'
                                      ? AppTheme.green.withValues(alpha: 0.15)
                                      : AppTheme.mustard.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  sched.status,
                                  style: GoogleFonts.workSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: sched.status == 'COMPLETED'
                                        ? AppTheme.green
                                        : AppTheme.ink,
                                  ),
                                ),
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
          ),
          const SizedBox(height: 12),
          const PatternStrip(height: 12),
        ],
      ),
    );
  }

  // --- 2. LIVE RESULTS TAB ---
  Widget _buildLiveTab(
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return resultsAsync.when(
      data: (results) {
        final published = results
            .where(
              (r) =>
                  r.status == ResultStatus.published ||
                  r.status == ResultStatus.announced,
            )
            .toList();

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

        Widget content;

        if (progResults.isEmpty) {
          content = Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.cream2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: Text(
              'No results published yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: AppTheme.inkSoft,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        } else {
          content = Column(
            children: progResults.entries.map((entry) {
              final prog = progMap[entry.key];
              final rList = entry.value;
              rList.sort(
                (a, b) => (a.position ?? 99).compareTo(b.position ?? 99),
              );

              final firstRes =
                  rList.where((r) => r.position == 1).firstOrNull ??
                  rList.firstOrNull;
              final secondRes = rList.where((r) => r.position == 2).firstOrNull;
              final thirdRes = rList.where((r) => r.position == 3).firstOrNull;

              final firstStud = firstRes != null
                  ? studMap[firstRes.studentId]
                  : null;
              final secondStud = secondRes != null
                  ? studMap[secondRes.studentId]
                  : null;
              final thirdStud = thirdRes != null
                  ? studMap[thirdRes.studentId]
                  : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ResultCard(
                  programName: prog?.programName ?? 'Unknown Program',
                  section: prog?.section.label ?? '—',
                  winnerName: firstStud?.name ?? '—',
                  winnerTeam: firstRes != null
                      ? (teamMap[firstRes.teamId]?.teamName ?? "—")
                      : "—",
                  secondName: secondStud?.name ?? '—',
                  secondTeam: secondRes != null
                      ? (teamMap[secondRes.teamId]?.teamName ?? "—")
                      : "—",
                  thirdName: thirdStud?.name ?? '—',
                  thirdTeam: thirdRes != null
                      ? (teamMap[thirdRes.teamId]?.teamName ?? '—')
                      : '—',
                ),
              );
            }).toList(),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(padding: const EdgeInsets.all(18), child: content),
              const SizedBox(height: 12),
              const PatternStrip(height: 12),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text('Error loading results: $e'),
        ),
      ),
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
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: _buildSearchCard(),
        ),
        Expanded(
          child: _buildLiveTab(
            resultsAsync,
            programsAsync,
            teamsAsync,
            studentsAsync,
          ),
        ),
      ],
    );
  }

  // --- 4. SCHEDULE & VENUES TAB ---
  Widget _buildScheduleTab(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Venue>> venuesAsync,
  ) {
    final schedules = schedulesAsync.value ?? [];
    final programs = programsAsync.value ?? [];
    final venues = venuesAsync.value ?? [];

    final Map<String, Program> progMap = {for (var p in programs) p.id: p};
    final Map<String, Venue> venMap = {for (var v in venues) v.id: v};

    // Filter schedules
    final filteredSchedules =
        schedules.where((s) {
          if (_publicScheduleDate != 'ALL' &&
              s.date.trim() != _publicScheduleDate) {
            return false;
          }
          return true;
        }).toList();

    // Sort chronologically by date and start time
    filteredSchedules.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      return a.startTime.compareTo(b.startTime);
    });

    final uniqueDates =
        schedules
            .map((s) => s.date.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.ink, Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      color: AppTheme.cream,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'EVENT & STAGE SCHEDULE',
                        style: GoogleFonts.rye(
                          fontSize: 20,
                          color: AppTheme.cream,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Browse program dates, stages, venues, and performance timings.',
                  style: GoogleFonts.workSans(
                    color: AppTheme.cream.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date Filter
          if (uniqueDates.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.line),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Date:',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.inkSoft,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All Dates'),
                      selected: _publicScheduleDate == 'ALL',
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        setState(() {
                          _publicScheduleDate = 'ALL';
                        });
                      },
                    ),
                    ...uniqueDates.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(d),
                          selected: _publicScheduleDate == d,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) {
                            setState(() {
                              _publicScheduleDate = d;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Schedule Cards
          if (filteredSchedules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                color: AppTheme.cream2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.event_busy_rounded,
                    size: 44,
                    color: AppTheme.inkSoft,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    schedules.isEmpty
                        ? 'No stage schedules published yet.'
                        : 'No schedules matching your search/filter.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: AppTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedules.isEmpty
                        ? 'Please check back once event organizers publish the schedule.'
                        : 'Try adjusting your search keywords or date filter.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: AppTheme.inkSoft,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'SHOWING ${filteredSchedules.length} SCHEDULES',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.inkSoft,
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSchedules.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final sch = filteredSchedules[idx];
                final prog = progMap[sch.programId];
                final ven = venMap[sch.venueId];
                final progName =
                    prog?.programName ??
                    (sch.programId.isNotEmpty
                        ? sch.programId
                        : 'Program #${sch.programId}');
                final progCode = prog?.programCode ?? '';
                final section = prog?.section.label ?? 'General';
                final venName =
                    ven?.name ??
                    (sch.venueId.isNotEmpty ? sch.venueId : 'Main Venue');
                final venLoc = ven?.location ?? '';

                Color statusBg = Colors.blue.withValues(alpha: 0.12);
                Color statusFg = Colors.blue.shade800;
                String statusLabel = sch.status;
                if (sch.status == 'IN_PROGRESS') {
                  statusBg = Colors.orange.withValues(alpha: 0.15);
                  statusFg = Colors.orange.shade900;
                  statusLabel = 'LIVE NOW';
                } else if (sch.status == 'COMPLETED') {
                  statusBg = Colors.green.withValues(alpha: 0.15);
                  statusFg = Colors.green.shade800;
                  statusLabel = 'COMPLETED';
                } else if (sch.status == 'CANCELLED') {
                  statusBg = Colors.red.withValues(alpha: 0.12);
                  statusFg = Colors.red.shade800;
                  statusLabel = 'CANCELLED';
                }

                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Box
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cream2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppTheme.red,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sch.startTime,
                                  style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                Text(
                                  sch.endTime,
                                  style: GoogleFonts.workSans(
                                    fontSize: 11,
                                    color: AppTheme.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Program Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        progName,
                                        style: GoogleFonts.workSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppTheme.ink,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: statusFg,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.line,
                                          ),
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
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
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
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.place,
                                          size: 14,
                                          color: AppTheme.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          venLoc.isNotEmpty
                                              ? '$venName ($venLoc)'
                                              : venName,
                                          style: GoogleFonts.workSans(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_month,
                                          size: 14,
                                          color: AppTheme.inkSoft,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          sch.date.isNotEmpty
                                              ? sch.date
                                              : 'Date TBA',
                                          style: GoogleFonts.workSans(
                                            fontSize: 12,
                                            color: AppTheme.inkSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
          const PatternStrip(height: 12),
        ],
      ),
    );
  }
}
