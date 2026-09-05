import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
export 'app_sidebar.dart';
export 'app_responsive_layout.dart';


// --- 1. Askesis Crest Clipper & Brand Mark ---
class AskesisCrestClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.38);
    path.lineTo(size.width * 0.82, size.height);
    path.lineTo(size.width * 0.18, size.height);
    path.lineTo(0, size.height * 0.38);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.stars, size: size, color: AppTheme.red),
        );
      },
    );
  }
}

class AskesisBrandHeader extends StatelessWidget {
  final List<Widget>? actions;

  const AskesisBrandHeader({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const BrandMark(size: 32),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Askesis',
                    style: GoogleFonts.rye(
                      fontSize: 22,
                      letterSpacing: 0.5,
                      height: 1.0,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ART FEST · 2026',
                    style: GoogleFonts.workSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: AppTheme.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (actions != null) Row(children: actions!),
        ],
      ),
    );
  }
}

class ScheduleTabIcon extends StatelessWidget {
  final Color color;
  const ScheduleTabIcon({super.key, this.color = AppTheme.inkSoft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            width: double.infinity,
            color: AppTheme.red,
            child: const Center(
              child: Text(
                'JUL',
                style: TextStyle(fontSize: 3.5, color: Colors.white, fontWeight: FontWeight.bold, height: 1.0),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '17',
                style: TextStyle(fontSize: 7.5, color: color, fontWeight: FontWeight.bold, height: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. PatternStrip Widget ---
class PatternStrip extends StatelessWidget {
  final double height;

  const PatternStrip({super.key, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: PatternStripPainter(),
      ),
    );
  }
}

class PatternStripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blockWidth = size.width / 5;

    // 1. Red diagonal stripes
    _drawStripedBlock(
      canvas,
      Rect.fromLTWH(0, 0, blockWidth, size.height),
      baseColor: const Color(0xFFC0392B),
      stripeColor: const Color(0xFF8B0000),
    );

    // 2. Black/White diagonal stripes
    _drawStripedBlock(
      canvas,
      Rect.fromLTWH(blockWidth, 0, blockWidth, size.height),
      baseColor: const Color(0xFFFFFFFF),
      stripeColor: const Color(0xFF111111),
    );

    // 3. Solid Olive Green
    final paint3 = Paint()..color = const Color(0xFF6E7B3D);
    canvas.drawRect(Rect.fromLTWH(blockWidth * 2, 0, blockWidth, size.height), paint3);

    // 4. Yellow/Green diagonal stripes
    _drawStripedBlock(
      canvas,
      Rect.fromLTWH(blockWidth * 3, 0, blockWidth, size.height),
      baseColor: const Color(0xFFD7A233),
      stripeColor: const Color(0xFF2D4A27),
    );

    // 5. Solid Dark Green
    final paint5 = Paint()..color = const Color(0xFF2D4A27);
    canvas.drawRect(Rect.fromLTWH(blockWidth * 4, 0, blockWidth, size.height), paint5);
  }

  void _drawStripedBlock(Canvas canvas, Rect rect, {required Color baseColor, required Color stripeColor}) {
    canvas.save();
    canvas.clipRect(rect);
    final basePaint = Paint()..color = baseColor;
    canvas.drawRect(rect, basePaint);

    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    const step = 7.0;
    for (double x = rect.left - rect.height * 2; x < rect.right + rect.height * 2; x += step) {
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        stripePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 3. AppButton ---
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppTheme.red;

    Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cream),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(
                label,
                style: GoogleFonts.workSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    final style = ElevatedButton.styleFrom(
      backgroundColor: isOutlined ? Colors.transparent : btnColor,
      foregroundColor: isOutlined ? btnColor : AppTheme.cream,
      side: isOutlined ? BorderSide(color: btnColor, width: 1.5) : BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      elevation: isOutlined ? 0 : 2,
    );

    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: style,
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

// --- 4. AppTextField ---
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.ink),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: GoogleFonts.workSans(color: AppTheme.ink, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppTheme.inkSoft) : null,
            suffixIcon: suffixIcon,
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
      ],
    );
  }
}

// --- 5. AppDropdown ---
class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.ink),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.cream,
          style: GoogleFonts.workSans(color: AppTheme.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
          borderRadius: BorderRadius.circular(12),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      ],
    );
  }
}

