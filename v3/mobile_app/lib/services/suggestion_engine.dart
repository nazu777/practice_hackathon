// ================================================================
// PulseEdge — Suggestion Engine
// ================================================================

// 🔥 THIS IS THE 3-PARAMETER FUNCTION FLUTTER WAS LOOKING FOR 🔥
String generateSuggestion(double risk, String activity, double strain) {
  if (strain > 0.45) {
    if (activity == "RUNNING") {
      return "⚠️ High strain detected while running! Slow down immediately and rest.";
    }
    return "⚠️ Critical strain level. Please stop activity and rest now.";
  }

  if (strain > 0.25) {
    if (activity == "RUNNING") {
      return "Elevated strain while running. Consider slowing to a walk.";
    }
    if (activity == "WALKING") {
      return "Moderate strain while walking. Maintain pace but don't push harder.";
    }
    return "Elevated strain detected. Monitor your condition closely.";
  }

  if (risk >= 0.8) {
    return "Critical risk detected. Please rest and consult a doctor.";
  } else if (risk >= 0.6) {
    return "Elevated risk. Avoid overexertion and monitor your heart.";
  } else if (risk >= 0.4) {
    return "Moderate risk. Maintain a healthy pace, but do not push too hard.";
  } else if (activity == "SITTING") {
    return "You've been inactive. Try walking for 5 mins.";
  } else if (activity == "RUNNING") {
    return "Good activity! Maintain steady pace.";
  }
  return "You're doing well. Stay consistent.";
}