import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_db_service.dart';
import '../core/error_handler.dart';
import 'assessment_form.dart';

class SidebarDrawer extends ConsumerWidget {
  const SidebarDrawer({super.key});

  void _showRatingDialog(BuildContext context, WidgetRef ref) {
    int selectedStars = 0;
    bool isSubmitted = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isSubmitted ? "Thank You!" : "Rate PulseEdge",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSubmitted) ...[
                const Text(
                  "How would you rate your experience?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(
                        starValue <= selectedStars ? Icons.star : Icons.star_border,
                        color: starValue <= selectedStars ? Colors.amber : Colors.cyanAccent,
                        size: 36,
                      ),
                      onPressed: () => setState(() => selectedStars = starValue),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: selectedStars == 0 ? null : () async {
                    setState(() => isSubmitted = true);
                    
                    // Sync to Supabase
                    final currentUser = ref.read(authStateProvider).value;
                    if (currentUser != null) {
                      try {
                        await SupabaseDBService.syncRating(
                          userId: currentUser.id,
                          stars: selectedStars,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Cloud Sync Failed: ${ErrorHandler.getMessage(e)}"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }

                    // Auto-close after a delay
                    Future.delayed(const Duration(seconds: 2), () {
                      if (context.mounted) Navigator.pop(ctx);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text("Submit", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
                const SizedBox(height: 16),
                const Text(
                  "rating saved! thanks!",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final risk = ref.watch(riskProvider);

    return Drawer(
      backgroundColor: const Color(0xFF0B0F1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User Profile Section
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? "Guest User",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Premium Member",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // 11 Parameters Edit Section
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.cyanAccent),
            title: const Text("Edit Health Profile", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Update your 11 parameters", style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentFormScreen()));
            },
          ),

          // Static Risk Section
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.redAccent),
            title: const Text("Static Risk", style: TextStyle(color: Colors.white)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${(risk * 100).toInt()}%",
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Mock Sensor Toggle
          Consumer(builder: (context, ref, _) {
            final isMock = ref.watch(mockSensorEnabledProvider);
            return SwitchListTile(
              secondary: const Icon(Icons.science, color: Colors.purpleAccent),
              title: const Text("Mock Sensor Mode", style: TextStyle(color: Colors.white)),
              value: isMock,
              activeColor: Colors.purpleAccent,
              onChanged: (val) {
                ref.read(mockSensorEnabledProvider.notifier).setMock(val);
              },
            );
          }),

          // Rating System
          ListTile(
            leading: const Icon(Icons.star_rate, color: Colors.amber),
            title: const Text("Rate App", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showRatingDialog(context, ref);
            },
          ),
          
          const Divider(color: Colors.white12, height: 30),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white54),
            title: const Text("Logout", style: TextStyle(color: Colors.white70)),
            onTap: () {
              ref.read(authStateProvider.notifier).signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
