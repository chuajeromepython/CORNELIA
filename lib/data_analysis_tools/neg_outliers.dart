import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class NegativeOutliersChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> analyses;

  const NegativeOutliersChart({
    super.key,
    required this.data,
    required this.analyses,
  });

  @override
  State<NegativeOutliersChart> createState() => _NegativeOutliersChartState();
}

class _NegativeOutliersChartState extends State<NegativeOutliersChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  int? _selectedCard;

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);
  static const _threshold = 0.90;
  static const _normalColor = Color(0xFF4FC3F7);
  static const _outlierColor = Color(0xFFE57373);

  List<Map<String, dynamic>> get _outliers =>
      widget.data
          .where(
            (c) =>
                (c['score'] as num).toDouble() >= _threshold &&
                (c['text'] as String).isNotEmpty,
          )
          .toList()
        ..sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

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
    final outliers = _outliers;

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
                          'Negative Outliers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Tooltip(
                          message:
                              'Comments with an unusually high negative sentiment confidence score, beyond the 0.90 threshold.',
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
                      'Confidence score per comment',
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
                    color: _outlierColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _outlierColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Flagged',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${outliers.length} comments',
                        style: const TextStyle(
                          color: _outlierColor,
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

            // ── Legend ───────────────────────────────────────────
            Row(
              children: [
                _legendDot(_normalColor, 'Normal'),
                const SizedBox(width: 16),
                _legendDot(_outlierColor, 'Outlier (≥ 0.90)'),
                const Spacer(),
                Container(
                  width: 28,
                  height: 1,
                  color: _outlierColor.withValues(alpha: 0.7),
                  margin: const EdgeInsets.only(right: 6),
                ),
                const Text(
                  'Threshold',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Distribution chart ───────────────────────────────
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                backgroundColor: _bg,
                plotAreaBorderColor: Colors.transparent,
                margin: EdgeInsets.zero,
                primaryXAxis: NumericAxis(
                  isVisible: false,
                  minimum: 0,
                  maximum: widget.data.length.toDouble(),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 1.0,
                  interval: 0.25,
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  majorGridLines: const MajorGridLines(
                    width: 0.8,
                    color: Color(0x1AFFFFFF),
                    dashArray: [4, 4],
                  ),
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  title: const AxisTitle(
                    text: 'Negative confidence',
                    textStyle: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'Score: point.y',
                  activationMode: ActivationMode.singleTap,
                  color: _surface,
                  borderColor: const Color(0xFF333355),
                  borderWidth: 1,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                annotations: [
                  CartesianChartAnnotation(
                    widget: SizedBox(
                      width: 10000,
                      child: Divider(
                        color: _outlierColor.withValues(alpha: 0.7),
                        thickness: 1.2,
                      ),
                    ),
                    coordinateUnit: CoordinateUnit.point,
                    x: widget.data.length / 2,
                    y: _threshold,
                  ),
                ],
                series: [
                  ColumnSeries<Map<String, dynamic>, num>(
                    dataSource: widget.data,
                    xValueMapper: (c, _) => (c['id'] as num).toInt(),
                    yValueMapper: (c, _) => (c['score'] as num).toDouble(),
                    pointColorMapper: (c, _) =>
                        (c['score'] as num).toDouble() >= _threshold
                        ? _outlierColor
                        : _normalColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                    animationDuration: 900,
                    width: 0.6,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: false,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Flagged comment cards ────────────────────────────
            Row(
              children: [
                const Text(
                  'Flagged Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _outlierColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _outlierColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${outliers.length}',
                    style: const TextStyle(
                      color: _outlierColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ...List.generate(outliers.length, (i) {
              final c = outliers[i];
              final isExpanded = _selectedCard == i;
              final score = (c['score'] as num).toDouble();
              final text = c['text'] as String;
              final id = (c['id'] as num).toInt();

              final analysis =
                  widget.analyses.firstWhere(
                        (a) => (a['id'] as num).toInt() == id,
                        orElse: () => {'analysis': 'No analysis available.'},
                      )['analysis']
                      as String? ??
                  'No analysis available.';

              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedCard = isExpanded ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isExpanded
                          ? _outlierColor.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                    boxShadow: isExpanded
                        ? [
                            BoxShadow(
                              color: _outlierColor.withValues(alpha: 0.1),
                              blurRadius: 16,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Score bar row
                      Row(
                        children: [
                          const Text(
                            'Score',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: score,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  _outlierColor,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            score.toStringAsFixed(2),
                            style: const TextStyle(
                              color: _outlierColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Comment text
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),

                      // Gemini explanation (expanded)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: isExpanded
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _outlierColor.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _outlierColor.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const FaIcon(
                                              FontAwesomeIcons
                                                  .wandMagicSparkles,
                                              color: _outlierColor,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Gemini Analysis',
                                              style: TextStyle(
                                                color: _outlierColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          analysis,
                                          textAlign: TextAlign.justify,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 6),

                      // Expand hint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isExpanded ? 'Collapse' : 'Tap for analysis',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white24,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
