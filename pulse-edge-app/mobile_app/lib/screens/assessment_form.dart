import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../services/ml_service.dart';
import '../services/local_db.dart';
import 'dashboard_screen.dart';

// ================================================================
// Assessment Form Screen
// User fills in 11 medical columns → TFLite prediction → Dashboard
// ================================================================

class AssessmentFormScreen extends ConsumerStatefulWidget {
  const AssessmentFormScreen({super.key});

  @override
  ConsumerState<AssessmentFormScreen> createState() =>
      _AssessmentFormScreenState();
}

class _AssessmentFormScreenState
    extends ConsumerState<AssessmentFormScreen> {
  final _formKey  = GlobalKey<FormState>();
  bool _isLoading = false;

  // Text controllers for numeric inputs
  final _ageCtrl         = TextEditingController();
  final _restingBPCtrl   = TextEditingController();
  final _cholesterolCtrl = TextEditingController();
  final _maxHRCtrl       = TextEditingController();
  final _oldpeakCtrl     = TextEditingController();

  // Dropdown selections (default to most common values for testing)
  double _sex            = 1.0; // Male
  double _chestPainType  = 2.0; // ASY (most common in dataset)
  double _fastingBS      = 0.0; // No
  double _restingECG     = 0.0; // Normal
  double _exerciseAngina = 0.0; // No
  double _stSlope        = 1.0; // Flat

  @override
  void dispose() {
    _ageCtrl.dispose();
    _restingBPCtrl.dispose();
    _cholesterolCtrl.dispose();
    _maxHRCtrl.dispose();
    _oldpeakCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Build raw inputs list
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

      // Normalize inputs using Member 4's ml_service
      final List<double> normalizedInputs = MLService.normalizeInputs(
        age:            rawInputs[0],
        sex:            rawInputs[1],
        chestPainType:  rawInputs[2],
        restingBP:      rawInputs[3],
        cholesterol:    rawInputs[4],
        fastingBS:      rawInputs[5],
        restingECG:     rawInputs[6],
        maxHR:          rawInputs[7],
        exerciseAngina: rawInputs[8],
        oldpeak:        rawInputs[9],
        stSlope:        rawInputs[10],
      );

      // Run TFLite inference
      final double riskScore = await MLService.predictRisk(normalizedInputs);

      // Save to local database
      await LocalDB.saveUserProfile(
        rawInputs:  rawInputs,
        riskScore:  riskScore,
      );

      // Update Riverpod state so dashboard shows correct risk
      ref.read(riskProvider.notifier).state = riskScore;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Widget helpers ──────────────────────────────────────────────

  Widget _textField(
    String label,
    TextEditingController ctrl,
    String hint, {
    String? unit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller:  ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText:   label,
          hintText:    hint,
          suffixText:  unit,
          border:      const OutlineInputBorder(),
          filled:      true,
          fillColor:   Colors.grey.shade50,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (double.tryParse(v) == null)    return 'Enter a valid number';
          return null;
        },
      ),
    );
  }

  Widget _dropdown(
    String label,
    double value,
    List<DropdownMenuItem<double>> items,
    void Function(double?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<double>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border:    const OutlineInputBorder(),
          filled:    true,
          fillColor: Colors.grey.shade50,
        ),
        items:     items,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Risk Assessment'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text('Calculating your risk...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please fill in your medical details accurately.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    _textField('Age', _ageCtrl, 'e.g. 45', unit: 'years'),
                    _dropdown('Sex', _sex, [
                      const DropdownMenuItem(value: 1.0, child: Text('Male')),
                      const DropdownMenuItem(value: 0.0, child: Text('Female')),
                    ], (v) => setState(() => _sex = v!)),
                    _dropdown('Chest Pain Type', _chestPainType, [
                      const DropdownMenuItem(value: 0.0, child: Text('ATA — Atypical Angina')),
                      const DropdownMenuItem(value: 1.0, child: Text('NAP — Non-Anginal Pain')),
                      const DropdownMenuItem(value: 2.0, child: Text('ASY — Asymptomatic')),
                      const DropdownMenuItem(value: 3.0, child: Text('TA — Typical Angina')),
                    ], (v) => setState(() => _chestPainType = v!)),
                    _textField('Resting Blood Pressure', _restingBPCtrl, 'e.g. 120', unit: 'mmHg'),
                    _textField('Cholesterol', _cholesterolCtrl, 'e.g. 200', unit: 'mg/dL'),
                    _dropdown('Fasting Blood Sugar > 120 mg/dL', _fastingBS, [
                      const DropdownMenuItem(value: 0.0, child: Text('No')),
                      const DropdownMenuItem(value: 1.0, child: Text('Yes')),
                    ], (v) => setState(() => _fastingBS = v!)),
                    _dropdown('Resting ECG Result', _restingECG, [
                      const DropdownMenuItem(value: 0.0, child: Text('Normal')),
                      const DropdownMenuItem(value: 1.0, child: Text('ST — ST-T Wave Abnormality')),
                      const DropdownMenuItem(value: 2.0, child: Text('LVH — Left Ventricular Hypertrophy')),
                    ], (v) => setState(() => _restingECG = v!)),
                    _textField('Max Heart Rate Achieved', _maxHRCtrl, 'e.g. 150', unit: 'bpm'),
                    _dropdown('Exercise Induced Angina', _exerciseAngina, [
                      const DropdownMenuItem(value: 0.0, child: Text('No')),
                      const DropdownMenuItem(value: 1.0, child: Text('Yes')),
                    ], (v) => setState(() => _exerciseAngina = v!)),
                    _textField('Oldpeak (ST Depression)', _oldpeakCtrl, 'e.g. 1.5'),
                    _dropdown('ST Slope', _stSlope, [
                      const DropdownMenuItem(value: 0.0, child: Text('Up — Upsloping')),
                      const DropdownMenuItem(value: 1.0, child: Text('Flat')),
                      const DropdownMenuItem(value: 2.0, child: Text('Down — Downsloping')),
                    ], (v) => setState(() => _stSlope = v!)),

                    const SizedBox(height: 24),
                    SizedBox(
                      width:  double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Calculate My Risk',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}