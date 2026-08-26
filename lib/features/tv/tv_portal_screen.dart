import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
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
    final activeAnnouncement = announcements.isNotEmpty ? announcements.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate background for TV displays
      body: Stack(
        children: [
          // Background content switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: tvService.currentSlideIndex == 0
                ? _buildTvScoreboardScreen(context, teamsAsync)
                : _buildTvResultsScreen(context, publishedResultsAsync, programsAsync, teamsAsync, studentsAsync),
          ),

          // Top Header Bar
          Positioned(
            top: 24,
            left: 32,
            right: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.festival, color: AppTheme.accentGold, size: 36),
                    const SizedBox(width: 14),
                    Text(
                      'FEST 2026 LIVE DISPLAY',
                      style: GoogleFonts.blackOpsOne(fontSize: 28, color: Colors.white, letterSpacing: 2),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text('LIVE BROADCAST', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Animated Overlay Banner for Announcements
          if (activeAnnouncement != null) ...[
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: Card(
                color: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign, color: AppTheme.accentGold, size: 48),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeAnnouncement.title,
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeAnnouncement.message,
                              style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
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

  // --- SCREEN 1: TV SCOREBOARD ---
  Widget _buildTvScoreboardScreen(BuildContext context, AsyncValue<List<Team>> teamsAsync) {
    return Container(
      key: const ValueKey('tv_scoreboard'),
      padding: const EdgeInsets.fromLTRB(40, 100, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEAM CHAMPIONSHIP SCOREBOARD', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.accentGold)),
          const SizedBox(height: 24),
          Expanded(
            child: teamsAsync.when(
              data: (teams) {
                if (teams.isEmpty) return const Center(child: Text('No team scores calculated.', style: TextStyle(color: Colors.white)));
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 100,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (context, idx) {
                    final t = teams[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: idx == 0 ? AppTheme.accentGold : const Color(0xFF334155), width: idx == 0 ? 3 : 1),
                      ),
                      child: Row(
                        children: [
                          Text('#${idx + 1}', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: idx == 0 ? AppTheme.accentGold : Colors.white70)),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t.teamName, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                if (t.leaderName != null && t.leaderName!.isNotEmpty)
                                  Text('Leader: ${t.leaderName}', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text('${t.totalPoints}', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.accentGold)),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
            ),
          ),
        ],
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
  ) {
    return Container(
      key: const ValueKey('tv_results'),
      padding: const EdgeInsets.fromLTRB(40, 100, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LATEST PUBLISHED RESULTS', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.accentGold)),
          const SizedBox(height: 24),
          Expanded(
            child: resultsAsync.when(
              data: (results) {
                final published = results.where((r) => r.status == ResultStatus.published || r.status == ResultStatus.announced).toList();
                if (published.isEmpty) {
                  return const Center(child: Text('No published results available yet.', style: TextStyle(color: Colors.white, fontSize: 20)));
                }

                final progs = programsAsync.value ?? [];
                final teams = teamsAsync.value ?? [];
                final students = studentsAsync.value ?? [];

                final progMap = {for (var p in progs) p.id: p};
                final teamMap = {for (var t in teams) t.id: t.teamName};
                final studMap = {for (var s in students) s.id: s.name};

                return ListView.builder(
                  itemCount: published.length > 3 ? 3 : published.length,
                  itemBuilder: (context, idx) {
                    final res = published[idx];
                    final prog = progMap[res.programId];
                    final studName = studMap[res.studentId] ?? 'Student';
                    final teamName = teamMap[res.teamId] ?? 'Team';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prog?.programName ?? 'Program', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('$studName ($teamName)', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[400])),
                            ],
                          ),
                          Text('${res.position != null ? "${res.position}st Place" : "Grade ${res.grade}"} • ${res.points} PTS',
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }
}
