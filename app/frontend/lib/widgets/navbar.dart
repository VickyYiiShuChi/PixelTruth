import 'package:flutter/material.dart';
import '../constants/colors.dart';

class Navbar extends StatelessWidget {
  final int selectedIndex;
  final List<String> navItems;
  final ValueChanged<int> onNavTap;

  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.navItems,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kAccent, width: 1.5),
                ),
                child: const Center(
                  child: Text('P', style: TextStyle(color: kAccent, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: 'Pixel', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.5)),
                    TextSpan(text: 'Truth', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.5)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Nav items
          Row(
            children: List.generate(navItems.length, (i) {
              return _NavItem(
                label: navItems[i],
                isSelected: i == selectedIndex,
                onTap: () => onNavTap(i),
              );
            }),
          ),
          const SizedBox(width: 24),
          // CTA
          _AnimatedCtaButton(),
        ],
      ),
    );
  }
}

// ── Animated Nav Item ──────────────────────────
class _NavItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: widget.isSelected
                ? BoxDecoration(
                    color: kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kAccent.withOpacity(0.4)),
                  )
                : BoxDecoration(
                    color: _hovering ? kAccent.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isSelected
                    ? kAccent
                    : _hovering
                        ? kTextPrimary
                        : kTextSecondary,
                fontSize: 14,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated CTA Button ────────────────────────
class _AnimatedCtaButton extends StatefulWidget {
  @override
  State<_AnimatedCtaButton> createState() => _AnimatedCtaButtonState();
}

class _AnimatedCtaButtonState extends State<_AnimatedCtaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
    );
  }
}