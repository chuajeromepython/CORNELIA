import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CountryData {
  final String country;
  final int users;

  CountryData(this.country, this.users);
}

class GenderSentiment {
  final String gender;
  final double positive;
  final double neutral;
  final double negative;

  GenderSentiment({
    required this.gender,
    required this.positive,
    required this.neutral,
    required this.negative,
  });
}

class ChoroplethMap extends StatefulWidget {
  final List<Map<String, dynamic>> choroplethData;
  const ChoroplethMap({super.key, required this.choroplethData});

  @override
  State<ChoroplethMap> createState() => _ChoroplethMapState();
}

class _ChoroplethMapState extends State<ChoroplethMap> {
  late MapZoomPanBehavior _zoomPanBehavior;
  int? _selectedIndex;

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);
  static const _positive = Color(0xFF4FC3F7);
  static const _neutral = Color(0xFFFFB74D);
  static const _negative = Color(0xFFE57373);

  // Replace the hardcoded lists with these getters
  List<CountryData> get data => widget.choroplethData
      .map((e) => CountryData(e['country'] as String, e['commentsNo'] as int))
      .toList();

  List<GenderSentiment> _genderDataForCountry(String country) {
    final entry = widget.choroplethData.firstWhere(
      (e) => e['country'] == country,
      orElse: () => {},
    );
    if (entry.isEmpty) return [];

    final male = entry['maleSentiment'] as Map<String, dynamic>;
    final female = entry['femaleSentiment'] as Map<String, dynamic>;

    return [
      GenderSentiment(
        gender: 'Male',
        positive: (male['positive'] as num).toDouble(),
        neutral: (male['neutral'] as num).toDouble(),
        negative: (male['negative'] as num).toDouble(),
      ),
      GenderSentiment(
        gender: 'Female',
        positive: (female['positive'] as num).toDouble(),
        neutral: (female['neutral'] as num).toDouble(),
        negative: (female['negative'] as num).toDouble(),
      ),
    ];
  }

  int get _totalUsers => data.fold(0, (sum, d) => sum + d.users);

  String get _topCountry =>
      data.reduce((a, b) => a.users >= b.users ? a : b).country;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = MapZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
    );
  }

  void _showCountryModal(CountryData selected) {
    final genderData = _genderDataForCountry(selected.country);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: _positive.withValues(alpha: 0.08),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // ── Header ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.country,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gender × Sentiment breakdown',
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
                            'Commentors',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${selected.users}',
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

                // ── Legend pills ─────────────────────────────
                Row(
                  children: [
                    _LegendPill(label: 'Positive', color: _positive),
                    const SizedBox(width: 8),
                    _LegendPill(label: 'Neutral', color: _neutral),
                    const SizedBox(width: 8),
                    _LegendPill(label: 'Negative', color: _negative),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Chart ────────────────────────────────────
                SizedBox(
                  height: 220,
                  child: SfCartesianChart(
                    backgroundColor: _surface,
                    plotAreaBorderColor: Colors.transparent,
                    margin: EdgeInsets.zero,
                    primaryXAxis: CategoryAxis(
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(width: 0),
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: 0,
                      maximum: 100,
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
                        text: 'Percentage (%)',
                        textStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      color: const Color(0xFF1E1E2E),
                      borderColor: const Color(0xFF333355),
                      borderWidth: 1,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    series: <CartesianSeries<GenderSentiment, String>>[
                      StackedColumnSeries<GenderSentiment, String>(
                        dataSource: genderData,
                        xValueMapper: (d, _) => d.gender,
                        yValueMapper: (d, _) => d.positive,
                        name: 'Positive',
                        color: _positive,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        animationDuration: 900,
                      ),
                      StackedColumnSeries<GenderSentiment, String>(
                        dataSource: genderData,
                        xValueMapper: (d, _) => d.gender,
                        yValueMapper: (d, _) => d.neutral,
                        name: 'Neutral',
                        color: _neutral,
                        animationDuration: 900,
                      ),
                      StackedColumnSeries<GenderSentiment, String>(
                        dataSource: genderData,
                        xValueMapper: (d, _) => d.gender,
                        yValueMapper: (d, _) => d.negative,
                        name: 'Negative',
                        color: _negative,
                        animationDuration: 900,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
          // ── Header ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Comments Origin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Tooltip(
                        message:
                            "Displays where in the world commenters are located, showing which regions are most engaged with this topic.",
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
                    'Tap a country to explore',
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
                      'Top Country',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _topCountry.length > 12
                          ? '${_topCountry.substring(0, 12)}…'
                          : _topCountry,
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

          const SizedBox(height: 12),

          // ── Color scale legend ────────────────────────────
          Row(
            children: [
              const Text(
                'Low',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E2A3A),
                        Color(0xFF1565C0),
                        Color(0xFF4FC3F7),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'High',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Map ───────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SfMaps(
                layers: [
                  MapShapeLayer(
                    zoomPanBehavior: _zoomPanBehavior,
                    source: MapShapeSource.asset(
                      'assets/maps/world_map.json',
                      shapeDataField: 'name',
                      dataCount: data.length,
                      primaryValueMapper: (int index) => data[index].country,
                      shapeColorValueMapper: (int index) => data[index].users,
                      shapeColorMappers: const [
                        MapColorMapper(
                          from: 0,
                          to: 50,
                          color: Color(0xFF1E2A3A),
                        ),
                        MapColorMapper(
                          from: 51,
                          to: 100,
                          color: Color(0xFF1565C0),
                        ),
                        MapColorMapper(
                          from: 101,
                          to: 200,
                          color: Color(0xFF1E88E5),
                        ),
                        MapColorMapper(
                          from: 201,
                          to: 500,
                          color: Color(0xFF4FC3F7),
                        ),
                      ],
                    ),
                    selectedIndex: _selectedIndex ?? -1,
                    onSelectionChanged: (int index) {
                      setState(() => _selectedIndex = index);
                      _showCountryModal(data[index]);
                    },
                    selectionSettings: const MapSelectionSettings(
                      color: Color(0xFFFFB74D),
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    ),
                    shapeTooltipBuilder: (context, index) {
                      final item = data[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF333355)),
                        ),
                        child: Text(
                          '${item.country}  ·  ${item.users} users',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                    tooltipSettings: const MapTooltipSettings(
                      color: Colors.transparent,
                    ),
                    strokeColor: Colors.white12,
                    strokeWidth: 0.5,
                    color: const Color(0xFF1A1F2E),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Footer summary ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryChip(
                label: 'Total',
                value: '$_totalUsers',
                color: _positive,
              ),
              _SummaryChip(
                label: 'Countries',
                value: '${data.length}',
                color: _neutral,
              ),
              _SummaryChip(
                label: 'Top',
                value: _topCountry.length > 10
                    ? '${_topCountry.substring(0, 10)}…'
                    : _topCountry,
                color: _negative,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _LegendPill extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
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
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
