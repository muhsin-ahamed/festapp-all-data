import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FestResultWinner {
  final int position;
  final String studentName;
  final String chaseNumber;
  final String teamName;
  final String? grade;

  const FestResultWinner({
    required this.position,
    required this.studentName,
    required this.chaseNumber,
    required this.teamName,
    this.grade,
  });
}

class FestResultPoster extends StatelessWidget {
  final String? resultNumber;
  final String programName;
  final String sectionLabel;
  final FestResultWinner? winner1;
  final FestResultWinner? winner2;
  final FestResultWinner? winner3;
  final Set<int> revealedPositions;
  final bool isRevealMode;

  const FestResultPoster({
    super.key,
    this.resultNumber,
    required this.programName,
    required this.sectionLabel,
    this.winner1,
    this.winner2,
    this.winner3,
    this.revealedPositions = const {1, 2, 3},
    this.isRevealMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final resNumStr = resultNumber ?? '';

    return Container(
      color: const Color(0xFFF8F6E7),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final scale = w / 1024.0;

              final isPos1Revealed = !isRevealMode || revealedPositions.contains(1);
              final isPos2Revealed = !isRevealMode || revealedPositions.contains(2);
              final isPos3Revealed = !isRevealMode || revealedPositions.contains(3);

              return Stack(
                children: [
                  // 1. Base template image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/announce_result_template.jpg',
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF8F6E7),
                        child: const Center(
                          child: Text(
                            'Announcement Template Missing',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Result Number (Next to red RESULT ribbon)
                  if (resNumStr.isNotEmpty)
                    Positioned(
                      left: 178 * scale,
                      top: 154 * scale,
                      width: 140 * scale,
                      height: 78 * scale,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          resNumStr,
                          style: GoogleFonts.workSans(
                            fontSize: 60 * scale,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF141414),
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),

                  // 3. Program Name (Below crosshatch divider)
                  Positioned(
                    left: 146 * scale,
                    top: 260 * scale,
                    width: 535 * scale,
                    height: 34 * scale,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        programName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rye(
                          fontSize: 21 * scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B1B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // 4. Section Pill (Olive capsule below program name)
                  Positioned(
                    left: 146 * scale,
                    top: 298 * scale,
                    height: 24 * scale,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14 * scale,
                        vertical: 3 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF748427),
                        borderRadius: BorderRadius.circular(12 * scale),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        sectionLabel.toUpperCase(),
                        style: GoogleFonts.workSans(
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // 5. Winner 1 (Next to green pin 1)
                  Positioned(
                    left: 184 * scale,
                    top: 338 * scale,
                    width: 510 * scale,
                    height: 36 * scale,
                    child: _buildWinnerRow(
                      scale: scale,
                      isRevealed: isPos1Revealed,
                      winner: winner1,
                      accentColor: const Color(0xFF5A8E33),
                    ),
                  ),

                  // 6. Winner 2 (Next to maroon pin 2)
                  Positioned(
                    left: 184 * scale,
                    top: 380 * scale,
                    width: 510 * scale,
                    height: 36 * scale,
                    child: _buildWinnerRow(
                      scale: scale,
                      isRevealed: isPos2Revealed,
                      winner: winner2,
                      accentColor: const Color(0xFF8B2B38),
                    ),
                  ),

                  // 7. Winner 3 (Next to red pin 3)
                  Positioned(
                    left: 184 * scale,
                    top: 427 * scale,
                    width: 510 * scale,
                    height: 36 * scale,
                    child: _buildWinnerRow(
                      scale: scale,
                      isRevealed: isPos3Revealed,
                      winner: winner3,
                      accentColor: const Color(0xFFDE1F33),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerRow({
    required double scale,
    required bool isRevealed,
    required FestResultWinner? winner,
    required Color accentColor,
  }) {
    if (winner == null || winner.studentName.isEmpty) {
      return const SizedBox.shrink();
    }

    final chaseNo = winner.chaseNumber.trim();
    final chaseFormatted = chaseNo.startsWith('#') ? chaseNo : '#$chaseNo';
    final teamName = winner.teamName.trim();

    return AnimatedOpacity(
      opacity: isRevealed ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              winner.studentName,
              style: GoogleFonts.workSans(
                fontSize: 17 * scale,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chaseNo.isNotEmpty) ...[
            SizedBox(width: 8 * scale),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 7 * scale,
                vertical: 2.5 * scale,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5 * scale),
                border: Border.all(color: accentColor, width: 1.2 * scale),
              ),
              child: Text(
                chaseFormatted,
                style: GoogleFonts.workSans(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ),
          ],
          if (teamName.isNotEmpty) ...[
            SizedBox(width: 8 * scale),
            Text(
              '• $teamName',
              style: GoogleFonts.workSans(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
