import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SentimentPoint {
  final DateTime date;
  final int positive;
  final int negative;
  final int neutral;

  const SentimentPoint({
    required this.date,
    required this.positive,
    required this.negative,
    required this.neutral,
  });
}

List<SentimentPoint> _buildRollingData(
  List<(String, String)> raw, {
  int window = 10,
}) {
  // Step 1: Aggregate counts per date so each date appears exactly once
  final Map<String, Map<String, int>> dateMap = {};

  for (final e in raw) {
    final d = DateTime.parse(e.$1);
    final dateStr = DateTime(
      d.year,
      d.month,
      d.day,
    ).toIso8601String().substring(0, 10);
    final label = e.$2;

    dateMap[dateStr] ??= {'positive': 0, 'negative': 0, 'neutral': 0};
    dateMap[dateStr]![label] = (dateMap[dateStr]![label] ?? 0) + 1;
  }

  final sortedDates = dateMap.keys.toList()..sort();

  final List<SentimentPoint> aggregated = sortedDates.map((dateStr) {
    final counts = dateMap[dateStr]!;
    final d = DateTime.parse(dateStr);
    return SentimentPoint(
      date: DateTime(d.year, d.month, d.day),
      positive: counts['positive']!,
      negative: counts['negative']!,
      neutral: counts['neutral']!,
    );
  }).toList();

  // Step 2: Apply rolling window over the deduplicated date list
  if (window <= 1 || aggregated.length < window) return aggregated;

  final List<SentimentPoint> smoothed = [];
  for (int i = window - 1; i < aggregated.length; i++) {
    final slice = aggregated.sublist(i - window + 1, i + 1);
    smoothed.add(
      SentimentPoint(
        date: aggregated[i].date,
        positive: slice.fold(0, (s, p) => s + p.positive),
        negative: slice.fold(0, (s, p) => s + p.negative),
        neutral: slice.fold(0, (s, p) => s + p.neutral),
      ),
    );
  }

  return smoothed;
}

class SentimentOverTimeChart extends StatefulWidget {
  final List<(String, String)> data;

  const SentimentOverTimeChart({super.key, required this.data});

  @override
  State<SentimentOverTimeChart> createState() => _SentimentOverTimeChartState();
}

class _SentimentOverTimeChartState extends State<SentimentOverTimeChart> {
  late final List<SentimentPoint> _data;
  late final TrackballBehavior _trackball;
  late final ZoomPanBehavior _zoomPan;

  bool _showPositive = true;
  bool _showNegative = true;
  bool _showNeutral = true;

  static const _positive = Color(0xFF4FC3F7);
  static const _negative = Color(0xFFE57373);
  static const _neutral = Color(0xFFFFB74D);
  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);

  @override
  void initState() {
    super.initState();
    _data = _buildRollingData(widget.data, window: 10);

    _trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        color: _surface,
        borderColor: Color(0xFF333355),
        borderWidth: 1,
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
        canShowMarker: true,
      ),
      lineColor: Colors.white24,
      lineWidth: 1.2,
      lineDashArray: const [4, 4],
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.visible,
        height: 8,
        width: 8,
        borderWidth: 2,
        borderColor: Colors.white,
      ),
    );

    _zoomPan = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      zoomMode: ZoomMode.x,
    );
  }

  SentimentPoint get _peakPoint => _data.reduce(
    (a, b) =>
        (a.positive + a.negative + a.neutral) >=
            (b.positive + b.negative + b.neutral)
        ? a
        : b,
  );

  @override
  Widget build(BuildContext context) {
    // Avoid lag: constrain axis to min/max dates
    final minDate = _data.first.date;
    final maxDate = _data.last.date;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildLegendToggles(),
          const SizedBox(height: 12),
          Expanded(
            child: SfCartesianChart(
              backgroundColor: _bg,
              plotAreaBorderColor: Colors.transparent,
              primaryXAxis: DateTimeAxis(
                minimum: minDate,
                maximum: maxDate,
                intervalType: DateTimeIntervalType.days,
                interval: 1,
                dateFormat: DateFormat.MMMd(),
                majorGridLines: const MajorGridLines(width: 0),
                minorGridLines: const MinorGridLines(width: 0),
                axisLine: const AxisLine(color: Color(0xFF333355)),
                labelStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
                majorTickLines: const MajorTickLines(size: 0),
                edgeLabelPlacement: EdgeLabelPlacement.shift,
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: _data.isEmpty
                    ? 10
                    : _data
                              .map(
                                (e) => [
                                  e.positive,
                                  e.negative,
                                  e.neutral,
                                ].reduce((a, b) => a > b ? a : b),
                              )
                              .reduce((a, b) => a > b ? a : b)
                              .toDouble() +
                          4, // ← extra headroom for the annotation
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(
                  width: 0.8,
                  color: Color(0x1AFFFFFF),
                  dashArray: [4, 4],
                ),
                labelStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
                majorTickLines: const MajorTickLines(size: 0),
                title: const AxisTitle(
                  text: "Comments in window",
                  textStyle: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
              trackballBehavior: _trackball,
              zoomPanBehavior: _zoomPan,
              annotations: [],

              series: [
                _lineSeries(
                  name: "Positive",
                  color: _positive,
                  visible: _showPositive,
                  yValue: (p) => p.positive,
                ),
                _lineSeries(
                  name: "Negative",
                  color: _negative,
                  visible: _showNegative,
                  yValue: (p) => p.negative,
                ),
                _lineSeries(
                  name: "Neutral",
                  color: _neutral,
                  visible: _showNeutral,
                  yValue: (p) => p.neutral,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final peak = _peakPoint;
    final peakLabel =
        peak.positive >= peak.negative && peak.positive >= peak.neutral
        ? 'Positive'
        : peak.negative >= peak.neutral
        ? 'Negative'
        : 'Neutral';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sentiment Over Time',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                Tooltip(
                  message:
                      "Tracks how overall comment sentiment shifts across different dates. Useful for spotting when public opinion changed.",
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
              'Rolling 10-comment window',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Peak',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$peakLabel · ${DateFormat('MMM d').format(peak.date)}',
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
    );
  }

  Widget _buildLegendToggles() {
    return Row(
      children: [
        _LegendPill(
          label: "Positive",
          color: _positive,
          active: _showPositive,
          onTap: () => setState(() => _showPositive = !_showPositive),
        ),
        const SizedBox(width: 8),
        _LegendPill(
          label: "Negative",
          color: _negative,
          active: _showNegative,
          onTap: () => setState(() => _showNegative = !_showNegative),
        ),
        const SizedBox(width: 8),
        _LegendPill(
          label: "Neutral",
          color: _neutral,
          active: _showNeutral,
          onTap: () => setState(() => _showNeutral = !_showNeutral),
        ),
      ],
    );
  }

  SplineAreaSeries<SentimentPoint, DateTime> _lineSeries({
    required String name,
    required Color color,
    required bool visible,
    required int Function(SentimentPoint) yValue,
  }) {
    return SplineAreaSeries<SentimentPoint, DateTime>(
      name: name,
      dataSource: _data,
      xValueMapper: (p, _) => p.date,
      yValueMapper: (p, _) => visible ? yValue(p) : null,
      color: color.withValues(alpha: 0.12),
      borderColor: color,
      borderWidth: 2.5,
      splineType: SplineType.monotonic,
      markerSettings: MarkerSettings(
        isVisible: true,
        height: 5,
        width: 5,
        color: color,
        borderColor: color,
      ),
      animationDuration: 600,
      enableTooltip: true,
    );
  }
}

class _LegendPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _LegendPill({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
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
      ),
    );
  }
}
