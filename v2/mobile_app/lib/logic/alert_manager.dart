import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/constants.dart';

// ================================================================
// PulseEdge — Alert Manager (Phase 3 Logic)
//
// Phase 3 Rule:
//   When a new alert fires, wait 60 seconds before acting.
//   After 60 seconds, compare previous vs current prediction.
//   If they are the same → confirmed, trigger alert.
//   If different         → newer prediction wins, trigger that instead.
//
// Why? This prevents a high-risk user starting a jog from immediately
// getting a "sit down" alarm before their body has adjusted.
// ================================================================

class AlertManager {
  static String _previousAlertLevel = ALERT_STABLE;
  static String _pendingAlertLevel  = ALERT_STABLE;
  static Timer? _delayTimer;
  static bool   _isWaiting = false;
  static bool   _isCriticalAlarmPlaying = false;

  static final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Called every 10 seconds from background service ─────────────
  static void processNewReading(String newAlertLevel) {
    // Always track the most recent reading
    _pendingAlertLevel = newAlertLevel;

    // If no timer is running, start the 60-second window
    if (!_isWaiting) {
      _isWaiting = true;

      _delayTimer = Timer(
        const Duration(seconds: ALERT_DELAY_SECONDS),
        _onDelayComplete,
      );
    }
    // If timer IS running, we just update _pendingAlertLevel above.
    // The timer will use the latest value when it fires.
  }

  // ── Called after 60-second delay ─────────────────────────────────
  static void _onDelayComplete() {
    _isWaiting = false;

    // Compare what we had before vs what we have now
    final String confirmedLevel;

    if (_pendingAlertLevel == _previousAlertLevel) {
      // Same level confirmed for 60 seconds → high confidence, alert
      confirmedLevel = _pendingAlertLevel;
    } else {
      // Level changed during the 60-second window → newer reading wins
      confirmedLevel = _pendingAlertLevel;
    }

    _previousAlertLevel = confirmedLevel;
    _triggerAlert(confirmedLevel);
  }

  // ── Trigger the appropriate alert ────────────────────────────────
  static Future<void> _triggerAlert(String alertLevel) async {
    switch (alertLevel) {
      case ALERT_STABLE:
        // Vitals stable — cancel any ongoing alerts
        await _stopAllAlerts();
        break;

      case ALERT_ELEVATED:
        // Elevated strain — single strong vibration, no sound
        await _stopAllAlerts();
        final bool hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 800, amplitude: 200);
        }
        break;

      case ALERT_CRITICAL:
        // Critical strain — continuous vibration + looping alarm sound
        if (!_isCriticalAlarmPlaying) {
          _isCriticalAlarmPlaying = true;

          // Vibration: repeating pattern [vibrate 500ms, pause 200ms]
          final bool hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator == true) {
            Vibration.vibrate(
              pattern: [0, 500, 200, 500, 200, 500],
              repeat: 0, // Repeat indefinitely
              amplitude: 255,
            );
          }

          // Looping alarm sound
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
          await _audioPlayer.play(AssetSource('audio/critical_alarm.mp3'));
        }
        break;
    }
  }

  // ── User taps "Dismiss" button on dashboard ───────────────────────
  static Future<void> dismissAlert() async {
    await _stopAllAlerts();
    _isCriticalAlarmPlaying = false;
  }

  static Future<void> _stopAllAlerts() async {
    Vibration.cancel();
    await _audioPlayer.stop();
    _isCriticalAlarmPlaying = false;
  }

  static void dispose() {
    _delayTimer?.cancel();
    _audioPlayer.dispose();
  }
}