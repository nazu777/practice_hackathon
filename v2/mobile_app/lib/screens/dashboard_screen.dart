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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

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
  Widget build(BuildContext context) {
    // ================================================================
    // CRITICAL FIX: Wire AlertManager to the reactive alert level.
    // This fires vibration/alarm when strain crosses thresholds.
    // ================================================================
    ref.listen<String>(alertLevelProvider, (previous, current) {
      AlertManager.processNewReading(current);
    });

    // Watches from Main Branch Providers
    final alertLevel = ref.watch(alertLevelProvider);
    final activity   = ref.watch(activityProvider);
    final risk       = ref.watch(riskProvider);
    final intensity  = ref.watch(intensityProvider);           // Live 5x/sec (for chart)
    final stabIntensity = ref.watch(stabilizedIntensityProvider); // 10-sec avg (for formula)
    final strain     = ref.watch(strainProductProvider);

    final alertColor = _alertColor(alertLevel);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A), // Dark UI from Head
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
            _mainHeroCard(activity, alertLevel, risk, intensity, strain, alertColor),

            const SizedBox(height: 20),

            // ⚡ ADJUSTED RISK CARD — Phase 1 × Phase 2
            // Uses stabilized (10-sec avg) intensity — the ACTUAL value in the multiplication
            _adjustedRiskCard(risk, stabIntensity, strain),

            const SizedBox(height: 20),

            // 📊 CHART CARD
            _chartCard(),

            const SizedBox(height: 20),

            // ⚡ EXTRA STATS (Integrated Strain Calculation from Main)
            _extraStats(strain, intensity),
          ],
        ),
      ),
    );
  }

  Widget _mainHeroCard(String activity, String alert, double risk, double intensity, double strain, Color alertColor) {
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
                    const Text("Static Risk", style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const Text("(from assessment)", style: TextStyle(color: Colors.white38, fontSize: 10)),
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
                    generateSuggestion(risk, activity, strain),
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

  // ================================================================
  // ADJUSTED RISK CARD — Phase 1 Risk × Phase 2 Intensity
  // This is the core "Phase 2" feature: real-time risk adjustment
  // ================================================================
  Widget _adjustedRiskCard(double risk, double intensity, double strain) {
    final adjustedPercent = (strain * 100).clamp(0, 100).toInt();
    final intensityPercent = (intensity * 100).clamp(0, 100).toInt();
    final riskPercent = (risk * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            _riskColor(strain).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _riskColor(strain).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _riskColor(strain).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.speed, color: _riskColor(strain), size: 22),
              const SizedBox(width: 8),
              const Text(
                "Real-Time Adjusted Risk",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // The multiplication formula display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Phase 1: Static Risk
              _formulaBox(
                label: "Static Risk",
                sublabel: "Phase 1",
                value: "$riskPercent%",
                color: _riskColor(risk),
                icon: Icons.favorite,
              ),

              // Multiply sign
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    "×",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),

              // Phase 2: Activity Intensity
              _formulaBox(
                label: "Intensity",
                sublabel: "Phase 2",
                value: "$intensityPercent%",
                color: const Color(0xFF00E5FF),
                icon: Icons.sensors,
              ),

              // Equals sign
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    "=",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),

              // Result: Adjusted Risk
              _formulaBox(
                label: "Adjusted",
                sublabel: "Result",
                value: "$adjustedPercent%",
                color: _riskColor(strain),
                icon: Icons.shield,
                highlight: true,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Adjusted risk progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: strain.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(_riskColor(strain)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strain < 0.25
                ? "Low strain — safe to continue activity"
                : strain < 0.45
                    ? "Moderate strain — monitor closely"
                    : "High strain — consider reducing activity",
            style: TextStyle(
              color: _riskColor(strain).withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Each box in the formula display
  Widget _formulaBox({
    required String label,
    required String sublabel,
    required String value,
    required Color color,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: highlight
            ? color.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: color.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          Text(
            sublabel,
            style: TextStyle(fontSize: 9, color: color.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
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

  Widget _extraStats(double strain, double intensity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniCard("Strain Index", strain.toStringAsFixed(3), _riskColor(strain)),
        _miniCard("Intensity", "${(intensity * 100).toInt()}%", const Color(0xFF00E5FF)),
        _miniCard("Status", strain < 0.25 ? "Safe" : strain < 0.45 ? "Warning" : "Danger",
            strain < 0.25 ? Colors.greenAccent : strain < 0.45 ? Colors.orangeAccent : Colors.redAccent),
      ],
    );
  }

  Widget _miniCard(String title, String value, Color accentColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF121826),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}