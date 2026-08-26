import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

// --- 1. AppButton ---
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
    final theme = Theme.of(context);
    final btnColor = color ?? theme.primaryColor;

    Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ],
          );

    final style = ElevatedButton.styleFrom(
      backgroundColor: isOutlined ? Colors.transparent : btnColor,
      foregroundColor: isOutlined ? btnColor : Colors.white,
      side: isOutlined ? BorderSide(color: btnColor, width: 1.5) : BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

// --- 2. AppTextField ---
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

// --- 3. AppDropdown ---
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// --- 4. AppCard ---
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: border ?? Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// --- 5. StatCard ---
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
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
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
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

// --- 6. SectionSelector ---
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
            child: FilterChip(
              selected: isSelected,
              label: Text(sec.label),
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => onSelected(sec),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- 7. SearchBarWidget ---
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
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// --- 8. TeamScoreCard ---
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
    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

    final leaderText = (leaderName != null && leaderName!.isNotEmpty) ? 'Leader: $leaderName' : '';

    return AppCard(
      color: isHighlight ? AppTheme.primaryColor.withOpacity(0.08) : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? rankColor : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (leaderText.isNotEmpty)
                  Text(
                    leaderText,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
              ),
              Text(
                'PTS',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 9. ResultCard ---
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                programName,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text(section, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                side: BorderSide.none,
              ),
            ],
          ),
          const Divider(height: 24),
          _buildRankRow(1, winnerName, winnerTeam, const Color(0xFFFFD700)),
          const SizedBox(height: 8),
          _buildRankRow(2, secondName, secondTeam, const Color(0xFFC0C0C0)),
          const SizedBox(height: 8),
          _buildRankRow(3, thirdName, thirdTeam, const Color(0xFFCD7F32)),
        ],
      ),
    );
  }

  Widget _buildRankRow(int pos, String name, String team, Color badgeColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${pos}st',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name.isNotEmpty ? name : '—',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          team.isNotEmpty ? team : '—',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

// --- 10. QRScannerWidget ---
class QRScannerWidget extends StatelessWidget {
  final ValueChanged<String> onScanned;

  const QRScannerWidget({super.key, required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
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

// --- 11. StudentQrDisplayDialog ---
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(studentName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Chase Number: $chaseNumber', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data: chaseNumber,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
