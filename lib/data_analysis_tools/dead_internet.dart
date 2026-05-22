import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DeadInternetTheoryCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const DeadInternetTheoryCard({super.key, required this.data});

  @override
  State<DeadInternetTheoryCard> createState() => _DeadInternetTheoryCardState();
}

class _DeadInternetTheoryCardState extends State<DeadInternetTheoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);
  static const _accentColor = Color(0xFF81C784);

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
    final repetitivePhrasing =
        widget.data['repetitive_phrasing_rate'] as String? ?? '0%';
    final coordinatedClusters =
        (widget.data['coordinated_clusters'] as num?)?.toInt() ?? 0;
    final avgOutlierScore =
        widget.data['avg_outlier_score'] as String? ?? '0.00';
    final narrative = widget.data['narrative'] as String? ?? '';

    final stats = [
      _StatCallout(
        value: repetitivePhrasing,
        label: 'Repetitive phrasing rate',
        description: 'Comments sharing near-identical sentence structures',
      ),
      _StatCallout(
        value: '$coordinatedClusters',
        label: 'Coordinated clusters',
        description:
            'Topic clusters with suspiciously uniform sentiment scores',
      ),
      _StatCallout(
        value: avgOutlierScore,
        label: 'Avg. outlier score',
        description: 'Mean negative confidence across flagged comments',
      ),
    ];

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
                          'Dead Internet Theory',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Tooltip(
                          message:
                              'Analyzes comments for signs of coordinated, bot-like, or inauthentic behavior.',
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
                      'Authenticity analysis',
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

            // ── Stat callouts ────────────────────────────────────
            Row(
              children: List.generate(stats.length, (i) {
                final s = stats[i];
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i < stats.length - 1 ? 8 : 0,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.value,
                          style: const TextStyle(
                            color: _accentColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.description,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 14),

            // ── Narrative ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Analysis',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    narrative,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.65,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Disclaimer ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleExclamation,
                  color: Colors.white24,
                  size: 11,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'This analysis is probabilistic and should not be treated as a definitive determination of bot activity. Results are based on linguistic patterns in the available comment data.',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCallout {
  final String value;
  final String label;
  final String description;

  const _StatCallout({
    required this.value,
    required this.label,
    required this.description,
  });
}
