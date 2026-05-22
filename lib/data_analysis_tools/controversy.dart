import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ControversyIndexWidget extends StatefulWidget {
  final double positive;
  final double neutral;
  final double negative;

  const ControversyIndexWidget({
    super.key,
    required this.positive,
    required this.neutral,
    required this.negative,
  });

  @override
  State<ControversyIndexWidget> createState() => _ControversyIndexWidgetState();
}

class _ControversyIndexWidgetState extends State<ControversyIndexWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnim;

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);

  double get _score =>
      (100 - (widget.positive - widget.negative).abs()).clamp(0, 100);

  String get _verdict {
    if (_score >= 80) return 'Highly Controversial';
    if (_score >= 60) return 'Controversial';
    if (_score >= 40) return 'Somewhat Divided';
    return 'Mostly Consensus';
  }

  Color get _accentColor {
    if (_score >= 80) return const Color(0xFFE57373);
    if (_score >= 60) return const Color(0xFFFFB74D);
    if (_score >= 40) return const Color(0xFF4FC3F7);
    return const Color(0xFF81C784);
  }

  String get _summary {
    final gap = (widget.positive - widget.negative).abs().toStringAsFixed(1);
    switch (_verdict) {
      case 'Highly Controversial':
        return 'Positive and negative sentiment are only $gap% apart, reflecting a deeply polarized discussion with strongly opposing viewpoints.';
      case 'Controversial':
        return 'Positive and negative sentiment are $gap% apart, indicating a significantly divided audience with clear opposing camps.';
      case 'Somewhat Divided':
        return 'Positive and negative sentiment are $gap% apart, suggesting a moderately split audience with room for common ground.';
      default:
        return 'Positive and negative sentiment are $gap% apart, indicating broad agreement in tone across the comment section.';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fillAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fillAnim,
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Controversy Index',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Tooltip(
                          message:
                              'Measures how divided commenters are. A high score means opinions are split almost evenly between positive and negative.',
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
                    const SizedBox(height: 4),
                    const Text(
                      'How divided are the commenters?',
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
                        'Verdict',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _verdict,
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Score display ────────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: _fillAnim,
                builder: (context, _) {
                  final animatedScore = _score * _fillAnim.value;
                  return Text(
                    animatedScore.toStringAsFixed(0),
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  );
                },
              ),
            ),
            const Center(
              child: Text(
                'out of 100',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tug of war bar ───────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Consensus',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    Text(
                      'Divided',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _fillAnim,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            color: Colors.white10,
                          ),
                          FractionallySizedBox(
                            widthFactor: (_score / 100) * _fillAnim.value,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.5,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 2,
                                height: 14,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Sentiment breakdown pills ─────────────────────────
            Row(
              children: [
                _SentimentPill(
                  label: 'Positive',
                  value: widget.positive,
                  color: const Color(0xFF81C784),
                ),
                const SizedBox(width: 8),
                _SentimentPill(
                  label: 'Neutral',
                  value: widget.neutral,
                  color: const Color(0xFF4FC3F7),
                ),
                const SizedBox(width: 8),
                _SentimentPill(
                  label: 'Negative',
                  value: widget.negative,
                  color: const Color(0xFFE57373),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Explanation panel ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.10),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _summary,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
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

class _SentimentPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SentimentPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