// --- 6. AppCard ---
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppTheme.cream2,
          borderRadius: BorderRadius.circular(14),
          border: border ?? Border.all(color: AppTheme.line),
        ),
        child: child,
      ),
    );
  }
}

// --- 7. StatCard ---
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(fontSize: 11, color: AppTheme.inkSoft, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.rye(fontSize: 22, color: AppTheme.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 8. SectionSelector ---
class SectionSelector extends StatelessWidget {
  final FestSection selectedSection;
  final ValueChanged<FestSection> onSelected;

  const SectionSelector({
    super.key,
    required this.selectedSection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FestSection.values.map((sec) {
          final isSelected = sec == selectedSection;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onSelected(sec),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.red : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.red : AppTheme.ink,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  sec.label,
                  style: GoogleFonts.workSans(
                    color: isSelected ? AppTheme.cream : AppTheme.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- 9. SearchBarWidget ---
class SearchBarWidget extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.hint = 'Search by name, chase number, or code...',
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.workSans(color: AppTheme.ink, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppTheme.cream,
        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.inkSoft),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
        ),
      ),
    );
  }
}

// --- 10. VsScoreboardWidget ---
class VsScoreboardWidget extends StatelessWidget {
  final Map<String, dynamic>? leaderTeam;
  final Map<String, dynamic>? runnerTeam;

  const VsScoreboardWidget({
    super.key,
    this.leaderTeam,
    this.runnerTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTeamCol(
                rank: 1,
                teamName: leaderTeam?['name'] ?? 'No Team',
                leaderName: leaderTeam?['leader'] ?? 'Leader: —',
                points: leaderTeam?['pts'] ?? 0,
                isLeader: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTeamCol(
                rank: 2,
                teamName: runnerTeam?['name'] ?? 'No Team',
                leaderName: runnerTeam?['leader'] ?? 'Leader: —',
                points: runnerTeam?['pts'] ?? 0,
                isLeader: false,
              ),
            ),
          ],
        ),
        // Central VS crest badge
        SizedBox(
          width: 38,
          height: 38,
          child: ClipPath(
            clipper: AskesisCrestClipper(),
            child: Container(
              color: AppTheme.red,
              alignment: Alignment.center,
              child: Text(
                'VS',
                style: GoogleFonts.rye(
                  color: AppTheme.cream,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCol({
    required int rank,
    required String teamName,
    required String leaderName,
    required int points,
    required bool isLeader,
  }) {
    final bg = isLeader
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFBF3DE), AppTheme.cream2],
          )
        : null;

    final initials = teamName.length >= 2 ? teamName.substring(0, 2).toUpperCase() : 'T';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isLeader ? null : AppTheme.cream2,
        gradient: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLeader ? AppTheme.mustard : AppTheme.line,
          width: isLeader ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isLeader ? AppTheme.mustard : AppTheme.ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#$rank',
              style: GoogleFonts.workSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isLeader ? AppTheme.ink : AppTheme.cream,
              ),
            ),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: isLeader ? AppTheme.red : AppTheme.olive,
            child: Text(
              initials,
              style: GoogleFonts.rye(color: AppTheme.cream, fontSize: 17),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.workSans(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppTheme.ink),
          ),
          const SizedBox(height: 2),
          Text(
            leaderName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.workSans(fontSize: 10.5, color: AppTheme.inkSoft),
          ),
          const SizedBox(height: 10),
          Text(
            '$points',
            style: GoogleFonts.rye(
              fontSize: 30,
              color: isLeader ? AppTheme.red : AppTheme.ink,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'PTS',
            style: GoogleFonts.workSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppTheme.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 10.5 TeamScoreCard ---
class TeamScoreCard extends StatelessWidget {
  final int rank;
  final String teamName;
  final String teamCode;
  final String? leaderName;
  final int points;
  final bool isHighlight;

  const TeamScoreCard({
    super.key,
    required this.rank,
    required this.teamName,
    this.teamCode = '',
    this.leaderName,
    required this.points,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor = AppTheme.inkSoft;
    if (rank == 1) rankColor = AppTheme.mustard;
    if (rank == 2) rankColor = const Color(0xFF9C9484);
    if (rank == 3) rankColor = const Color(0xFFB4703A);

    final leaderText = (leaderName != null && leaderName!.isNotEmpty) ? 'Leader: $leaderName' : '';

    return AppCard(
      color: isHighlight ? const Color(0xFFFBF3DE) : AppTheme.cream2,
      border: isHighlight ? Border.all(color: AppTheme.mustard, width: 1.5) : Border.all(color: AppTheme.line),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColor : AppTheme.ink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: rank == 1 ? AppTheme.ink : AppTheme.cream,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: GoogleFonts.workSans(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppTheme.ink),
                ),
                if (leaderText.isNotEmpty)
                  Text(
                    leaderText,
                    style: GoogleFonts.workSans(fontSize: 11.5, color: AppTheme.inkSoft, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: GoogleFonts.rye(fontSize: 22, color: isHighlight ? AppTheme.red : AppTheme.ink),
              ),
              Text(
                'PTS',
                style: GoogleFonts.workSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.inkSoft, letterSpacing: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 11. ResultCard ---
class ResultCard extends StatelessWidget {
  final String programName;
  final String section;
  final String winnerName;
  final String winnerTeam;
  final String secondName;
  final String secondTeam;
  final String thirdName;
  final String thirdTeam;

  const ResultCard({
    super.key,
    required this.programName,
    required this.section,
    required this.winnerName,
    required this.winnerTeam,
    required this.secondName,
    required this.secondTeam,
    required this.thirdName,
    required this.thirdTeam,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  programName,
                  style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  border: Border.all(color: AppTheme.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  section,
                  style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.inkSoft),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppTheme.line),
          ),
          _buildRankRow(1, winnerName, winnerTeam),
          const SizedBox(height: 6),
          _buildRankRow(2, secondName, secondTeam),
          const SizedBox(height: 6),
          _buildRankRow(3, thirdName, thirdTeam),
        ],
      ),
    );
  }

  Widget _buildRankRow(int pos, String name, String team) {
    Color posBg;
    Color posFg;
    bool isEmpty = name.isEmpty || name == '—';

    final label = pos == 1 ? '1st' : (pos == 2 ? '2nd' : '3rd');

    if (pos == 1) {
      posBg = AppTheme.mustard;
      posFg = AppTheme.ink;
    } else if (pos == 2) {
      posBg = const Color(0xFF999486);
      posFg = AppTheme.ink;
    } else {
      posBg = const Color(0xFFF2ECE1);
      posFg = AppTheme.inkSoft;
    }

    return Row(
      children: [
        Container(
          width: 38,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: posBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: GoogleFonts.workSans(
              color: posFg,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            !isEmpty ? name : '—',
            style: GoogleFonts.workSans(
              fontWeight: isEmpty ? FontWeight.w600 : FontWeight.w700,
              fontSize: 13.5,
              color: isEmpty ? AppTheme.inkSoft : AppTheme.ink,
            ),
          ),
        ),
        Text(
          !isEmpty ? team : '—',
          style: GoogleFonts.workSans(
            color: AppTheme.inkSoft,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// --- 12. QRScannerWidget ---
class QRScannerWidget extends StatelessWidget {
  final ValueChanged<String> onScanned;

  const QRScannerWidget({super.key, required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                onScanned(barcode.rawValue!);
                break;
              }
            }
          },
        ),
      ),
    );
  }
}

// --- 13. StudentQrDisplayDialog ---
class StudentQrDisplayDialog extends StatelessWidget {
  final String studentName;
  final String chaseNumber;

  const StudentQrDisplayDialog({
    super.key,
    required this.studentName,
    required this.chaseNumber,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = (screenWidth * 0.45).clamp(140.0, 200.0);

    return AlertDialog(
      backgroundColor: AppTheme.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        studentName,
        textAlign: TextAlign.center,
        style: GoogleFonts.rye(fontWeight: FontWeight.bold, color: AppTheme.ink, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chase Number: $chaseNumber',
              style: GoogleFonts.workSans(color: AppTheme.red, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: qrSize,
                height: qrSize,
                child: QrImageView(
                  data: chaseNumber,
                  version: QrVersions.auto,
                  size: qrSize,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: GoogleFonts.workSans(color: AppTheme.red, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
