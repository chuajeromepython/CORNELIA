import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionBarThemePlot extends StatefulWidget {
  const SyncfusionBarThemePlot({super.key});

  @override
  State<SyncfusionBarThemePlot> createState() => _SyncfusionBarThemePlotState();
}

class _SyncfusionBarThemePlotState extends State<SyncfusionBarThemePlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> scaleAnim;
  late Animation<double> fadeAnim;

  final List<_BarData> data = [
    _BarData("Customer Service", 320),
    _BarData("Product Quality", 140),
    _BarData("Delivery Issues", 120),
    _BarData("Pricing", 90),
    _BarData("User Experience", 60),
  ];

  final LinearGradient barGradient = const LinearGradient(
    colors: [Color(0xFFE6F3EC), Color(0xFFF4EFEA), Color(0xFFF3E1E3)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  late TooltipBehavior tooltip;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    tooltip = TooltipBehavior(
      enable: true,
      format: 'point.x : point.y',
      activationMode: ActivationMode.singleTap,
      color: const Color(0xFF1F1F1F),
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: ScaleTransition(
        scale: scaleAnim,
        child: SizedBox(
          height: 300,
          width: 300,
          child: SfCartesianChart(
            margin: EdgeInsets.zero,
            plotAreaBorderWidth: 0,
            borderWidth: 0,
            tooltipBehavior: tooltip,
            primaryXAxis: CategoryAxis(
              axisLine: AxisLine(width: 0),
              majorTickLines: MajorTickLines(width: 0),
              majorGridLines: MajorGridLines(width: 0),
              labelStyle: TextStyle(color: Colors.transparent),
            ),
            primaryYAxis: NumericAxis(isVisible: false),
            series: <CartesianSeries>[
              ColumnSeries<_BarData, String>(
                dataSource: data,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.value,
                gradient: barGradient,
                borderRadius: BorderRadius.circular(4),
                animationDuration: 900,
                selectionBehavior: SelectionBehavior(
                  enable: true,
                  selectedOpacity: 1.0,
                  unselectedOpacity: 0.35,
                ),
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.bottom,
                  builder: (data, point, series, pointIndex, seriesIndex) {
                    final d = data as _BarData;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        d.value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),

              ScatterSeries<_BarData, String>(
                dataSource: data,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.value,
                markerSettings: MarkerSettings(
                  isVisible: true,
                  width: 10,
                  height: 10,
                  shape: DataMarkerType.circle,
                  color: Color.fromARGB(255, 23, 23, 30),
                  borderWidth: 2,
                  borderColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarData {
  final String label;
  final double value;

  _BarData(this.label, this.value);
}
