import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Logic & Services from Main
import '../providers/app_state.dart';
import '../core/constants.dart';
import '../logic/alert_manager.dart';
import '../services/local_db.dart';
import '../services/suggestion_engine.dart'; // From HEAD

// Components
import '../components/live_chart.dart';
import 'assessment_form.dart';
import 'sidebar_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // UI Helper: Maps Main logic constants to Head colors
  Color _alertColor(String level) {
    switch (level) {
      case ALERT_STABLE:   return Colors.green;
      case ALERT_ELEVATED: return Colors.orange;
      case ALERT_CRITICAL: return Colors.red;
      default:             return Colors.grey;
    }
  }

  // UI Helper: Maps Main logic constants to Head icons
  IconData _activityIcon(String activity) {
    switch (activity) {
      case ACTIVITY_SITTING: return Icons.chair_outlined;
      case ACTIVITY_WALKING: return Icons.directions_walk;
      case ACTIVITY_RUNNING: return Icons.directions_run;
      default:               return Icons.device_unknown;
    }
  }

  Color _riskColor(double risk) {
    if (risk < 0.3) return Colors.greenAccent;
    if (risk < 0.7) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches from Main Branch Providers
    final alertLevel = ref.watch(alertLevelProvider);
    final activity   = ref.watch(activityProvider);
    final risk       = ref.watch(riskProvider);
    final intensity  = ref.watch(intensityProvider);
    final strain     = ref.watch(strainProductProvider);

    final alertColor = _alertColor(alertLevel);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A), // Dark UI from Head
      drawer: const SidebarDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Pulse Edge",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () async {
              await LocalDB.clearProfile();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AssessmentFormScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 MAIN HERO CARD (Head UI with Main Data)
            _mainHeroCard(activity, alertLevel, risk, intensity, alertColor),

            const SizedBox(height: 20),

            // 📊 CHART CARD
            _chartCard(),

            const SizedBox(height: 20),

            // ⚡ EXTRA STATS (Integrated Strain Calculation from Main)
            _extraStats(strain),
          ],
        ),
      ),
    );
  }

  Widget _mainHeroCard(String activity, String alert, double risk, double intensity, Color alertColor) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_activityIcon(activity), color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(activity, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.2),
                  border: Border.all(color: alertColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(alert, style: TextStyle(color: alertColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 30),

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
                    Text("${(risk * 100).toInt()}%",
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text("Risk Level", style: TextStyle(color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 🤖 AI SUGGESTION (Logic from Head)
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
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          if (alert == ALERT_CRITICAL) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => AlertManager.dismissAlert(),
                icon: const Icon(Icons.check_circle),
                label: const Text('Dismiss Critical Alarm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

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
          Text("Live Intensity", style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Expanded(child: LiveChart()),
        ],
      ),
    );
  }

  Widget _extraStats(double strain) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniCard("Strain Index", strain.toStringAsFixed(2)),
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
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}