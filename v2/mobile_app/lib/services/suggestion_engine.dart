String generateSuggestion(double risk, String activity) {
  if (risk > 0.7) {
    return "High stress detected. Sit down, breathe slowly.";
  } else if (activity == "SITTING") {
    return "You’ve been inactive. Try walking for 5 mins.";
  } else if (activity == "RUNNING") {
    return "Good activity! Maintain steady pace.";
  }
  return "You're doing well. Stay consistent.";
}