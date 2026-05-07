import 'package:flutter/material.dart';
import 'assessment_form.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔵 TOP GLOW
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              height: 320,
              width: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF2563EB), // Blue glow
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // 🔷 BOTTOM GLOW
          Positioned(
            bottom: -140,
            left: -80,
            child: Container(
              height: 320,
              width: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF06B6D4), // Cyan glow
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // 🔥 MAIN CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🧠 MINIMAL HEADER
                const Text(
                  "Pulse Edge",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white60,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 60),

                // 🚀 HERO TEXT
                const Text(
                  "Build awareness\nof your body.",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 20),

                // 💬 SUBTEXT
                const Text(
                  "Track your activity.\nReduce risk.\nStay in control of your health.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),

                const Spacer(),

                // 🎯 HERO LOGO (BIG + GLOW)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.25),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/images/pulse_edge_logo.png",
                      height: 180,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // 🚀 CTA BUTTON
              Center(
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentFormScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF06B6D4),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Get Started",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18, color: Colors.white),
          ],
        ),
      ),
    ),
  ),
),

const SizedBox(height: 20),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
