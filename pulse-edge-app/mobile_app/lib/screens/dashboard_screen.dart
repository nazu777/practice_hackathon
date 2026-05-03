import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../core/constants.dart';
import '../components/live_chart.dart';
import '../logic/alert_manager.dart';
import '../services/local_db.dart';
import 'assessment_form.dart';

// ================================================================
// Dashboard Screen
// Shows live activity, risk score, strain product, and alert banner.
// Member 2 owns this. Uses ref.watch() on providers from app_state.dart.
// ================================================================

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Color _alertColor(String level) {
    switch (level) {
      case ALERT_STABLE:   return const Color(0xFF2E7D32); // Dark green
      case ALERT_ELEVATED: return const Color(0xFFE65100); // Dark orange
      case ALERT_CRITICAL: return const Color(0xFFB71C1C); // Dark red
      default:             return Colors.grey;
    }
  }

  String _alertMessage(String level) {
    switch (level) {
      case ALERT_STABLE:
        return 'Your vitals are stable. Keep it up!';
      case ALERT_ELEVATED:
        return 'Elevated strain detected.\nConsider slowing to a walk or sitting down.';
      case ALERT_CRITICAL:
        return '⚠️ HIGH CARDIOVASCULAR STRAIN\nSIT DOWN IMMEDIATELY AND REST';
      default:
        return 'Monitoring...';
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

  String _riskLabel(double risk) {
    if (risk <= 0.3) return 'LOW';
    if (risk <= 0.6) return 'MEDIUM';
    return 'HIGH';
  }

  Color _riskColor(double risk) {
    if (risk <= 0.3) return Colors.green;
    if (risk <= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertLevel = ref.watch(alertLevelProvider);
    final activity   = ref.watch(activityProvider);
    final risk       = ref.watch(riskProvider);
    final intensity  = ref.watch(intensityProvider);
    final strain     = ref.watch(strainProductProvider);

    final alertColor = _alertColor(alertLevel);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor:  alertColor,
        foregroundColor:  Colors.white,
        title:            const Text('PulseEdge'),
        actions: [
          // Re-assess button
          IconButton(
            icon:    const Icon(Icons.refresh),
            tooltip: 'Re-do Assessment',
            onPressed: () async {
              await LocalDB.clearProfile();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const AssessmentFormScreen(),
                  ),
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

            // ── Alert Banner ────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width:   double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:        alertColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:      alertColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset:     const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    alertLevel,
                    style: const TextStyle(
                      color:       Colors.white,
                      fontSize:    28,
                      fontWeight:  FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _alertMessage(alertLevel),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  if (alertLevel == ALERT_CRITICAL) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => AlertManager.dismissAlert(),
                      icon:  const Icon(Icons.check_circle),
                      label: const Text('Dismiss Alarm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade800,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Activity + Risk Row ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title:    'Activity',
                    value:    activity,
                    icon:     _activityIcon(activity),
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    title:     'Static Risk',
                    value:     _riskLabel(risk),
                    subtitle:  risk.toStringAsFixed(2),
                    icon:      Icons.favorite,
                    iconColor: _riskColor(risk),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Intensity + Strain Row ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title:     'Intensity',
                    value:     intensity.toStringAsFixed(2),
                    icon:      Icons.speed,
                    iconColor: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    title:     'Strain (R×I)',
                    value:     strain.toStringAsFixed(2),
                    icon:      Icons.monitor_heart,
                    iconColor: alertColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Live Chart ──────────────────────────────────────────
            Container(
              padding:     const EdgeInsets.all(12),
              decoration:  BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Intensity (last 5 min)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  LiveChart(),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ── Reusable info card widget ────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String   title;
  final String   value;
  final String?  subtitle;
  final IconData icon;
  final Color    iconColor;

  const _InfoCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}