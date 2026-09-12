import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_ui_components.dart';
import '../../data/models/team_model.dart';
import '../../data/models/result_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/student_model.dart';

class TvPortalScreen extends ConsumerWidget {
  const TvPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvService = ref.watch(tvServiceProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final publishedResultsAsync = ref.watch(publishedResultsProvider);
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

    if (mode == 'POSTER') {
      currentWidget = _buildTvPosterScreen(context);
      isPosterShowing = true;
    } else if (mode == 'SCOREBOARD') {
      currentWidget = _buildTvScoreboardScreen(context, teamsAsync, isCompact);
    } else if (mode == 'RESULTS') {
      currentWidget = _buildTvResultsScreen(
        context,
        publishedResultsAsync,
        programsAsync,
        teamsAsync,
        studentsAsync,
        isCompact,
      );
    } else {
      // AUTO mode
      switch (tvService.currentSlideIndex % 3) {
        case 0:
          currentWidget = _buildTvPosterScreen(context);
          isPosterShowing = true;
          break;
        case 1:
          currentWidget = _buildTvScoreboardScreen(context, teamsAsync, isCompact);
          break;
        case 2:
        default:
          currentWidget = _buildTvResultsScreen(
            context,
            publishedResultsAsync,
            programsAsync,
            teamsAsync,
            studentsAsync,
            isCompact,
          );
          break;
      }
    }

    return Scaffold(
      backgroundColor: isPosterShowing ? Colors.white : AppTheme.wood,
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
        ],
      ),
    );
  }

  // --- SCREEN 0: TV FEST POSTER ---
  Widget _buildTvPosterScreen(BuildContext context) {
    return Container(
      key: const ValueKey('tv_poster'),
      color: Colors.white,
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

  // --- SCREEN 1: TV SCOREBOARD ---
  Widget _buildTvScoreboardScreen(
    BuildContext context,
    AsyncValue<List<Team>> teamsAsync,
    bool isCompact,
  ) {
    return Container(
      key: const ValueKey('tv_scoreboard'),
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
                  'TEAM CHAMPIONSHIP SCOREBOARD',
                  style: GoogleFonts.rye(
                    fontSize: isCompact ? 20 : 32,
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
                  'LIVE LEADERBOARD',
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
          SizedBox(height: isCompact ? 12 : 20),
          Expanded(
            child: teamsAsync.when(
              data: (teams) {
                if (teams.isEmpty) {
                  return const Center(
                    child: Text(
                      'No team scores calculated.',
                      style: TextStyle(color: AppTheme.cream, fontSize: 20),
                    ),
                  );
                }

                final team1 = teams[0];
                final team2 = teams.length > 1 ? teams[1] : null;
                final remainingTeams = teams.length > 2
                    ? teams.sublist(2)
                    : <Team>[];

                return Column(
                  children: [
                    // Main 50/50 Split (Half First Team, Half Second Team)
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left 50% - First Team
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: _buildHalfScreenTeamCard(
                                    team: team1,
                                    rank: 1,
                                    isLeader: true,
                                    isCompact: isCompact,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Right 50% - Second Team (or placeholder if only 1 team)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: team2 != null
                                      ? _buildHalfScreenTeamCard(
                                          team: team2,
                                          rank: 2,
                                          isLeader: false,
                                          isCompact: isCompact,
                                        )
                                      : Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cream2.withValues(
                                              alpha: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Awaiting 2nd Team',
                                              style: TextStyle(
                                                color: AppTheme.inkSoft,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          // Central VS Crest Badge
                          if (team2 != null)
                            SizedBox(
                              width: isCompact ? 46 : 60,
                              height: isCompact ? 46 : 60,
                              child: ClipPath(
                                clipper: AskesisCrestClipper(),
                                child: Container(
                                  color: AppTheme.red,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'VS',
                                    style: GoogleFonts.rye(
                                      color: AppTheme.cream,
                                      fontSize: isCompact ? 15 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Bottom Strip for Remaining Teams (#3, #4, etc.)
                    if (remainingTeams.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: isCompact ? 54 : 66,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: remainingTeams.length,
                          itemBuilder: (context, idx) {
                            final t = remainingTeams[idx];
                            final rank = idx + 3;
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 14 : 20,
                                vertical: isCompact ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cream2,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppTheme.line,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.ink,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      '#$rank',
                                      style: GoogleFonts.workSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.cream,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    t.teamName,
                                    style: GoogleFonts.workSans(
                                      fontSize: isCompact ? 14 : 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    '${t.totalPoints} PTS',
                                    style: GoogleFonts.rye(
                                      fontSize: isCompact ? 15 : 18,
                                      color: AppTheme.red,
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppTheme.cream),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHalfScreenTeamCard({
    required Team team,
    required int rank,
    required bool isLeader,
    required bool isCompact,
  }) {
    final initials = team.teamName.length >= 2
        ? team.teamName.substring(0, 2).toUpperCase()
        : 'T';

    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 28),
      decoration: BoxDecoration(
        color: AppTheme.cream2,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isLeader ? AppTheme.mustard : AppTheme.line,
          width: isLeader ? 4 : 1.5,
        ),
        boxShadow: isLeader
            ? [
                BoxShadow(
                  color: AppTheme.mustard.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rank Badge Header
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 16 : 22,
                        vertical: isCompact ? 7 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: isLeader ? AppTheme.mustard : AppTheme.ink,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLeader) ...[
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: AppTheme.ink,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                          ],
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isLeader ? '#1 LEADER' : '#2 RUNNER-UP',
                              style: GoogleFonts.workSans(
                                fontSize: isCompact ? 15 : 20,
                                fontWeight: FontWeight.w900,
                                color: isLeader ? AppTheme.ink : AppTheme.cream,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isCompact ? 12 : 22),

                    // Team Crest / Avatar
                    CircleAvatar(
                      radius: isCompact ? 32 : 48,
                      backgroundColor: isLeader ? AppTheme.red : AppTheme.olive,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          initials,
                          style: GoogleFonts.rye(
                            color: AppTheme.cream,
                            fontSize: isCompact ? 24 : 38,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 12 : 20),

                    // Team Name
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        team.teamName,
                        style: GoogleFonts.workSans(
                          fontSize: isCompact ? 24 : 36,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (team.leaderName != null &&
                        team.leaderName!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Leader: ${team.leaderName}',
                          style: GoogleFonts.workSans(
                            fontSize: isCompact ? 14 : 18,
                            color: AppTheme.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                    const Spacer(),

                    // Total Points
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${team.totalPoints}',
                        style: GoogleFonts.rye(
                          fontSize: isCompact ? 52 : 84,
                          color: isLeader ? AppTheme.red : AppTheme.ink,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TOTAL POINTS',
                      style: GoogleFonts.workSans(
                        fontSize: isCompact ? 12 : 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkSoft,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
          Text(
            'LATEST PUBLISHED RESULTS',
            style: GoogleFonts.rye(
              fontSize: isCompact ? 22 : 32,
              color: AppTheme.mustard,
            ),
          ),
          SizedBox(height: isCompact ? 14 : 22),
          Expanded(
            child: resultsAsync.when(
              data: (results) {
                final published = results
                    .where(
                      (r) =>
                          r.status == ResultStatus.published ||
                          r.status == ResultStatus.announced,
                    )
                    .toList();
                if (published.isEmpty) {
                  return const Center(
                    child: Text(
                      'No published results available yet.',
                      style: TextStyle(color: AppTheme.cream, fontSize: 20),
                    ),
                  );
                }

                final progs = programsAsync.value ?? [];
                final teams = teamsAsync.value ?? [];
                final students = studentsAsync.value ?? [];

                final progMap = {for (var p in progs) p.id: p};
                final teamMap = {for (var t in teams) t.id: t.teamName};
                final studMap = {for (var s in students) s.id: s.name};

                return ListView.builder(
                  itemCount: published.length > 4 ? 4 : published.length,
                  itemBuilder: (context, idx) {
                    final res = published[idx];
                    final prog = progMap[res.programId];
                    final studName = studMap[res.studentId] ?? 'Student';
                    final teamName = teamMap[res.teamId] ?? 'Team';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(isCompact ? 16 : 24),
                      decoration: BoxDecoration(
                        color: AppTheme.cream2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.line, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prog?.programName ?? 'Program',
                                  style: GoogleFonts.workSans(
                                    fontSize: isCompact ? 18 : 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$studName ($teamName)',
                                  style: GoogleFonts.workSans(
                                    fontSize: isCompact ? 14 : 18,
                                    color: AppTheme.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${res.position != null ? "${res.position}st Place" : "Grade ${res.grade}"} • ${res.points} PTS',
                              style: GoogleFonts.rye(
                                fontSize: isCompact ? 16 : 22,
                                color: AppTheme.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppTheme.cream),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
