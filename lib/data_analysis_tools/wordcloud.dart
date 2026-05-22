import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class KeywordBubblePlot extends StatelessWidget {
  const KeywordBubblePlot({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder numeric data with sentiment
    final List<KeywordData> data = [
      KeywordData('Privacy', 1, 120, 'positive'),
      KeywordData('Data', 2.5, 80, 'neutral'),
      KeywordData('Security', 3.2, 60, 'negative'),
      KeywordData('AI', 4.0, 40, 'positive'),
      KeywordData('Policy', 5.5, 20, 'neutral'),
      KeywordData('Cloud', 6.0, 50, 'positive'),
      KeywordData('Consent', 7.3, 35, 'negative'),
    ];

    return SfCartesianChart(
      title: ChartTitle(text: 'Keyword Bubble Plot'),
      primaryXAxis: NumericAxis(
        isVisible: false, // hide X-axis labels/ticks
        minimum: 0,
        maximum: 8,
      ),
      primaryYAxis: NumericAxis(title: AxisTitle(text: 'Mentions'), minimum: 0),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder:
            (
              dynamic dataPoint,
              dynamic point,
              dynamic series,
              int pointIndex,
              int seriesIndex,
            ) {
              final KeywordData d = data[pointIndex];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${d.keyword}\nMentions: ${d.value}\nSentiment: ${d.sentiment}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
      ),
      series: <BubbleSeries<KeywordData, double>>[
        BubbleSeries<KeywordData, double>(
          dataSource: data,
          xValueMapper: (KeywordData d, _) => d.x,
          yValueMapper: (KeywordData d, _) => d.value,
          sizeValueMapper: (KeywordData d, _) => d.value,
          pointColorMapper: (KeywordData d, _) {
            switch (d.sentiment) {
              case 'positive':
                return Colors.green.withAlpha(200);
              case 'negative':
                return Colors.red.withAlpha(200);
              default:
                return Colors.grey.withAlpha(200);
            }
          },
        ),
      ],
    );
  }
}

class KeywordData {
  final String keyword;
  final double x;
  final double value;
  final String sentiment;

  KeywordData(this.keyword, this.x, this.value, this.sentiment);
}
