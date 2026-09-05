import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SidebarNavItem {
  final IconData icon;
  final String label;
  final String? badgeText;
  final Color? badgeColor;

  const SidebarNavItem({
    required this.icon,
    required this.label,
    this.badgeText,
    this.badgeColor,
  });
}

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String headerTitle;
  final String headerSubtitle;
  final IconData headerIcon;
  final Color? headerColor;
  final List<SidebarNavItem> items;
  final Widget? footer;
  final Widget Function(bool isCollapsed)? sidebarSearchWidgetBuilder;
  final double width;
  final double collapsedWidth;
  final bool initialCollapsed;
  final ValueChanged<bool>? onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.headerTitle,
    required this.headerSubtitle,
    this.headerIcon = Icons.shield_outlined,
    this.headerColor,
    required this.items,
    this.footer,
    this.sidebarSearchWidgetBuilder,
    this.width = 260,
    this.collapsedWidth = 72,
    this.initialCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initialCollapsed;
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
    if (widget.onToggleCollapse != null) {
      widget.onToggleCollapse!(_isCollapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.headerColor ?? AppTheme.red;
    final currentWidth = _isCollapsed ? widget.collapsedWidth : widget.width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: currentWidth,
      decoration: const BoxDecoration(
        color: AppTheme.cream,
        border: Border(
          right: BorderSide(color: AppTheme.line, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                padding: _isCollapsed
                    ? const EdgeInsets.symmetric(vertical: 14, horizontal: 8)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      activeColor,
                      AppTheme.redDeep,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isCollapsed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.cream,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(height: 10),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.chevron_right, color: AppTheme.cream, size: 22),
                            tooltip: 'Expand Sidebar',
                            onPressed: _toggleCollapse,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.cream,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.menu_open, color: AppTheme.cream, size: 22),
                                tooltip: 'Collapse Sidebar',
                                onPressed: _toggleCollapse,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.headerTitle,
                            style: GoogleFonts.rye(
                              color: AppTheme.cream,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.headerSubtitle,
                            style: GoogleFonts.workSans(
                              color: AppTheme.cream.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
            ),
            if (widget.sidebarSearchWidgetBuilder != null)
              widget.sidebarSearchWidgetBuilder!(_isCollapsed),
            const SizedBox(height: 6),

            // Nav Items List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = widget.selectedIndex == index;

                  if (_isCollapsed) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Tooltip(
                        message: item.label,
                        preferBelow: false,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => widget.onDestinationSelected(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? activeColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: activeColor.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 22,
                                    color: isSelected ? AppTheme.cream : AppTheme.inkSoft,
                                  ),
                                  if (item.badgeText != null)
                                    Positioned(
                                      top: 6,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: item.badgeColor ?? AppTheme.mustard,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => widget.onDestinationSelected(index),
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: activeColor.withValues(alpha: 0.08),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: activeColor.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 21,
                                color: isSelected ? AppTheme.cream : AppTheme.inkSoft,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: GoogleFonts.workSans(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? AppTheme.cream : AppTheme.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.badgeText != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.mustard : (item.badgeColor ?? activeColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.badgeText!,
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.ink : AppTheme.cream,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer Toggle / Custom Footer
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.line, width: 1)),
              ),
              child: _isCollapsed
                  ? IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppTheme.inkSoft, size: 22),
                      tooltip: 'Expand Sidebar',
                      onPressed: _toggleCollapse,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: widget.footer ??
                              Text(
                                'Askesis \'26 Portal',
                                style: GoogleFonts.workSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.inkSoft,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.chevron_left, color: AppTheme.inkSoft, size: 20),
                          tooltip: 'Collapse Sidebar',
                          onPressed: _toggleCollapse,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
