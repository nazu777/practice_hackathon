import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/app_state.dart';
import '../core/constants.dart';
import '../logic/alert_manager.dart';
import '../services/local_db.dart';
import '../services/suggestion_engine.dart'; 
import '../services/auth_service.dart';

import '../components/live_chart.dart';
import 'assessment_form.dart';
import 'onboarding_screen.dart';
import '../components/app_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  Color _alertColor(String level) {
    switch (level) {
      case ALERT_STABLE:   return Colors.greenAccent;
      case ALERT_ELEVATED: return Colors.orangeAccent;
      case ALERT_CRITICAL: return Colors.redAccent;
      default:             return Colors.grey;
    }
  }

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

  String _riskLabel(double risk) {
    if (risk < 0.3) return "Low Risk";
    if (risk < 0.7) return "Moderate Risk";
    return "High Risk";
  }

  @override
  Widget build(BuildContext context) {
    // Watch dismissal state
    final isDismissed = ref.watch(isDismissedProvider);

    // Listen for new alarms
    ref.listen<String>(alertLevelProvider, (previous, current) {
      if (current == ALERT_CRITICAL && previous != ALERT_CRITICAL) {
        ref.read(isDismissedProvider.notifier).setDismissed(false);
      }
      AlertManager.processNewReading(current);
    });

    final alertLevel = ref.watch(alertLevelProvider);
    final activity   = ref.watch(activityProvider);
    final risk       = ref.watch(riskProvider);
    final intensity  = ref.watch(intensityProvider);           
    final stabIntensity = ref.watch(stabilizedIntensityProvider); 
    final strain     = ref.watch(strainProductProvider);

    final currentUser = FirebaseAuth.instance.currentUser;
    final String displayName = currentUser?.displayName ?? "User";

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello $displayName 👋", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            const Text("Your heart health at a glance.", style: TextStyle(fontSize: 16, color: Colors.white60)),
            const SizedBox(height: 24),

            _phase1Card(risk),
            const SizedBox(height: 16),

            _phase2Card(risk, stabIntensity, strain),
            const SizedBox(height: 16),

            // 🔥 FIX: 6 parameters are now correctly passed! 🔥
            _activityCard(activity, alertLevel, risk, strain, isDismissed, ref),
            const SizedBox(height: 16),

            _chartCard(),
            const SizedBox(height: 16),

            _extraStats(strain, intensity),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _phase1Card(double risk) {
    return _baseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Phase 1: Static Risk", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.favorite, color: _riskColor(risk), size: 28),
                  const SizedBox(width: 8),
                  Text("${(risk * 100).toInt()}%", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              Text(_riskLabel(risk), style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: risk,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(_riskColor(risk)),
                ),
                const Icon(Icons.monitor_heart, color: Colors.white54, size: 30),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _phase2Card(double risk, double intensity, double strain) {
    final adjustedPercent = (strain * 100).clamp(0, 100).toInt();
    final intensityPercent = (intensity * 100).clamp(0, 100).toInt();
    final riskPercent = (risk * 100).toInt();

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Phase 2: Adjusted Risk", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          const Text("Formula: Risk × Intensity = Strain", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _formulaBox(label: "Static", value: "$riskPercent%", color: _riskColor(risk)),
              const Text("×", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white54)),
              _formulaBox(label: "Intensity", value: "$intensityPercent%", color: const Color(0xFF00E5FF)),
              const Text("=", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white54)),
              _formulaBox(label: "Strain", value: "$adjustedPercent%", color: _riskColor(strain), highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityCard(String activity, String alertLevel, double risk, double strain, bool isDismissed, WidgetRef ref) {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Current Activity", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(_activityIcon(activity), color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(activity, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                ],
              ),
              if (alertLevel == ALERT_CRITICAL && !isDismissed)
                ElevatedButton(
                  onPressed: () {
                    AlertManager.dismissAlert();
                    ref.read(isDismissedProvider.notifier).setDismissed(true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
                )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _alertColor(alertLevel).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _alertColor(alertLevel).withOpacity(0.3))),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: _alertColor(alertLevel), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    generateSuggestion(risk, activity, strain),
                    style: TextStyle(color: _alertColor(alertLevel), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Live Intensity Feed", style: TextStyle(fontSize: 14, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          SizedBox(height: 180, child: LiveChart()),
        ],
      ),
    );
  }

  Widget _extraStats(double strain, double intensity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniCard("Strain Index", strain.toStringAsFixed(3), _riskColor(strain)),
        _miniCard("Live Accel", "${(intensity * 100).toInt()}%", const Color(0xFF00E5FF)),
        _miniCard("Status", strain < 0.25 ? "Safe" : strain < 0.45 ? "Warning" : "Danger",
            strain < 0.25 ? Colors.greenAccent : strain < 0.45 ? Colors.orangeAccent : Colors.redAccent),
      ],
    );
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: child,
    );
  }

  Widget _formulaBox({required String label, required String value, required Color color, bool highlight = false}) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: highlight ? Border.all(color: color.withOpacity(0.5), width: 1.5) : null,
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: highlight ? 22 : 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _miniCard(String title, String value, Color accentColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}