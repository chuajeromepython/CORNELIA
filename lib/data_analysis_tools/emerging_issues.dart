import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EmergingIssuesChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const EmergingIssuesChart({super.key, required this.data});

  @override
  State<EmergingIssuesChart> createState() => _EmergingIssuesChartState();
}

class _EmergingIssuesChartState extends State<EmergingIssuesChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  int? _selectedIndex;

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);

  static const List<Color> _colors = [
    Color(0xFF4FC3F7),
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
  ];

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
    final data = widget.data;

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
                          'Emerging Issues',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Tooltip(
                          message:
                              'Top recurring issues identified from comment clusters, ranked by mention frequency.',
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
                      'Ranked by mention frequency',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                if (data.isNotEmpty)
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
                          'Top Issue',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.first['label'] ?? '',
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

            // ── Legend pills ─────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(data.length, (i) {
                final d = data[i];
                final color = _colors[i % _colors.length];
                final isActive = _selectedIndex == null || _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(
                    () => _selectedIndex = _selectedIndex == i ? null : i,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withValues(alpha: 0.15)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? color.withValues(alpha: 0.6)
                            : Colors.white12,
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
                            color: isActive ? color : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          d['label'] ?? '',
                          style: TextStyle(
                            color: isActive ? color : Colors.white24,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // ── Chart ────────────────────────────────────────────
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                backgroundColor: _bg,
                plotAreaBorderColor: Colors.transparent,
                margin: EdgeInsets.zero,
                primaryXAxis: CategoryAxis(
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  isVisible: true,
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
                    text: 'Mentions',
                    textStyle: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : point.y mentions',
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
                series: [
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d['label'] as String? ?? '',
                    yValueMapper: (d, _) => (d['count'] as num?)?.toInt() ?? 0,
                    pointColorMapper: (d, i) {
                      final color = _colors[i % _colors.length];
                      return _selectedIndex == null
                          ? color
                          : i == _selectedIndex
                          ? color
                          : color.withValues(alpha: 0.25);
                    },
                    borderRadius: BorderRadius.circular(6),
                    animationDuration: 900,
                    onPointTap: (args) {
                      setState(() {
                        _selectedIndex = _selectedIndex == args.pointIndex
                            ? null
                            : args.pointIndex;
                      });
                    },
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      builder: (d, point, series, pointIndex, seriesIndex) {
                        final item = d as Map<String, dynamic>;
                        final color = _colors[pointIndex % _colors.length];
                        final pct =
                            (item['percentage'] as num?)?.toDouble() ?? 0.0;
                        return Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Info panel ───────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _selectedIndex == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Tap a bar to explore',
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final color = _colors[_selectedIndex! % _colors.length];
                        final d = data[_selectedIndex!];
                        final count = (d['count'] as num?)?.toInt() ?? 0;
                        final pct =
                            (d['percentage'] as num?)?.toDouble() ?? 0.0;
                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.12),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    d['label'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  _badge(color, '$count mentions'),
                                  const SizedBox(width: 6),
                                  _badge(color, '${pct.toStringAsFixed(1)}%'),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedIndex = null),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white30,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                d['summary'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
