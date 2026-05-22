import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class KeyInsightsCard extends StatefulWidget {
  final List<Map<String, dynamic>> insights;

  const KeyInsightsCard({super.key, required this.insights});

  @override
  State<KeyInsightsCard> createState() => _KeyInsightsCardState();
}

class _KeyInsightsCardState extends State<KeyInsightsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);

  static const _labelStyle = {
    'Dominant Sentiment': (
      icon: FontAwesomeIcons.faceAngry,
      color: Color(0xFFE57373),
    ),
    'Rising Concern': (
      icon: FontAwesomeIcons.arrowTrendUp,
      color: Color(0xFFFFB74D),
    ),
    'Geographic Signal': (
      icon: FontAwesomeIcons.earthAsia,
      color: Color(0xFF4FC3F7),
    ),
    'Alert': (
      icon: FontAwesomeIcons.triangleExclamation,
      color: Color(0xFFBA68C8),
    ),
    'Insufficient Data': (
      icon: FontAwesomeIcons.circleExclamation,
      color: Color(0xFF90A4AE),
    ),
  };

  static const _defaultStyle = (
    icon: FontAwesomeIcons.wandMagicSparkles,
    color: Color(0xFF90A4AE),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
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
      opacity: _fadeAnim,
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
                          'Key Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Tooltip(
                          message:
                              'AI-generated summary of the most significant patterns detected across all analyses.',
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
                      'Generated from all analyses',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                // Gemini badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: const [
                      FaIcon(
                        FontAwesomeIcons.wandMagicSparkles,
                        color: Colors.white38,
                        size: 11,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Gemini',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Insight cards ────────────────────────────────────
            ...widget.insights.map((insight) {
              final style = _labelStyle[insight['label']] ?? _defaultStyle;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: style.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: style.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: FaIcon(style.icon, color: style.color, size: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight['label'] ?? '',
                            style: TextStyle(
                              color: style.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            insight['body'] ?? '',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
