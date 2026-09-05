import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'app_sidebar.dart';

class AppResponsiveLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SidebarNavItem> items;
  final Widget body;
  final String headerTitle;
  final String headerSubtitle;
  final IconData headerIcon;
  final Color? headerColor;
  final List<Widget>? appBarActions;
  final double breakpoint;
  final Widget? brandHeader;
  final Widget Function(bool isCollapsed)? sidebarSearchWidgetBuilder;

  const AppResponsiveLayout({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    required this.body,
    required this.headerTitle,
    required this.headerSubtitle,
    this.headerIcon = Icons.shield_outlined,
    this.headerColor,
    this.appBarActions,
    this.breakpoint = 768,
    this.brandHeader,
    this.sidebarSearchWidgetBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < breakpoint;
    final headerWidget = brandHeader;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: AppBar(
          title: Row(
            children: [
              if (items.isNotEmpty && selectedIndex < items.length) ...[
                Icon(items[selectedIndex].icon, size: 22, color: headerColor ?? AppTheme.red),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  items.isNotEmpty && selectedIndex < items.length
                      ? items[selectedIndex].label
                      : headerTitle,
                  style: GoogleFonts.rye(fontSize: 16, color: AppTheme.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: appBarActions,
        ),
        body: Column(
          children: [
            ?headerWidget,
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          items: items,
          activeColor: headerColor ?? AppTheme.red,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: appBarActions != null || headerTitle.isNotEmpty
          ? AppBar(
              title: Row(
                children: [
                  Text(
                    headerTitle.toUpperCase(),
                    style: GoogleFonts.rye(fontSize: 18, color: AppTheme.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: appBarActions,
            )
          : null,
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            headerTitle: headerTitle,
            headerSubtitle: headerSubtitle,
            headerIcon: headerIcon,
            headerColor: headerColor,
            items: items,
            sidebarSearchWidgetBuilder: sidebarSearchWidgetBuilder,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SidebarNavItem> items;
  final Color activeColor;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.activeColor = AppTheme.red,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isScrollable = items.length > 5;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cream,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppTheme.line, width: 1),
        ),
      ),
      child: SafeArea(
        child: isScrollable
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildNavItem(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => onDestinationSelected(index),
                        compact: true,
                      ),
                    );
                  }),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = selectedIndex == index;
                    return Expanded(
                      child: _buildNavItem(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => onDestinationSelected(index),
                        compact: false,
                      ),
                    );
                  }),
                ),
              ),
      ),
    );
  }

  Widget _buildNavItem({
    required SidebarNavItem item,
    required bool isSelected,
    required VoidCallback onTap,
    required bool compact,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: activeColor.withValues(alpha: 0.3), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: isSelected ? activeColor : AppTheme.inkSoft,
                  ),
                  if (item.badgeText != null)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: item.badgeColor ?? AppTheme.mustard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badgeText!,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.workSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : AppTheme.inkSoft,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
