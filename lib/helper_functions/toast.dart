import 'package:flutter/material.dart';

// ── Design tokens (mirrors Login/Register) ───────────────────────────────────
//const _surface = Color(0xFF0F1117);
const _accent = Color(0xFF4FC3F7);

void showSlidingToast(
  BuildContext context,
  String message, {
  double maxWidth = 250,
}) {
  final overlay = Overlay.of(context);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _SlidingToast(
      message: message,
      maxWidth: maxWidth,
      onDismissed: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _SlidingToast extends StatefulWidget {
  final String message;
  final double maxWidth;
  final VoidCallback onDismissed;

  const _SlidingToast({
    required this.message,
    required this.maxWidth,
    required this.onDismissed,
  });

  @override
  State<_SlidingToast> createState() => _SlidingToastState();
}

class _SlidingToastState extends State<_SlidingToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accent.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
