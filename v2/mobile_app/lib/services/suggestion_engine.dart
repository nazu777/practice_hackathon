// ================================================================
// PulseEdge — Suggestion Engine
// Uses ADJUSTED risk (risk × intensity) for smarter suggestions.
// Phase 2: Now considers the strain product for real-time advice.
// ================================================================

String generateSuggestion(double risk, String activity, double strain) {
  // Phase 2: Use the strain product (risk × intensity) for dynamic advice
  // when the user is actively moving. Fall back to static risk otherwise.

  // CRITICAL: Strain is dangerously high
  if (strain > 0.45) {
    if (activity == "RUNNING") {
      return "⚠️ High strain detected while running! Slow down immediately and rest.";
    }
    return "⚠️ Critical strain level. Please stop activity and rest now.";
  }

  // ELEVATED: Strain is moderately high
  if (strain > 0.25) {
    if (activity == "RUNNING") {
      return "Elevated strain while running. Consider slowing to a walk.";
    }
    if (activity == "WALKING") {
      return "Moderate strain while walking. Maintain pace but don't push harder.";
    }
    return "Elevated strain detected. Monitor your condition closely.";
  }

  // LOW STRAIN: Use static risk for baseline advice
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