import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../core/constants.dart';

// ================================================================
// Live Intensity Chart
// Appends a new data point every time intensityProvider updates.
// Displays last 30 readings (= 5 minutes at 10-second intervals).
// Horizontal reference lines show activity boundaries.
// ================================================================

class LiveChart extends ConsumerStatefulWidget {
  const LiveChart({super.key});

  @override
  ConsumerState<LiveChart> createState() => _LiveChartState();
}

class _LiveChartState extends ConsumerState<LiveChart> {
  final List<FlSpot> _points = [];
  double _xTime = 0;

  static const int _maxPoints = 30; // 30 × 10s = 5 minutes

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen to intensity changes and append to chart
    ref.listen<double>(intensityProvider, (previous, next) {
      setState(() {
        _points.add(FlSpot(_xTime, next));
        _xTime += 10; // Each point = 10 seconds
        if (_points.length > _maxPoints) {
          _points.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Seed with current value if empty
    if (_points.isEmpty) {
      final current = ref.read(intensityProvider);
      _points.add(FlSpot(0, current));
    }

    // Compute x-axis range for sliding window
    final double xMin = _points.first.x;
    final double xMax = _points.last.x + 1;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1,
          minX: xMin,
          maxX: xMax,

          // Grid lines every 0.2 on Y axis
          gridData: FlGridData(
            show: true,
            horizontalInterval: 0.2,
            getDrawingHorizontalLine: (value) => FlLine(
              color:       Colors.grey.shade200,
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),

          // Axis titles
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                interval:     0.2,
                reservedSize: 30,
                getTitlesWidget: (val, meta) => Text(
                  val.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),

          borderData: FlBorderData(
            show:   true,
            border: Border.all(color: Colors.grey.shade300),
          ),

          // Horizontal reference lines for activity thresholds
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              // Sitting/Walking boundary
              HorizontalLine(
                y:           INTENSITY_SITTING_MAX,
                color:       Colors.blue.withOpacity(0.6),
                strokeWidth: 1.5,
                dashArray:   [5, 5],
                label: HorizontalLineLabel(
                  show:         true,
                  alignment:    Alignment.topRight,
                  padding:      const EdgeInsets.only(right: 4, bottom: 2),
                  labelResolver: (_) => 'Sit',
                  style: const TextStyle(fontSize: 9, color: Colors.blue),
                ),
              ),
              // Walking/Running boundary
              HorizontalLine(
                y:           INTENSITY_WALKING_MAX,
                color:       Colors.orange.withOpacity(0.6),
                strokeWidth: 1.5,
                dashArray:   [5, 5],
                label: HorizontalLineLabel(
                  show:          true,
                  alignment:     Alignment.topRight,
                  padding:       const EdgeInsets.only(right: 4, bottom: 2),
                  labelResolver: (_) => 'Walk',
                  style: const TextStyle(fontSize: 9, color: Colors.orange),
                ),
              ),
            ],
          ),

          // The main intensity line
          lineBarsData: [
            LineChartBarData(
              spots:     _points,
              isCurved:  true,
              color:     Colors.red,
              barWidth:  2,
              dotData:   FlDotData(show: false),
              belowBarData: BarAreaData(
                show:  true,
                color: Colors.red.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}