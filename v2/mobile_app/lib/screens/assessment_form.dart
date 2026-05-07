import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../services/ml_service.dart';
import '../services/local_db.dart';
import 'dashboard_screen.dart';

// ================================================================
// Assessment Form Screen
// Integrated: Premium UI (Branch) + ML Inference Logic (Main)
// ================================================================

class AssessmentFormScreen extends ConsumerStatefulWidget {
  const AssessmentFormScreen({super.key});

  @override
  ConsumerState<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends ConsumerState<AssessmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for numeric inputs (Main Branch Logic)
  final _ageCtrl = TextEditingController();
  final _restingBPCtrl = TextEditingController();
  final _cholesterolCtrl = TextEditingController();
  final _maxHRCtrl = TextEditingController();
  final _oldpeakCtrl = TextEditingController();

  // Dropdown selections (Main Branch Logic)
  double _sex = 1.0; 
  double _chestPainType = 2.0; 
  double _fastingBS = 0.0; 
  double _restingECG = 0.0; 
  double _exerciseAngina = 0.0; 
  double _stSlope = 1.0; 

  @override
  void dispose() {
    _ageCtrl.dispose();
    _restingBPCtrl.dispose();
    _cholesterolCtrl.dispose();
    _maxHRCtrl.dispose();
    _oldpeakCtrl.dispose();
    super.dispose();
  }

  // BACKEND LOGIC: Kept exactly from Main Branch
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final List<double> rawInputs = [
        double.parse(_ageCtrl.text),
        _sex,
        _chestPainType,
        double.parse(_restingBPCtrl.text),
        double.parse(_cholesterolCtrl.text),
        _fastingBS,
        _restingECG,
        double.parse(_maxHRCtrl.text),
        _exerciseAngina,
        double.parse(_oldpeakCtrl.text),
        _stSlope,
      ];

      final List<double> normalizedInputs = MLService.normalizeInputs(
        age: rawInputs[0], sex: rawInputs[1], chestPainType: rawInputs[2],
        restingBP: rawInputs[3], cholesterol: rawInputs[4], fastingBS: rawInputs[5],
        restingECG: rawInputs[6], maxHR: rawInputs[7], exerciseAngina: rawInputs[8],
        oldpeak: rawInputs[9], stSlope: rawInputs[10],
      );

      final double riskScore = await MLService.predictRisk(normalizedInputs);

      await LocalDB.saveUserProfile(rawInputs: rawInputs, riskScore: riskScore);
      ref.read(riskProvider.notifier).setRisk(riskScore);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // UI: Branch Style
      appBar: AppBar(
        title: const Text("Heart Risk Assessment"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _glow(const Color(0xFF2563EB))),
          Positioned(bottom: -140, left: -80, child: _glow(const Color(0xFF06B6D4))),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        _styledField("Age", _ageCtrl, "e.g. 45"),
                        _styledDropdown("Sex", _sex, [
                          const DropdownMenuItem(value: 1.0, child: Text('Male')),
                          const DropdownMenuItem(value: 0.0, child: Text('Female')),
                        ], (v) => setState(() => _sex = v!)),
                        _styledDropdown("Chest Pain", _chestPainType, [
                          const DropdownMenuItem(value: 0.0, child: Text('ATA')),
                          const DropdownMenuItem(value: 1.0, child: Text('NAP')),
                          const DropdownMenuItem(value: 2.0, child: Text('ASY')),
                          const DropdownMenuItem(value: 3.0, child: Text('TA')),
                        ], (v) => setState(() => _chestPainType = v!)),
                        _styledField("Resting BP", _restingBPCtrl, "mmHg"),
                        _styledField("Cholesterol", _cholesterolCtrl, "mg/dL"),
                        _styledDropdown("Fasting Blood Sugar > 120", _fastingBS, [
                          const DropdownMenuItem(value: 0.0, child: Text('No')),
                          const DropdownMenuItem(value: 1.0, child: Text('Yes')),
                        ], (v) => setState(() => _fastingBS = v!)),
                        
                        // ADDED: Resting ECG Field (Parameter 7)
                        _styledDropdown("Resting ECG", _restingECG, [
                          const DropdownMenuItem(value: 0.0, child: Text('Normal')),
                          const DropdownMenuItem(value: 1.0, child: Text('ST-T Wave Abnormality')),
                          const DropdownMenuItem(value: 2.0, child: Text('LVH')),
                        ], (v) => setState(() => _restingECG = v!)),

                        _styledField("Max Heart Rate", _maxHRCtrl, "bpm"),

                        // ADDED: Exercise Induced Angina Field (Parameter 9)
                        _styledDropdown("Exercise Induced Angina", _exerciseAngina, [
                          const DropdownMenuItem(value: 0.0, child: Text('No')),
                          const DropdownMenuItem(value: 1.0, child: Text('Yes')),
                        ], (v) => setState(() => _exerciseAngina = v!)),

                        _styledField("ST Depression (Oldpeak)", _oldpeakCtrl, "e.g. 1.5"),
                        _styledDropdown("ST Slope", _stSlope, [
                          const DropdownMenuItem(value: 0.0, child: Text('Up')),
                          const DropdownMenuItem(value: 1.0, child: Text('Flat')),
                          const DropdownMenuItem(value: 2.0, child: Text('Down')),
                        ], (v) => setState(() => _stSlope = v!)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI HELPER: Branch Premium Text Field
  Widget _styledField(String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: TextFormField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            labelStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ),
    );
  }

  // UI HELPER: Branch Premium Dropdown
  Widget _styledDropdown(String label, double value, List<DropdownMenuItem<double>> items, void Function(double?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButtonFormField<double>(
            value: value,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _isLoading ? null : _onSubmit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF06B6D4)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 20)],
            ),
            child: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Analyze Risk", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _glow(Color color) {
    return Container(
      height: 300, width: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent], radius: 0.8),
      ),
    );
  }
}
