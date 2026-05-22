import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class TrendData {
  final DateTime time;
  final int count;
  final String keyword;

  const TrendData(this.time, this.count, this.keyword);
}

// ─── Rolling-window helper ────────────────────────────────────────────────────

Map<String, List<TrendData>> _buildRollingTrends(
  List<TrendData> raw, {
  int window = 5,
}) {
  final Map<String, Map<String, int>> byKeyword = {};

  for (final d in raw) {
    final dateStr = DateTime(
      d.time.year,
      d.time.month,
      d.time.day,
    ).toIso8601String().substring(0, 10);
    byKeyword.putIfAbsent(d.keyword, () => {});
    byKeyword[d.keyword]![dateStr] =
        (byKeyword[d.keyword]![dateStr] ?? 0) + d.count;
  }

  final Map<String, List<TrendData>> result = {};

  for (final entry in byKeyword.entries) {
    final keyword = entry.key;
    final sortedDates = entry.value.keys.toList()..sort();

    final aggregated = sortedDates.map((ds) {
      return TrendData(DateTime.parse(ds), entry.value[ds]!, keyword);
    }).toList();

    if (window <= 1 || aggregated.length < window) {
      result[keyword] = aggregated;
      continue;
    }

    final smoothed = <TrendData>[];
    for (int i = 0; i < aggregated.length; i++) {
      final slice = aggregated.sublist(i < window ? 0 : i - window + 1, i + 1);
      final sum = slice.fold(0, (s, p) => s + p.count);
      smoothed.add(TrendData(aggregated[i].time, sum, keyword));
    }
    result[keyword] = smoothed;
  }

  return result;
}

// ─── Palette ──────────────────────────────────────────────────────────────────

const _bg = Color(0xFF0F1117);
const _surface = Color(0xFF1E1E2E);

const _palette = [
  Color(0xFF4FC3F7),
  Color(0xFFE57373),
  Color(0xFFFFB74D),
  Color(0xFF81C784),
  Color(0xFFCE93D8),
  Color(0xFF4DB6AC),
];

// ─── Widget ───────────────────────────────────────────────────────────────────

class EmergingTrendsChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const EmergingTrendsChart({super.key, required this.data});

  @override
  State<EmergingTrendsChart> createState() => _EmergingTrendsChartState();
}

class _EmergingTrendsChartState extends State<EmergingTrendsChart> {
  late final Map<String, List<TrendData>> _byKeyword;
  late final List<String> _keywords;
  late final Map<String, bool> _visible;
  late final TrackballBehavior _trackball;
  late final ZoomPanBehavior _zoomPan;

  @override
  void initState() {
    super.initState();

    final List<TrendData> converted = widget.data
        .map(
          (e) => TrendData(
            DateTime.parse(e['time'] as String),
            e['count'] as int,
            e['keyword'] as String,
          ),
        )
        .toList();

    _byKeyword = _buildRollingTrends(converted, window: 5);
    _keywords = _byKeyword.keys.toList();
    _visible = {for (final k in _keywords) k: true};

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

  ({String keyword, TrendData point}) get _peak {
    TrendData? best;
    String bestKw = _keywords.first;
    for (final entry in _byKeyword.entries) {
      for (final d in entry.value) {
        if (best == null || d.count > best.count) {
          best = d;
          bestKw = entry.key;
        }
      }
    }
    return (keyword: bestKw, point: best!);
  }

  double get _yMax {
    double max = 10;
    for (final entry in _byKeyword.entries) {
      if (_visible[entry.key] != true) continue;
      for (final d in entry.value) {
        if (d.count > max) max = d.count.toDouble();
      }
    }
    return max + 4;
  }

  DateTime get _minDate => _byKeyword.values
      .expand((l) => l)
      .map((d) => d.time)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  DateTime get _maxDate => _byKeyword.values
      .expand((l) => l)
      .map((d) => d.time)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  Color _colorFor(int index) => _palette[index % _palette.length];

  @override
  Widget build(BuildContext context) {
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
                minimum: _minDate,
                maximum: _maxDate,
                intervalType: DateTimeIntervalType.days,
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
                labelRotation: -45,
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: _yMax,
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
                  text: 'Mentions in window',
                  textStyle: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
              trackballBehavior: _trackball,
              zoomPanBehavior: _zoomPan,
              annotations: [],
              series: [
                for (int i = 0; i < _keywords.length; i++)
                  _areaSeries(
                    keyword: _keywords[i],
                    color: _colorFor(i),
                    data: _byKeyword[_keywords[i]]!,
                    visible: _visible[_keywords[i]]!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final peak = _peak;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Emerging Trends',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                Tooltip(
                  message:
                      "Shows keywords that spiked in discussion frequency over time, revealing topics that are gaining momentum.",
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
              'Rolling 5-day mention window',
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
                '${peak.keyword} · ${DateFormat('MMM d').format(peak.point.time)}',
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < _keywords.length; i++)
          _LegendPill(
            label: _keywords[i],
            color: _colorFor(i),
            active: _visible[_keywords[i]]!,
            onTap: () => setState(
              () => _visible[_keywords[i]] = !_visible[_keywords[i]]!,
            ),
          ),
      ],
    );
  }

  SplineAreaSeries<TrendData, DateTime> _areaSeries({
    required String keyword,
    required Color color,
    required List<TrendData> data,
    required bool visible,
  }) {
    return SplineAreaSeries<TrendData, DateTime>(
      name: keyword,
      dataSource: data,
      xValueMapper: (d, _) => d.time,
      yValueMapper: (d, _) => visible ? d.count : null,
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

// ─── Legend pill ──────────────────────────────────────────────────────────────

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
