import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'dashboard_screen.dart';

class AssessmentForm extends ConsumerStatefulWidget {
  const AssessmentForm({super.key});

  @override
  ConsumerState<AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends ConsumerState<AssessmentForm> {
  final List<TextEditingController> controllers =
      List.generate(11, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
      List.generate(11, (_) => FocusNode());

  bool isLoading = false;

  final List<String> labels = [
    "Heart Rate",
    "Blood Pressure",
    "Oxygen Level",
    "Stress Level",
    "Sleep Hours",
    "Steps Count",
    "Age",
    "BMI",
    "Activity Score",
    "Hydration Level",
    "Energy Level",
  ];

  void handleSubmit() async {
    FocusScope.of(context).unfocus();

    List<double> inputs =
        controllers.map((c) => double.tryParse(c.text) ?? 0.0).toList();

    setState(() => isLoading = true);

    double result = await runRiskInference(inputs);
    ref.read(riskProvider.notifier).state = result;

    setState(() => isLoading = false);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Health Assessment"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 🔵 TOP GLOW
          Positioned(
            top: -120,
            right: -80,
            child: _glow(const Color(0xFF2563EB)),
          ),

          // 🔷 BOTTOM GLOW
          Positioned(
            bottom: -140,
            left: -80,
            child: _glow(const Color(0xFF06B6D4)),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 🔥 FORM
                Expanded(
                  child: ListView.builder(
                    itemCount: labels.length,
                    itemBuilder: (context, index) {
                      final isFocused = focusNodes[index].hasFocus;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? Colors.cyanAccent
                                  : Colors.white12,
                              width: 1.2,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.cyanAccent.withOpacity(0.25),
                                      blurRadius: 20,
                                    )
                                  ]
                                : [],
                          ),
                          child: TextField(
                            controller: controllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: labels[index],
                              labelStyle: const TextStyle(
                                  color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            onTap: () => setState(() {}),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 🚀 PREMIUM BUTTON
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: isLoading ? null : handleSubmit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
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
                            )
                          ],
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Analyze Risk",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward,
                                      size: 18, color: Colors.white),
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

  Widget _glow(Color color) {
    return Container(
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          radius: 0.8,
        ),
      ),
    );
  }
}