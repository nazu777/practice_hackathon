// ================================================================
// PulseEdge — Shared Constants
// ALL members must use these. Never hardcode thresholds elsewhere.
// ================================================================

// --- Activity Labels (Member 2 uses for UI, Member 3 uses for classification) ---
const String ACTIVITY_SITTING = "SITTING";
const String ACTIVITY_WALKING = "WALKING";
const String ACTIVITY_RUNNING = "RUNNING";

// --- Alert Levels (Member 2 uses for UI colors, Member 4 uses for alerts) ---
const String ALERT_STABLE   = "STABLE";
const String ALERT_ELEVATED = "ELEVATED";
const String ALERT_CRITICAL = "CRITICAL";

// --- Intensity Thresholds (Member 3 uses these to classify activity) ---
// 0.00 to 0.10 = Sitting/Resting (Calibrated for real-world g-force)
// 0.11 to 0.50 = Walking/Light activity
// 0.51 to 1.00 = Running/Vigorous
const double INTENSITY_SITTING_MAX = 0.10;
const double INTENSITY_WALKING_MAX = 0.50;

// --- Final Strain Product Thresholds (Member 4 uses for alert logic) ---
// strain = risk × intensity
// 0.00 to 0.25 = Stable   → No alert
// 0.26 to 0.45 = Elevated → Single vibration
// > 0.45       = Critical → Continuous vibration + sound
const double STRAIN_STABLE_MAX   = 0.25;
const double STRAIN_ELEVATED_MAX = 0.45;

// --- Phase 3: Alert Delay ---
const int ALERT_DELAY_SECONDS = 60; // 1 minute stabilization window

// --- TFLite Model Path ---
const String MODEL_PATH = "assets/models/heart_risk.tflite";

// --- Sensor Math ---
// Maximum expected dynamic SVM for a sprinting person (in g-force units)
// Calibrated from 2.5 to 1.5 to provide better dynamic range for walking vs running.
const double MAX_EXPECTED_SVM = 1.5;

// How often we compute the average and push to providers
const int SENSOR_WINDOW_SECONDS = 10;
