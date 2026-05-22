import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CommentVolumeAreaChart extends StatefulWidget {
  const CommentVolumeAreaChart({super.key});

  @override
  State<CommentVolumeAreaChart> createState() => _CommentVolumeAreaChartState();
}

class _CommentVolumeAreaChartState extends State<CommentVolumeAreaChart> {
  int? selectedIndex;

  final List<double> volume = [120, 180, 140, 10, 200, 260, 240];
  final List<String> labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  late TooltipBehavior tooltip;

  @override
  void initState() {
    super.initState();

    tooltip = TooltipBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      color: Color(0xFF1F1F1F),
      textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    );
  }

  List<_ChartData> get chartData =>
      List.generate(volume.length, (i) => _ChartData(labels[i], volume[i]));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        borderWidth: 0,
        tooltipBehavior: tooltip,
        primaryXAxis: CategoryAxis(
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(width: 0),
          labelPlacement: LabelPlacement.onTicks,

          majorGridLines: MajorGridLines(
            width: 1,
            color: Colors.white.withValues(alpha: 0.18),
          ),

          labelStyle: TextStyle(color: Colors.white70, fontSize: 10),
        ),
        primaryYAxis: NumericAxis(
          axisLine: AxisLine(width: 1, color: Colors.white54),

          majorTickLines: MajorTickLines(width: 1, color: Colors.white54),

          majorGridLines: MajorGridLines(
            width: 1,
            color: Colors.white.withValues(alpha: 0.18),
          ),

          labelStyle: TextStyle(color: Colors.white70, fontSize: 10),
        ),

        series: <CartesianSeries>[
          AreaSeries<_ChartData, String>(
            dataSource: chartData,

            xValueMapper: (data, _) => data.day,
            yValueMapper: (data, _) => data.value,

            animationDuration: 900,
            gradient: LinearGradient(
              colors: [
                Color(0xFFF4EFEA).withValues(alpha: 0.45),
                Color(0xFFF3E1E3).withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderGradient: const LinearGradient(
              colors: [Color(0xFFE6F3EC), Color(0xFFF4EFEA), Color(0xFFF3E1E3)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderWidth: 3,
            markerSettings: MarkerSettings(
              isVisible: true,
              width: 10,
              height: 10,
              shape: DataMarkerType.circle,
              color: Color.fromARGB(255, 23, 23, 30),
              borderWidth: 2,
              borderColor: Colors.white,
            ),

            onPointTap: (details) {
              setState(() => selectedIndex = details.pointIndex);
            },
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String day;
  final double value;

  _ChartData(this.day, this.value);
}
