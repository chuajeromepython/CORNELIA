import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TopicSentimentData {
  final String topic;
  final int positive;
  final int neutral;
  final int negative;

  const TopicSentimentData({
    required this.topic,
    required this.positive,
    required this.neutral,
    required this.negative,
  });
}

class TopicSentimentChart extends StatelessWidget {
  final List<TopicSentimentData> data;

  const TopicSentimentChart({
    super.key,
    this.data = const [
      TopicSentimentData(
        topic: 'Product quality',
        positive: 61,
        neutral: 12,
        negative: 27,
      ),
      TopicSentimentData(
        topic: 'Delivery & shipping',
        positive: 38,
        neutral: 8,
        negative: 54,
      ),
      TopicSentimentData(
        topic: 'Customer support',
        positive: 74,
        neutral: 10,
        negative: 16,
      ),
      TopicSentimentData(
        topic: 'Pricing & value',
        positive: 29,
        neutral: 21,
        negative: 50,
      ),
      TopicSentimentData(
        topic: 'App & interface',
        positive: 55,
        neutral: 18,
        negative: 27,
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      legend: Legend(
        isVisible: true,
        position: LegendPosition.top,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      primaryXAxis: CategoryAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(fontSize: 12),
      ),
      primaryYAxis: NumericAxis(isVisible: false, minimum: 0, maximum: 100),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: [
        StackedBar100Series<TopicSentimentData, String>(
          dataSource: data,
          xValueMapper: (d, _) => d.topic,
          yValueMapper: (d, _) => d.positive,
          name: 'Positive',
          color: const Color(0xFF1D9E75),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            bottomLeft: Radius.circular(6),
          ),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.middle,
            textStyle: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        StackedBar100Series<TopicSentimentData, String>(
          dataSource: data,
          xValueMapper: (d, _) => d.topic,
          yValueMapper: (d, _) => d.neutral,
          name: 'Neutral',
          color: const Color(0xFFB4B2A9),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.middle,
            textStyle: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        StackedBar100Series<TopicSentimentData, String>(
          dataSource: data,
          xValueMapper: (d, _) => d.topic,
          yValueMapper: (d, _) => d.negative,
          name: 'Negative',
          color: const Color(0xFFE24B4A),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.middle,
            textStyle: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
