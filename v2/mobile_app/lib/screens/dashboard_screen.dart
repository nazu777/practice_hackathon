import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../components/live_chart.dart';
import '../services/suggestion_engine.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);
    final alert = ref.watch(alertLevelProvider);
    final risk = ref.watch(riskProvider);
    final intensity = ref.watch(intensityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Pulse Edge",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 MAIN CARD
            _mainCard(activity, alert, risk, intensity),

            const SizedBox(height: 20),

            // 📊 CHART CARD
            _chartCard(),

            const SizedBox(height: 20),

            // ⚡ EXTRA STATS
            _extraStats(),
          ],
        ),
      ),
    );
  }

  // 🔥 MAIN CARD (Hero UI)
  Widget _mainCard(String activity, String alert, double risk, double intensity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activity,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _alertColor(alert),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alert,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 🎯 CIRCULAR RISK
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: risk,
                    strokeWidth: 14,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(_riskColor(risk)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(risk * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Risk Level",
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ⚡ STATS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Intensity", intensity.toStringAsFixed(2)),
              _statItem("Status", alert),
              _statItem("Mode", activity),
            ],
          ),

          const SizedBox(height: 25),

          // 🤖 AI SUGGESTION
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.cyanAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    generateSuggestion(risk, activity),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 CHART CARD
  Widget _chartCard() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Live Activity",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          SizedBox(height: 10),
          Expanded(child: LiveChart()),
        ],
      ),
    );
  }

  // ⚡ EXTRA STATS
  Widget _extraStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniCard("Steps", "1,240"),
        _miniCard("Active", "32m"),
        _miniCard("Calories", "86"),
      ],
    );
  }

  Widget _miniCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF121826),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _riskColor(double risk) {
    if (risk < 0.3) return Colors.greenAccent;
    if (risk < 0.7) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _alertColor(String alert) {
    switch (alert) {
      case "STABLE":
        return Colors.green;
      case "WARNING":
        return Colors.orange;
      case "DANGER":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}