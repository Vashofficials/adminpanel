import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// HELPER WIDGETS
// -----------------------------------------------------------------------------

class SectionHeader extends StatelessWidget {
  final String text;
  final bool hidden;
  const SectionHeader(this.text, {super.key, required this.hidden});
  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 0.6,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class NavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool collapsed;
  final int? badge; // Optional numeric badge
  final bool isChild;
  final bool isActive;
  final Widget? trailing;
  final VoidCallback? onTap;

  const NavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.collapsed,
    this.badge,
    this.isChild = false,
    this.isActive = false,
    this.trailing,
    this.onTap,
  });

  @override
  State<NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    // Reference Colors
    const blue = Color(0xFFF59E0B);
    const blueBg = Color(0xFFF1F5FF);
    const orange = Color(0xFFF59E0B);
    const orangeBg = Color(0xFFFFF7ED);
    const text = Color(0xFF475569); // Slightly softer gray than black

    final isActive = widget.isActive;
    
    // Background Color Logic
    final bgColor = isActive
        ? orangeBg
        : _hover ? blueBg : Colors.transparent;
    
    // Foreground (Icon/Text) Color Logic
    final fgColor = isActive
        ? orange
        : _hover ? blue : text;

    final collapsed = widget.collapsed;

    final tile = Container(
      // Indentation for children items
      margin: EdgeInsets.only(left: widget.isChild && !collapsed ? 18 : 8, right: 8, bottom: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        // Leading Icon
        leading: Icon(widget.icon, size: 20, color: fgColor),
        // Title Text
        title: collapsed ? null : Text(
          widget.label,
          style: TextStyle(fontSize: 13, color: fgColor, fontWeight: FontWeight.w600),
        ),
        // Trailing (Badge + Arrows)
        trailing: collapsed ? null : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${widget.badge}',
                    style: const TextStyle(fontSize: 10, color: blue, fontWeight: FontWeight.w800)),
              ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 6),
              widget.trailing!,
            ],
          ],
        ),
        minLeadingWidth: 20,
        horizontalTitleGap: collapsed ? 0 : 12,
        contentPadding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
        onTap: widget.onTap,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: tile,
      ),
    );
  }
}