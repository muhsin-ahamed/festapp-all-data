import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui_components.dart';
import '../../core/widgets/fest_result_poster.dart';
import '../../data/models/team_model.dart';
import '../../data/models/result_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/student_model.dart';
import '../../services/tv_service.dart';

class TvPortalScreen extends ConsumerStatefulWidget {
  const TvPortalScreen({super.key});

  @override
  ConsumerState<TvPortalScreen> createState() => _TvPortalScreenState();
}

class _TvPortalScreenState extends ConsumerState<TvPortalScreen> {
  bool _showExitOverlay = false;
  final FocusNode _focusNode = FocusNode();
  DateTime? _lastEscTime;
  Timer? _dataRefreshTimer;
  final GlobalKey<TvResultsCarouselViewState> _carouselKey =
      GlobalKey<TvResultsCarouselViewState>();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    // Background refresh data every 30 seconds for TV screen
    _dataRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        triggerDataRefresh(ref);
      }
    });
  }

  @override
  void dispose() {
    _dataRefreshTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        final now = DateTime.now();
        if (_lastEscTime != null &&
            now.difference(_lastEscTime!).inMilliseconds < 150) {
          return true;
        }
        _lastEscTime = now;
        setState(() {
          _showExitOverlay = !_showExitOverlay;
        });
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.pageDown) {
        final state = _carouselKey.currentState;
        if (state != null) {
          state.nextSlide();
          return true;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.pageUp) {
        final state = _carouselKey.currentState;
        if (state != null) {
          state.previousSlide();
          return true;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.space) {
        final state = _carouselKey.currentState;
        if (state != null) {
          state.togglePause();
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tvService = ref.watch(tvServiceProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final publishedResultsAsync = ref.watch(publishedResultsProvider);
    final resultsAsync = ref.watch(resultsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    final programsAsync = ref.watch(programsProvider);
    final studentsAsync = ref.watch(studentsProvider);

    final announcements = announcementsAsync.value ?? [];
    final activeAnnouncement = announcements.isNotEmpty
        ? announcements.first
        : null;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    final mode = tvService.settings.screenMode;
    Widget currentWidget;
    bool isPosterShowing = false;

    if (mode == 'ONLY_MAIN' || mode == 'POSTER') {
      currentWidget = _buildTvPosterScreen(context);
      isPosterShowing = true;
    } else if (mode == 'ANNOUNCE_RESULT') {
      currentWidget = _buildTvAnnouncementPosterScreen(
        context,
        tvService,
        programsAsync,
        resultsAsync,
        studentsAsync,
        teamsAsync,
      );
      isPosterShowing = true;
    } else if (mode == 'SCOREBOARD') {
      currentWidget = _buildTvScoreboardScreen(context, teamsAsync, isCompact);
      isPosterShowing = true;
    } else if (mode == 'RESULTS') {
      currentWidget = _buildTvResultsScreen(
        context,
        publishedResultsAsync,
        programsAsync,
        teamsAsync,
        studentsAsync,
        isCompact,
      );
    } else if (mode == 'AUTO_WITHOUT_SCOREBOARD') {
      // 2 slides: 0 -> Main Poster, 1 -> Results
      if (tvService.currentSlideIndex % 2 == 0) {
        currentWidget = _buildTvPosterScreen(context);
        isPosterShowing = true;
      } else {
        currentWidget = _buildTvResultsScreen(
          context,
          publishedResultsAsync,
          programsAsync,
          teamsAsync,
          studentsAsync,
          isCompact,
        );
      }
    } else {
      // AUTO_WITH_SCOREBOARD or default AUTO (3 slides: 0: Main, 1: Published Results, 2: Scoreboard)
      switch (tvService.currentSlideIndex % 3) {
        case 0:
          currentWidget = _buildTvPosterScreen(context);
          isPosterShowing = true;
          break;
        case 1:
          currentWidget = _buildTvResultsScreen(
            context,
            publishedResultsAsync,
            programsAsync,
            teamsAsync,
            studentsAsync,
            isCompact,
          );
          break;
        case 2:
        default:
          currentWidget = _buildTvScoreboardScreen(context, teamsAsync, isCompact);
          isPosterShowing = true;
          break;
      }
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isPosterShowing ? const Color(0xFFF8F6E7) : AppTheme.wood,
      body: Stack(
        children: [
          // Background content switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: currentWidget,
          ),

          // Top Pattern Strip & Header Bar (Shown only when not in full-screen poster mode)
          if (!isPosterShowing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const PatternStrip(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 20 : 40,
                      vertical: isCompact ? 14 : 22,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const BrandMark(size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Askesis Art Fest \'26',
                                      style: GoogleFonts.rye(
                                        fontSize: isCompact ? 20 : 32,
                                        color: AppTheme.cream,
                                        letterSpacing: 1.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'LIVE DISPLAY PORTAL',
                                      style: GoogleFonts.workSans(
                                        fontSize: isCompact ? 11 : 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.mustard,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 12 : 20,
                            vertical: isCompact ? 8 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.red,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.red.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.fiber_manual_record,
                                color: AppTheme.cream,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE',
                                style: GoogleFonts.workSans(
                                  color: AppTheme.cream,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 12 : 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Animated Overlay Banner for Announcements
          if (activeAnnouncement != null) ...[
            Positioned(
              bottom: isCompact ? 20 : 40,
              left: isCompact ? 20 : 40,
              right: isCompact ? 20 : 40,
              child: Card(
                color: AppTheme.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 20.0 : 28.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.campaign,
                        color: AppTheme.mustard,
                        size: 44,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeAnnouncement.title,
                              style: GoogleFonts.rye(
                                fontSize: isCompact ? 20 : 26,
                                color: AppTheme.cream,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              activeAnnouncement.message,
                              style: GoogleFonts.workSans(
                                fontSize: isCompact ? 14 : 18,
                                color: AppTheme.cream.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Subtle ESC Hint at bottom right
          Positioned(
            bottom: 12,
            right: 16,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showExitOverlay ? 0.0 : 0.45,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Press ESC to exit',
                        style: GoogleFonts.workSans(
                          fontSize: 10.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Exit / Logout Overlay banner triggered by ESC key
          if (_showExitOverlay)
            Positioned(
              top: 24,
              left: 16,
              right: 16,
              child: Center(
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.cream,
                  shadowColor: Colors.black.withValues(alpha: 0.6),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 580),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 14 : 20,
                      vertical: isCompact ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.red, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.red.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tv_off_rounded,
                            color: AppTheme.red,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TV Display Controls',
                                style: GoogleFonts.rye(
                                  fontSize: isCompact ? 14 : 16,
                                  color: AppTheme.ink,
                                ),
                              ),
                              Text(
                                'Press ESC to dismiss',
                                style: GoogleFonts.workSans(
                                  fontSize: isCompact ? 10 : 11.5,
                                  color: AppTheme.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.red,
                            foregroundColor: AppTheme.cream,
                            elevation: 4,
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 12 : 18,
                              vertical: isCompact ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text(
                            'Logout to Public Screen',
                            style: GoogleFonts.workSans(
                              fontWeight: FontWeight.w800,
                              fontSize: isCompact ? 12 : 13,
                            ),
                          ),
                          onPressed: () async {
                            final auth = ref.read(authServiceProvider);
                            await auth.logout();
                            ref.read(currentUserProvider.notifier).state = null;
                            if (context.mounted) {
                              context.go('/public');
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.inkSoft,
                            size: 20,
                          ),
                          tooltip: 'Dismiss (Esc)',
                          onPressed: () {
                            setState(() {
                              _showExitOverlay = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  // --- SCREEN 0: TV FEST POSTER ---
  Widget _buildTvPosterScreen(BuildContext context) {
    return Container(
      key: const ValueKey('tv_poster'),
      color: AppTheme.cream,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/images/tv_poster.png',
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Poster Image Not Found',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- SCREEN: ANNOUNCE RESULT POSTER ---
  Widget _buildTvAnnouncementPosterScreen(
    BuildContext context,
    TvService tvService,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Student>> studentsAsync,
    AsyncValue<List<Team>> teamsAsync,
  ) {
    final progId = tvService.settings.announcedProgramId;
    final progs = programsAsync.value ?? [];
    final results = resultsAsync.value ?? [];
    final students = studentsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];

    final prog = progs.where((p) => p.id == progId).firstOrNull;
    final progName = prog?.programName ?? 'CHAMPIONSHIP RESULT';
    final sectionLabel = prog?.section.label ?? 'GENERAL';

    final progResults = results.where((r) => r.programId == progId).toList();
    final res1 = progResults.where((r) => r.position == 1).firstOrNull;
    final res2 = progResults.where((r) => r.position == 2).firstOrNull;
    final res3 = progResults.where((r) => r.position == 3).firstOrNull;

    final studMap = {for (var s in students) s.id: s};
    final teamMap = {for (var t in teams) t.id: t};

    final s1 = res1 != null ? studMap[res1.studentId] : null;
    final t1 = res1 != null ? teamMap[res1.teamId] : null;
    final s2 = res2 != null ? studMap[res2.studentId] : null;
    final t2 = res2 != null ? teamMap[res2.teamId] : null;
    final s3 = res3 != null ? studMap[res3.studentId] : null;
    final t3 = res3 != null ? teamMap[res3.teamId] : null;

    final revealed = tvService.settings.revealedPositions;
    final resNum = tvService.settings.announcedResultNumber ?? 1;
    final resNumStr = resNum < 10 ? '0$resNum' : '$resNum';

    return Container(
      key: const ValueKey('tv_announcement_poster'),
      color: const Color(0xFFF8F6E7),
      width: double.infinity,
      height: double.infinity,
      child: FestResultPoster(
        resultNumber: resNumStr,
        programName: progName,
        sectionLabel: sectionLabel,
        winner1: s1 != null || res1 != null
            ? FestResultWinner(
                position: 1,
                studentName: s1?.name ?? (res1 != null ? 'Winner' : ''),
                chaseNumber: s1?.chaseNumber ?? '',
                teamName: t1?.teamName ?? '',
                grade: res1?.grade,
              )
            : null,
        winner2: s2 != null || res2 != null
            ? FestResultWinner(
                position: 2,
                studentName: s2?.name ?? (res2 != null ? 'Winner' : ''),
                chaseNumber: s2?.chaseNumber ?? '',
                teamName: t2?.teamName ?? '',
                grade: res2?.grade,
              )
            : null,
        winner3: s3 != null || res3 != null
            ? FestResultWinner(
                position: 3,
                studentName: s3?.name ?? (res3 != null ? 'Winner' : ''),
                chaseNumber: s3?.chaseNumber ?? '',
                teamName: t3?.teamName ?? '',
                grade: res3?.grade,
              )
            : null,
        revealedPositions: revealed.toSet(),
        isRevealMode: true,
      ),
    );
  }
  Widget _buildTvScoreboardScreen(
    BuildContext context,
    AsyncValue<List<Team>> teamsAsync,
    bool isCompact,
  ) {
    return Container(
      key: const ValueKey('tv_scoreboard'),
      color: const Color(0xFFF8F6E7),
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // 1. Subtle Paper Contour Texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.65,
              child: Image.asset(
                'assets/images/tv_bg_texture.jpg',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Left Botanical Foliage Framing
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/tv_leaves_left.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 3. Right Botanical Foliage Framing
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/tv_leaves_right.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 4. Main Scoreboard Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final teams = teamsAsync.value;
                if (teamsAsync.isLoading && teams == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.red),
                  );
                }

                if (teamsAsync.hasError && teams == null) {
                  return Center(
                    child: Text(
                      'Error loading scoreboard: ${teamsAsync.error}',
                      style: const TextStyle(color: AppTheme.red, fontSize: 18),
                    ),
                  );
                }

                if (teams == null || teams.isEmpty) {
                  return const Center(
                    child: Text(
                      'No team scores calculated.',
                      style: TextStyle(color: Color(0xFF241A12), fontSize: 20),
                    ),
                  );
                }

                final team1 = teams[0];
                final team2 = teams.length > 1 ? teams[1] : null;
                final remainingTeams =
                    teams.length > 2 ? teams.sublist(2) : <Team>[];

                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final isCompactView = w < 720 || h < 450;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactView ? 16.0 : (w > 1200 ? 56.0 : 36.0),
                    vertical: isCompactView ? 10.0 : 16.0,
                  ),
                  child: Column(
                    children: [
                      // Top Header Bar
                      Padding(
                        padding:
                            EdgeInsets.only(bottom: isCompactView ? 6.0 : 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const BrandMark(size: 26),
                                const SizedBox(width: 10),
                                Text(
                                  "Askesis Art Fest '26",
                                  style: GoogleFonts.rye(
                                    fontSize: isCompactView ? 14 : 18,
                                    color: const Color(0xFF241A12),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompactView ? 10 : 14,
                                vertical: isCompactView ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF8F2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2DCBE),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF9C2B22),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'LIVE SCOREBOARD',
                                    style: GoogleFonts.workSans(
                                      fontSize: isCompactView ? 10 : 12,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF241A12),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main Two Team Cards Center Stage
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Card (#1 Leader)
                                Expanded(
                                  child: _buildTvScoreboardCard(
                                    team: team1,
                                    rank: 1,
                                    isLeader: true,
                                    isCompact: isCompactView,
                                  ),
                                ),

                                // Center VS Divider
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompactView ? 6.0 : 14.0,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/tv_vs_divider.png',
                                      height: isCompactView ? 140 : 210,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) =>
                                          _buildFallbackVsDivider(isCompactView),
                                    ),
                                  ),
                                ),

                                // Right Card (#2 Runner-Up)
                                Expanded(
                                  child: team2 != null
                                      ? _buildTvScoreboardCard(
                                          team: team2,
                                          rank: 2,
                                          isLeader: false,
                                          isCompact: isCompactView,
                                        )
                                      : _buildAwaitingTeamCard(isCompactView),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom Strip for Remaining Teams (#3, #4, etc.)
                      if (remainingTeams.isNotEmpty) ...[
                        SizedBox(height: isCompactView ? 8 : 12),
                        SizedBox(
                          height: isCompactView ? 46 : 56,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: remainingTeams.length,
                            itemBuilder: (context, idx) {
                              final t = remainingTeams[idx];
                              final rank = idx + 3;
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompactView ? 12 : 18,
                                  vertical: isCompactView ? 6 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF8F2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2DCBE),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x08000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#$rank ${t.teamName}',
                                      style: GoogleFonts.workSans(
                                        fontSize: isCompactView ? 12 : 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1B1B1B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${t.totalPoints} PTS',
                                      style: GoogleFonts.rye(
                                        fontSize: isCompactView ? 14 : 17,
                                        color: const Color(0xFF9C2B22),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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

  Widget _buildTvScoreboardCard({
    required Team team,
    required int rank,
    required bool isLeader,
    required bool isCompact,
  }) {
    final initials = team.teamName.length >= 2
        ? team.teamName.substring(0, 2).toUpperCase()
        : team.teamName.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE2DCBE),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final isVeryCompact = h < 320;
          final isMedium = h >= 320 && h < 480;

          // Responsive sizing
          final badgeHeight = isVeryCompact ? 28.0 : (isMedium ? 36.0 : 44.0);
          final stampSize = isVeryCompact ? 56.0 : (isMedium ? 74.0 : 92.0);
          final initialsSize = isVeryCompact ? 20.0 : (isMedium ? 26.0 : 34.0);
          final teamNameSize = isVeryCompact ? 18.0 : (isMedium ? 26.0 : 34.0);
          final leaderBannerHeight =
              isVeryCompact ? 22.0 : (isMedium ? 28.0 : 34.0);
          final leaderFontSize =
              isVeryCompact ? 10.0 : (isMedium ? 12.0 : 14.0);
          final scoreFontSize =
              isVeryCompact ? 36.0 : (isMedium ? 50.0 : 68.0);

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10.0 : 20.0,
              vertical: isVeryCompact ? 10.0 : (isMedium ? 16.0 : 24.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Top Rank Brush Badge (#1 LEADER with trophy or #2 RUNNER-UP)
                Image.asset(
                  isLeader
                      ? 'assets/images/tv_badge_leader.png'
                      : 'assets/images/tv_badge_runnerup.png',
                  height: badgeHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      _buildFallbackRankBadge(isLeader, badgeHeight),
                ),

                // 2. Middle Section: Stamp Avatar + Team Name + Leader Banner
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular Stamp Avatar with Initials
                    SizedBox(
                      width: stampSize,
                      height: stampSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            isLeader
                                ? 'assets/images/tv_stamp_red.png'
                                : 'assets/images/tv_stamp_green.png',
                            width: stampSize,
                            height: stampSize,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => CircleAvatar(
                              radius: stampSize / 2,
                              backgroundColor:
                                  isLeader ? AppTheme.red : AppTheme.olive,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              initials,
                              style: GoogleFonts.rye(
                                color: Colors.white,
                                fontSize: initialsSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isVeryCompact ? 4 : 8),

                    // Team Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          team.teamName,
                          style: GoogleFonts.workSans(
                            fontSize: teamNameSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1B1B1B),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                    ),

                    // Leader Name on Brush Banner
                    if (team.leaderName != null &&
                        team.leaderName!.isNotEmpty) ...[
                      SizedBox(height: isVeryCompact ? 4 : 6),
                      SizedBox(
                        height: leaderBannerHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/tv_banner_leader.png',
                              height: leaderBannerHeight,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A7446),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14.0,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Leader: ${team.leaderName}',
                                  style: GoogleFonts.workSans(
                                    fontSize: leaderFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // 3. Score (Stylized Vintage Numerals)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${team.totalPoints}',
                    style: GoogleFonts.rye(
                      fontSize: scoreFontSize,
                      color: isLeader
                          ? const Color(0xFF9C2B22)
                          : const Color(0xFF1B1B1B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackVsDivider(bool isCompact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 2, height: 24, color: const Color(0xFF345D3B)),
        const SizedBox(height: 4),
        Transform.rotate(
          angle: 0.7854,
          child:
              Container(width: 10, height: 10, color: const Color(0xFF345D3B)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: isCompact ? 40 : 54,
          height: isCompact ? 44 : 58,
          child: ClipPath(
            clipper: AskesisCrestClipper(),
            child: Container(
              color: const Color(0xFF9C2B22),
              alignment: Alignment.center,
              child: Text(
                'VS',
                style: GoogleFonts.rye(
                  color: Colors.white,
                  fontSize: isCompact ? 16 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Transform.rotate(
          angle: 0.7854,
          child:
              Container(width: 10, height: 10, color: const Color(0xFF345D3B)),
        ),
        const SizedBox(height: 4),
        Container(width: 2, height: 24, color: const Color(0xFF345D3B)),
      ],
    );
  }

  Widget _buildFallbackRankBadge(bool isLeader, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E5336),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeader) ...[
            const Icon(Icons.emoji_events_rounded,
                color: Color(0xFF9C2B22), size: 18),
            const SizedBox(width: 6),
          ],
          Text(
            isLeader ? '#1 LEADER' : '#2 RUNNER-UP',
            style: GoogleFonts.workSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingTeamCard(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2DCBE), width: 1.5),
      ),
      child: const Center(
        child: Text(
          'Awaiting 2nd Team',
          style: TextStyle(
            color: Color(0xFF5A4E3F),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --- SCREEN 2: TV LATEST RESULTS ---
  Widget _buildTvResultsScreen(
    BuildContext context,
    AsyncValue<List<Result>> resultsAsync,
    AsyncValue<List<Program>> programsAsync,
    AsyncValue<List<Team>> teamsAsync,
    AsyncValue<List<Student>> studentsAsync,
    bool isCompact,
  ) {
    final results = resultsAsync.value;
    if (resultsAsync.isLoading && results == null) {
      return Container(
        key: const ValueKey('tv_results'),
        padding: EdgeInsets.fromLTRB(
          isCompact ? 20 : 44,
          isCompact ? 90 : 110,
          isCompact ? 20 : 44,
          isCompact ? 20 : 28,
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.mustard),
        ),
      );
    }

    if (resultsAsync.hasError && results == null) {
      return Container(
        key: const ValueKey('tv_results'),
        padding: EdgeInsets.fromLTRB(
          isCompact ? 20 : 44,
          isCompact ? 90 : 110,
          isCompact ? 20 : 44,
          isCompact ? 20 : 28,
        ),
        child: Center(
          child: Text(
            'Error: ${resultsAsync.error}',
            style: const TextStyle(color: AppTheme.cream),
          ),
        ),
      );
    }

    final published = (results ?? [])
        .where(
          (r) =>
              r.status == ResultStatus.published ||
              r.status == ResultStatus.announced,
        )
        .toList();

    if (published.isEmpty) {
      return Container(
        key: const ValueKey('tv_results'),
        padding: EdgeInsets.fromLTRB(
          isCompact ? 20 : 44,
          isCompact ? 90 : 110,
          isCompact ? 20 : 44,
          isCompact ? 20 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'RESULTS',
                    style: GoogleFonts.rye(
                      fontSize: isCompact ? 22 : 32,
                      color: AppTheme.mustard,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 18,
                    vertical: isCompact ? 6 : 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cream2,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.line, width: 1.5),
                  ),
                  child: Text(
                    'LIVE RESULTS PORTAL',
                    style: GoogleFonts.workSans(
                      fontSize: isCompact ? 11 : 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ],
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'No published results available yet.',
                  style: TextStyle(color: AppTheme.cream, fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final progs = programsAsync.value ?? [];
    final teams = teamsAsync.value ?? [];
    final students = studentsAsync.value ?? [];

    final progMap = {for (var p in progs) p.id: p};
    final teamMap = {for (var t in teams) t.id: t};
    final studMap = {for (var s in students) s.id: s};

    // Group published results by Program
    final Map<String, List<Result>> progGroups = {};
    for (var r in published) {
      progGroups.putIfAbsent(r.programId, () => []).add(r);
    }

    // Sort program groups by published date of newest result
    final progKeys = progGroups.keys.toList();
    progKeys.sort((a, b) {
      final maxTimeA = progGroups[a]!
          .map((r) => r.publishedAt ?? r.createdAt)
          .reduce((v, e) => v.isAfter(e) ? v : e);
      final maxTimeB = progGroups[b]!
          .map((r) => r.publishedAt ?? r.createdAt)
          .reduce((v, e) => v.isAfter(e) ? v : e);
      return maxTimeB.compareTo(maxTimeA);
    });

    return Container(
      key: const ValueKey('tv_results'),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 20 : 44,
        isCompact ? 90 : 110,
        isCompact ? 20 : 44,
        isCompact ? 20 : 28,
      ),
      child: TvResultsCarouselView(
        key: _carouselKey,
        progKeys: progKeys,
        progMap: progMap,
        progGroups: progGroups,
        teamMap: teamMap,
        studMap: studMap,
        isCompact: isCompact,
        slideDurationSeconds: 8,
      ),
    );
  }
}

class TvResultsCarouselView extends StatefulWidget {
  final List<String> progKeys;
  final Map<String, Program> progMap;
  final Map<String, List<Result>> progGroups;
  final Map<String, Team> teamMap;
  final Map<String, Student> studMap;
  final bool isCompact;
  final int slideDurationSeconds;

  const TvResultsCarouselView({
    super.key,
    required this.progKeys,
    required this.progMap,
    required this.progGroups,
    required this.teamMap,
    required this.studMap,
    required this.isCompact,
    this.slideDurationSeconds = 8,
  });

  @override
  State<TvResultsCarouselView> createState() => TvResultsCarouselViewState();
}

class TvResultsCarouselViewState extends State<TvResultsCarouselView> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _isPaused = false;
  static const int _virtualMultiplier = 1000;

  int get _initialVirtualPage {
    if (widget.progKeys.isEmpty) return 0;
    final half = (widget.progKeys.length * _virtualMultiplier) ~/ 2;
    return half - (half % widget.progKeys.length);
  }

  int get actualIndex {
    if (widget.progKeys.isEmpty) return 0;
    return _currentPage % widget.progKeys.length;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.progKeys.length > 1 ? _initialVirtualPage : 0;
    _pageController = PageController(initialPage: initial);
    _currentPage = initial;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant TvResultsCarouselView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progKeys.length != oldWidget.progKeys.length) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _autoSlideTimer?.cancel();
    if (widget.progKeys.length > 1 && !_isPaused) {
      _autoSlideTimer = Timer.periodic(
        Duration(seconds: widget.slideDurationSeconds),
        (_) => nextSlide(),
      );
    }
  }

  void nextSlide() {
    if (!mounted || widget.progKeys.length <= 1 || !_pageController.hasClients) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  void previousSlide() {
    if (!mounted || widget.progKeys.length <= 1 || !_pageController.hasClients) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  void togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _autoSlideTimer?.cancel();
    } else {
      _startTimer();
    }
  }

  void goToSlide(int index) {
    if (!mounted || widget.progKeys.isEmpty || !_pageController.hasClients) return;
    if (widget.progKeys.length <= 1) return;
    final diff = index - actualIndex;
    _pageController.animateToPage(
      _currentPage + diff,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.progKeys.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Row: Title 'RESULTS' + controls + 'LIVE RESULTS PORTAL'
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'RESULTS',
                style: GoogleFonts.rye(
                  fontSize: widget.isCompact ? 22 : 32,
                  color: AppTheme.mustard,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            if (hasMultiple) ...[
              // Slide Count Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 8 : 12,
                  vertical: widget.isCompact ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.wood.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.line, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.view_carousel_rounded,
                      color: AppTheme.mustard,
                      size: widget.isCompact ? 14 : 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${actualIndex + 1} / ${widget.progKeys.length}',
                      style: GoogleFonts.workSans(
                        fontSize: widget.isCompact ? 11 : 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.cream,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Prev Button
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppTheme.cream,
                iconSize: widget.isCompact ? 20 : 24,
                tooltip: 'Previous result (Left arrow)',
                visualDensity: VisualDensity.compact,
                onPressed: previousSlide,
              ),
              // Pause / Play Button
              IconButton(
                icon: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                color: _isPaused ? AppTheme.mustard : AppTheme.cream,
                iconSize: widget.isCompact ? 20 : 24,
                tooltip: _isPaused
                    ? 'Resume auto-slides'
                    : 'Pause on this result (Space)',
                visualDensity: VisualDensity.compact,
                onPressed: togglePause,
              ),
              // Next Button
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppTheme.cream,
                iconSize: widget.isCompact ? 20 : 24,
                tooltip: 'Next result (Right arrow)',
                visualDensity: VisualDensity.compact,
                onPressed: nextSlide,
              ),
              const SizedBox(width: 6),
            ],
            // 'LIVE RESULTS PORTAL' Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCompact ? 12 : 18,
                vertical: widget.isCompact ? 6 : 9,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cream2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.line, width: 1.5),
              ),
              child: Text(
                'LIVE RESULTS PORTAL',
                style: GoogleFonts.workSans(
                  fontSize: widget.isCompact ? 11 : 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.isCompact ? 14 : 22),

        // Slide PageView Body
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: hasMultiple
                    ? widget.progKeys.length * _virtualMultiplier
                    : 1,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _startTimer();
                },
                itemBuilder: (context, index) {
                  final pIdx = index % widget.progKeys.length;
                  final pId = widget.progKeys[pIdx];
                  final prog = widget.progMap[pId];
                  final rList = List<Result>.from(widget.progGroups[pId] ?? []);
                  rList.sort(
                    (a, b) =>
                        (a.position ?? 99).compareTo(b.position ?? 99),
                  );

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hasMultiple
                          ? (widget.isCompact ? 4 : 8)
                          : 0,
                    ),
                    child: _buildProgramCard(
                      prog: prog,
                      rList: rList,
                      teamMap: widget.teamMap,
                      studMap: widget.studMap,
                      isCompact: widget.isCompact,
                      hasMultiple: hasMultiple,
                    ),
                  );
                },
              ),

              // Floating Left Chevron
              if (hasMultiple)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: previousSlide,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.wood.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.line,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: AppTheme.cream,
                            size: widget.isCompact ? 22 : 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Floating Right Chevron
              if (hasMultiple)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: nextSlide,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.wood.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.line,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.cream,
                            size: widget.isCompact ? 22 : 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Slide Indicator Dots
        if (hasMultiple) ...[
          const SizedBox(height: 12),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.progKeys.length, (i) {
                  final isActive = i == actualIndex;
                  return GestureDetector(
                    onTap: () => goToSlide(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? (widget.isCompact ? 20 : 28) : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.mustard
                            : AppTheme.cream.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgramCard({
    required Program? prog,
    required List<Result> rList,
    required Map<String, Team> teamMap,
    required Map<String, Student> studMap,
    required bool isCompact,
    required bool hasMultiple,
  }) {
    final res1 = rList.where((r) => r.position == 1).firstOrNull;
    final res2 = rList.where((r) => r.position == 2).firstOrNull;
    final res3 = rList.where((r) => r.position == 3).firstOrNull;

    final s1 = res1 != null ? studMap[res1.studentId] : null;
    final t1 = res1 != null ? teamMap[res1.teamId] : null;
    final s2 = res2 != null ? studMap[res2.studentId] : null;
    final t2 = res2 != null ? teamMap[res2.teamId] : null;
    final s3 = res3 != null ? studMap[res3.studentId] : null;
    final t3 = res3 != null ? teamMap[res3.teamId] : null;

    final codeDigits = prog?.programCode.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final resNum = codeDigits.isNotEmpty ? codeDigits : '';

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: hasMultiple ? (isCompact ? 16 : 40) : 0,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FestResultPoster(
              resultNumber: resNum,
              programName: prog?.programName ?? 'CHAMPIONSHIP RESULT',
              sectionLabel: prog?.section.label ?? 'GENERAL',
              winner1: s1 != null || res1 != null
                  ? FestResultWinner(
                      position: 1,
                      studentName: s1?.name ?? (res1 != null ? 'Winner' : ''),
                      chaseNumber: s1?.chaseNumber ?? '',
                      teamName: t1?.teamName ?? '',
                      grade: res1?.grade,
                    )
                  : null,
              winner2: s2 != null || res2 != null
                  ? FestResultWinner(
                      position: 2,
                      studentName: s2?.name ?? (res2 != null ? 'Winner' : ''),
                      chaseNumber: s2?.chaseNumber ?? '',
                      teamName: t2?.teamName ?? '',
                      grade: res2?.grade,
                    )
                  : null,
              winner3: s3 != null || res3 != null
                  ? FestResultWinner(
                      position: 3,
                      studentName: s3?.name ?? (res3 != null ? 'Winner' : ''),
                      chaseNumber: s3?.chaseNumber ?? '',
                      teamName: t3?.teamName ?? '',
                      grade: res3?.grade,
                    )
                  : null,
              revealedPositions: const {1, 2, 3},
              isRevealMode: false,
            ),
          ),
        ),
      ),
    );
  }
}
