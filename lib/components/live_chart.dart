import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class LiveChart extends ConsumerStatefulWidget {
  const LiveChart({super.key});

  @override
  ConsumerState<LiveChart> createState() => _LiveChartState();
}

class _LiveChartState extends ConsumerState<LiveChart> {
  final List<FlSpot> spots = [];
  int time = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final value = ref.read(intensityProvider);

      if (spots.length >= 30) {
        spots.removeAt(0);
      }

      spots.add(FlSpot(time.toDouble(), value));
      time++;

      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel(); // 🔥 VERY IMPORTANT (prevents memory leak)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),

        titlesData: FlTitlesData(show: false),

        borderData: FlBorderData(show: false),

        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0.2,
              color: Colors.blueAccent,
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
            HorizontalLine(
              y: 0.6,
              color: Colors.orangeAccent,
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
          ],
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,

            isCurved: true,
            curveSmoothness: 0.35,

            barWidth: 3,
            isStrokeCapRound: true,

            gradient: const LinearGradient(
              colors: [
                Color(0xFF00E5FF),
                Color(0xFF7C4DFF),
              ],
            ),

            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.3),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),

            dotData: FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300), // smooth animation
      curve: Curves.easeOut,
    );
  }
}