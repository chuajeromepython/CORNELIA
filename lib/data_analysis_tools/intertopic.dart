import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ThemeCluster {
  final String name;
  final int comments;
  final List<String> keywords;
  final double x;
  final double y;

  const ThemeCluster({
    required this.name,
    required this.comments,
    required this.keywords,
    required this.x,
    required this.y,
  });
}

const List<Color> _palette = [
  Color(0xFF4FC3F7),
  Color(0xFF81C784),
  Color(0xFFFFB74D),
  Color(0xFFE57373),
  Color(0xFFBA68C8),
  Color(0xFF4DB6AC),
  Color(0xFFF06292),
  Color(0xFFFFD54F),
  Color(0xFF64B5F6),
  Color(0xFFA5D6A7),
  Color(0xFFFF8A65),
  Color(0xFF90A4AE),
  Color(0xFFCE93D8),
  Color(0xFF80CBC4),
  Color(0xFFEF9A9A),
];

class IntertopicDistanceMap extends StatefulWidget {
  final Map<String, dynamic> themesData;

  const IntertopicDistanceMap({super.key, required this.themesData});

  @override
  State<IntertopicDistanceMap> createState() => _IntertopicDistanceMapState();
}

class _IntertopicDistanceMapState extends State<IntertopicDistanceMap>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);
  static const _blue = Color(0xFF4FC3F7);
  late AnimationController _pulseController; // ← add
  late Animation<double> _pulseAnim;

  int? _selectedIndex;

  List<ThemeCluster> get _themes {
    return widget.themesData.entries.map((entry) {
      final data = entry.value as Map<String, dynamic>;
      return ThemeCluster(
        name: entry.key,
        comments: (data['comments'] as num?)?.toInt() ?? 0,
        keywords: List<String>.from(data['keywords'] ?? []),
        x: (data['x'] as num?)?.toDouble() ?? 0.5,
        y: (data['y'] as num?)?.toDouble() ?? 0.5,
      );
    }).toList();
  }

  List<Color> get _solidColors =>
      List.generate(_themes.length, (i) => _palette[i % _palette.length]);

  List<Color> get _dimColors => List.generate(
    _themes.length,
    (i) => _palette[i % _palette.length].withValues(alpha: 0.60),
  );

  List<Color> get _selectedColors => List.generate(
    _themes.length,
    (i) => _palette[i % _palette.length].withValues(alpha: 0.95),
  );

  int get _maxComments => _themes.isEmpty
      ? 1
      : _themes.map((t) => t.comments).reduce((a, b) => a > b ? a : b);

  ThemeCluster? get _selected =>
      _selectedIndex == null ? null : _themes[_selectedIndex!];

  double _bubbleRadius(int comments, double canvasSize) {
    const minR = 0.038;
    const maxR = 0.110;
    return canvasSize * (minR + (maxR - minR) * (comments / _maxComments));
  }

  int? _hitTest(Offset position, Size canvasSize) {
    final shortSide = min(canvasSize.width, canvasSize.height);
    final themes = _themes;
    for (int i = themes.length - 1; i >= 0; i--) {
      final t = themes[i];
      final center = Offset(t.x * canvasSize.width, t.y * canvasSize.height);
      final r = _bubbleRadius(t.comments, shortSide);
      if ((position - center).distance <= r) return i;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapUp(TapUpDetails details, Size canvasSize) {
    final hit = _hitTest(details.localPosition, canvasSize);
    setState(() => _selectedIndex = hit == _selectedIndex ? null : hit);
  }

  @override
  Widget build(BuildContext context) {
    final themes = _themes;
    final solidColors = _solidColors;
    final dimColors = _dimColors;
    final selectedColors = _selectedColors;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (matches KeywordGraphChart) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Intertopic Distance Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Tooltip(
                        message:
                            "Groups similar discussion themes into clusters. Larger circles mean more comments belong to that theme, and closer circles mean the themes are more related to each other.",
                        waitDuration: Duration.zero,
                        showDuration: const Duration(seconds: 5),
                        exitDuration: const Duration(seconds: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.circleInfo,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Semantic proximity between themes',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Bubbles',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${themes.length} theme${themes.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Legend pill (tap to toggle labels) ──
          Row(
            children: [
              _LegendPill(
                label: 'Tap to explore',
                color: _blue,
                active: _selectedIndex != null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Canvas (matches KeywordGraphChart border/surface) ──
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF333355), width: 1),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: GestureDetector(
                        onTapUp: (d) => _onTapUp(d, canvasSize),
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, _) {
                            return CustomPaint(
                              size: canvasSize,
                              painter: _BubbleMapPainter(
                                themes: themes,
                                selectedIndex: _selectedIndex,
                                solidColors: solidColors,
                                dimColors: dimColors,
                                selectedColors: selectedColors,
                                maxComments: _maxComments,
                                pulseValue: _pulseAnim.value,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Info panel ──
          AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            offset: _selected == null ? const Offset(0, 0.15) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              opacity: _selected == null ? 0.0 : 1.0,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _selected == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _InfoPanel(
                          theme: _selected!,
                          color: solidColors[_selectedIndex!],
                          onClose: () => setState(() => _selectedIndex = null),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOM PAINTER
// ─────────────────────────────────────────────
class _BubbleMapPainter extends CustomPainter {
  final double pulseValue;
  final List<ThemeCluster> themes;
  final int? selectedIndex;
  final List<Color> solidColors;
  final List<Color> dimColors;
  final List<Color> selectedColors;
  final int maxComments;

  final Paint _fillPaint = Paint();
  final Paint _borderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _gridPaint = Paint()
    ..color = const Color(0x0AFFFFFF)
    ..strokeWidth = 1;

  _BubbleMapPainter({
    required this.themes,
    required this.selectedIndex,
    required this.solidColors,
    required this.dimColors,
    required this.selectedColors,
    required this.maxComments,
    required this.pulseValue,
  });

  double _bubbleRadius(int comments, double canvasSize) {
    const minR = 0.038;
    const maxR = 0.110;
    return canvasSize * (minR + (maxR - minR) * (comments / maxComments));
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    final shortSide = min(size.width, size.height);

    for (int i = 0; i < themes.length; i++) {
      final theme = themes[i];
      final isSelected = selectedIndex == i;
      final hasSelection = selectedIndex != null;
      final center = Offset(theme.x * size.width, theme.y * size.height);
      final r = _bubbleRadius(theme.comments, shortSide);
      final displayR = isSelected ? r * pulseValue : r;

      // Glow for selected — matches KeywordGraphChart node glow
      if (isSelected) {
        canvas.drawCircle(
          center,
          displayR * 1.5,
          Paint()
            ..color = solidColors[i].withValues(alpha: 0.20)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, displayR * 0.8),
        );
      }

      // Fill — dim unselected like KeywordGraphChart fades non-connected nodes
      _fillPaint.color = hasSelection && !isSelected
          ? dimColors[i].withValues(alpha: 0.25)
          : isSelected
          ? selectedColors[i]
          : dimColors[i];
      canvas.drawCircle(center, displayR, _fillPaint);

      // Border
      _borderPaint
        ..color = hasSelection && !isSelected
            ? solidColors[i].withValues(alpha: 0.25)
            : isSelected
            ? Colors.white
            : solidColors[i]
        ..strokeWidth = isSelected ? 2.5 : 1.2;
      canvas.drawCircle(center, displayR, _borderPaint);

      // Label
      final fontSize = (displayR * 0.36).clamp(8.0, 14.0);
      final tp = TextPainter(
        text: TextSpan(
          text: theme.name,
          style: TextStyle(
            color: hasSelection && !isSelected
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: displayR * 1.8);
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    const divisions = 8;
    for (int i = 1; i < divisions; i++) {
      final x = size.width * i / divisions;
      final y = size.height * i / divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }

  @override
  bool shouldRepaint(_BubbleMapPainter old) =>
      old.selectedIndex != selectedIndex ||
      old.themes != themes ||
      old.pulseValue != pulseValue;
}

// ─────────────────────────────────────────────
// INFO PANEL
// ─────────────────────────────────────────────
class _InfoPanel extends StatelessWidget {
  final ThemeCluster theme;
  final Color color;
  final VoidCallback onClose;

  const _InfoPanel({
    required this.theme,
    required this.color,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                theme.name.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${theme.comments} comment${theme.comments != 1 ? 's' : ''}',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.white30, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: theme.keywords.map((kw) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  kw,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LEGEND PILL
// ─────────────────────────────────────────────
class _LegendPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;

  const _LegendPill({
    required this.label,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.15) : Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? color.withValues(alpha: 0.6) : Colors.white12,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color : Colors.white24,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? color : Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
