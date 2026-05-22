import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OpinionRadarChart extends StatefulWidget {
  const OpinionRadarChart({super.key});

  @override
  State<OpinionRadarChart> createState() => _OpinionRadarChartState();
}

class _OpinionRadarChartState extends State<OpinionRadarChart> {
  int? touchedIndex;

  final labels = const [
    "Supporters",
    "Critics",
    "Neutral",
    "Undecided",
    "Advocates",
    "Opponents",
  ];

  final List<double> values = [
    20,
    55,
    70,
    90,
    90,
    65,
  ].map((e) => e.toDouble()).toList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: const Color(0xFF7E57C2).withOpacity(0.35),
              borderColor: const Color(0xFF5E35B1),
              entryRadius: 4,
              borderWidth: 3,
              dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
            ),
          ],

          radarShape: RadarShape.polygon,

          tickCount: 5,

          ticksTextStyle: const TextStyle(color: Colors.white70, fontSize: 10),

          tickBorderData: const BorderSide(color: Colors.white24, width: 1),

          gridBorderData: const BorderSide(color: Colors.white24, width: 1),

          titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 11),

          getTitle: (index, angle) {
            return RadarChartTitle(text: labels[index]);
          },

          radarTouchData: RadarTouchData(
            enabled: true,
            touchCallback: (event, response) {
              setState(() {
                touchedIndex = response?.touchedSpot?.touchedDataSetIndex;
              });
            },
          ),
        ),
      ),
    );
  }
}
