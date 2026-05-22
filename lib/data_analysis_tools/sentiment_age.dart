import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SentimentHeatMap extends StatefulWidget {
  final List<dynamic> data;
  const SentimentHeatMap({super.key, required this.data});

  @override
  State<SentimentHeatMap> createState() => _SentimentHeatMapState();
}

class _SentimentHeatMapState extends State<SentimentHeatMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  // Selected cell: (ageGroupIndex, aspectLabel)
  ({int groupIndex, String aspect})? _selected;

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);

  // Sentiment palette
  static const _positiveColor = Color(0xFF81C784);
  static const _neutralColor = Color(0xFF4FC3F7);
  static const _negativeColor = Color(0xFFE57373);
  static const _emptyColor = Color(0xFF2A2A3A);

  // All unique aspects across all age groups
  List<String> get _allAspects {
    final seen = <String>{};
    final result = <String>[];
    for (final group in widget.data) {
      for (final a in (group['aspects'] as List<dynamic>)) {
        final label = a['aspect'] as String;
        if (seen.add(label)) result.add(label);
      }
    }
    return result;
  }

  Color _sentimentColor(String sentiment, {double opacity = 1.0}) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return _positiveColor.withValues(alpha: opacity);
      case 'neutral':
        return _neutralColor.withValues(alpha: opacity);
      default:
        return _negativeColor.withValues(alpha: opacity);
    }
  }

  // Returns the positive% for a cell to drive color intensity
  Color _cellColor(Map<String, dynamic>? aspectData) {
    if (aspectData == null) return _emptyColor;
    final breakdown = aspectData['breakdown'] as Map<String, dynamic>;
    final pos = (breakdown['positive'] as num).toDouble();
    final neg = (breakdown['negative'] as num).toDouble();
    final neu = (breakdown['neutral'] as num).toDouble();

    // Dominant wins
    if (pos >= neg && pos >= neu) {
      return _positiveColor.withValues(alpha: 0.15 + (pos / 100) * 0.75);
    } else if (neg >= pos && neg >= neu) {
      return _negativeColor.withValues(alpha: 0.15 + (neg / 100) * 0.75);
    } else {
      return _neutralColor.withValues(alpha: 0.15 + (neu / 100) * 0.75);
    }
  }

  Color _cellBorderColor(Map<String, dynamic>? aspectData) {
    if (aspectData == null) return Colors.white10;
    final sentiment = aspectData['sentiment'] as String;
    return _sentimentColor(sentiment, opacity: 0.45);
  }

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
    final aspects = _allAspects;
    final groups = widget.data;

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
                        Text(
                          'Sentiment by Age & Aspect',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Tooltip(
                          message:
                              "Shows how different age groups feel about specific aspects mentioned in comments. Tap a cell to explore the breakdown.",
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
                      'How age groups feel about each topic',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                // Legend chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _LegendDot(color: _positiveColor, label: 'Positive'),
                    const SizedBox(height: 4),
                    _LegendDot(color: _neutralColor, label: 'Neutral'),
                    const SizedBox(height: 4),
                    _LegendDot(color: _negativeColor, label: 'Negative'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Heatmap Grid ─────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aspect column headers
                  Row(
                    children: [
                      // Spacer for age-group label column
                      const SizedBox(width: 72),
                      ...aspects.map((aspect) => _AspectHeader(label: aspect)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Rows: one per age group
                  ...List.generate(groups.length, (gi) {
                    final group = groups[gi];
                    final ageGroup = group['ageGroup'] as String;
                    final aspectList = group['aspects'] as List<dynamic>;

                    // Build a lookup map for quick access
                    final aspectMap = <String, Map<String, dynamic>>{
                      for (final a in aspectList)
                        (a['aspect'] as String): a as Map<String, dynamic>,
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Age group label
                          SizedBox(
                            width: 72,
                            child: Text(
                              ageGroup,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Cells
                          ...aspects.map((aspect) {
                            final cell = aspectMap[aspect];
                            final isSelected =
                                _selected?.groupIndex == gi &&
                                _selected?.aspect == aspect;
                            final hasData = cell != null;

                            return GestureDetector(
                              onTap: () {
                                if (!hasData) return;
                                setState(() {
                                  _selected = isSelected
                                      ? null
                                      : (groupIndex: gi, aspect: aspect);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 72,
                                height: 52,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: _cellColor(cell),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white60
                                        : _cellBorderColor(cell),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _sentimentColor(
                                              cell!['sentiment'] as String,
                                              opacity: 0.35,
                                            ),
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: hasData
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${(cell['breakdown']['positive'] as num).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              color: _sentimentColor(
                                                cell['sentiment'] as String,
                                              ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${cell['mentionCount']}x',
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Center(
                                        child: Text(
                                          '—',
                                          style: TextStyle(
                                            color: Colors.white12,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Info Panel ───────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _selected == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Tap a cell to explore',
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    )
                  : _buildInfoPanel(groups, aspects),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(List<dynamic> groups, List<String> aspects) {
    final gi = _selected!.groupIndex;
    final aspectLabel = _selected!.aspect;
    final group = groups[gi];
    final ageGroup = group['ageGroup'] as String;
    final aspectList = group['aspects'] as List<dynamic>;
    final cell =
        aspectList.firstWhere((a) => a['aspect'] == aspectLabel)
            as Map<String, dynamic>;

    final sentiment = cell['sentiment'] as String;
    final breakdown = cell['breakdown'] as Map<String, dynamic>;
    final mentions = cell['mentionCount'] as int;
    final accentColor = _sentimentColor(sentiment);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.12), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary sentence
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Users aged '),
                      TextSpan(
                        text: ageGroup,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' have '),
                      TextSpan(
                        text:
                            sentiment[0].toUpperCase() + sentiment.substring(1),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' sentiment toward '),
                      TextSpan(
                        text: '"$aspectLabel"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' ($mentions mention${mentions == 1 ? '' : 's'}).',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _selected = null),
                child: const Icon(Icons.close, color: Colors.white30, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Breakdown bars
          ...[
            ('Positive', breakdown['positive'] as double, _positiveColor),
            ('Neutral', breakdown['neutral'] as double, _neutralColor),
            ('Negative', breakdown['negative'] as double, _negativeColor),
          ].map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      entry.$1,
                      style: TextStyle(
                        color: entry.$3,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.$2 / 100,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(
                          entry.$3.withValues(alpha: 0.75),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.$2.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: entry.$3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _AspectHeader extends StatelessWidget {
  final String label;
  const _AspectHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
