String generateSuggestion(double risk, String activity) {
  if (risk >= 0.8) {
    return "Critical risk detected. Please rest and consult a doctor.";
  } else if (risk >= 0.6) {
    return "Elevated risk. Avoid overexertion and monitor your heart.";
  } else if (risk >= 0.4) {
    return "Moderate risk. Maintain a healthy pace, but do not push too hard.";
  } else if (activity == "SITTING") {
    return "You’ve been inactive. Try walking for 5 mins.";
  } else if (activity == "RUNNING") {
    return "Good activity! Maintain steady pace.";
  }
  return "You're doing well. Stay consistent.";
}