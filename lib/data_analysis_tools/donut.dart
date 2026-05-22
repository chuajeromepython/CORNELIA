import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionDonutMini extends StatefulWidget {
  final Map<String, dynamic> data;
  const SyncfusionDonutMini({super.key, required this.data});

  @override
  State<SyncfusionDonutMini> createState() => _SyncfusionDonutMiniState();
}

class _SyncfusionDonutMiniState extends State<SyncfusionDonutMini> {
  int _selectedIndex = -1;

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);
  static const _positive = Color(0xFF4FC3F7);
  static const _neutral = Color(0xFFFFB74D);
  static const _negative = Color(0xFFE57373);

  List<_ChartData> get _chartData => [
    _ChartData(
      "Positive",
      (widget.data['positive'] ?? 0).toDouble(),
      _positive,
    ),
    _ChartData("Neutral", (widget.data['neutral'] ?? 0).toDouble(), _neutral),
    _ChartData(
      "Negative",
      (widget.data['negative'] ?? 0).toDouble(),
      _negative,
    ),
  ];

  late TooltipBehavior _tooltip;

  @override
  void initState() {
    super.initState();
    _tooltip = TooltipBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      format: 'point.x : point.y%',
      color: _surface,
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      borderColor: const Color(0xFF333355),
      borderWidth: 1,
    );
  }

  _ChartData? get _selected =>
      _selectedIndex == -1 ? null : _chartData[_selectedIndex];

  String get _dominantLabel =>
      _chartData.reduce((a, b) => a.value >= b.value ? a : b).label;

  @override
  Widget build(BuildContext context) {
    final data = _chartData;
    final selected = _selected;

    return Container(
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
                        'Sentiment Distribution',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Tooltip(
                        message:
                            "Shows the overall breakdown of comment sentiment. Tap a segment to see which comments fall into that category.",
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
                    'Detected from comments',
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
                      'Dominant',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dominantLabel,
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
          Row(
            children: data.map((d) {
              final i = data.indexOf(d);
              final isActive = _selectedIndex == -1 || _selectedIndex == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(
                    () => _selectedIndex = _selectedIndex == i ? -1 : i,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? d.color.withValues(alpha: 0.15)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? d.color.withValues(alpha: 0.6)
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
                            color: isActive ? d.color : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          d.label,
                          style: TextStyle(
                            color: isActive ? d.color : Colors.white24,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // ── Donut ────────────────────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              if (_selectedIndex != -1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data[_selectedIndex].color.withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              SfCircularChart(
                margin: EdgeInsets.zero,
                tooltipBehavior: _tooltip,
                series: <CircularSeries>[
                  DoughnutSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value,
                    pointColorMapper: (d, i) => _selectedIndex == -1
                        ? d.color
                        : i == _selectedIndex
                        ? d.color
                        : d.color.withValues(alpha: 0.15),
                    innerRadius: '68%',
                    radius: '82%',
                    animationDuration: 900,
                    explode: true,
                    explodeIndex: _selectedIndex,
                    explodeOffset: '7%',
                    onPointTap: (details) {
                      setState(() {
                        _selectedIndex = _selectedIndex == details.pointIndex!
                            ? -1
                            : details.pointIndex!;
                      });
                    },
                  ),
                ],
              ),

              // ── Center label ─────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Column(
                  key: ValueKey(_selectedIndex),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selected?.label ?? "All",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected == null ? Colors.white : selected.color,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected == null
                          ? "100%"
                          : "${selected.value.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: selected == null
                            ? Colors.white30
                            : selected.color.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Info panel ───────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: selected == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Tap a segment to explore",
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected.color.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected.color.withValues(alpha: 0.12),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: selected.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selected.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected.color.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                "${selected.value.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  color: selected.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _selectedIndex = -1),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white30,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '${selected.value.toStringAsFixed(1)}% of users have "',
                              ),
                              TextSpan(
                                text: selected.label,
                                style: TextStyle(
                                  color: selected.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(
                                text: '" sentiment toward this topic',
                              ),
                            ],
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

class _ChartData {
  final String label;
  final double value;
  final Color color;
  _ChartData(this.label, this.value, this.color);
}
