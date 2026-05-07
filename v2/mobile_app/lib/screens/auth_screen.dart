import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../core/error_handler.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await ref.read(authStateProvider.notifier).signIn(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
      } else {
        await ref.read(authStateProvider.notifier).signUp(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
      }
      // If successful, authStateProvider will automatically update and the AuthGate will handle navigation.
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Pop back so AuthGate can route
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getMessage(e)), 
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100, right: -50,
            child: _glow(const Color(0xFF6366F1)),
          ),
          Positioned(
            bottom: -100, left: -50,
            child: _glow(const Color(0xFF06B6D4)),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.1),
                              blurRadius: 40,
                              spreadRadius: 10,
                            )
                          ],
                        ),
                        child: const Icon(Icons.health_and_safety, size: 80, color: Colors.cyanAccent),
                      ),
                      const SizedBox(height: 40),
                      
                      Text(
                        _isLogin ? "Welcome Back" : "Create Account",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 30),

                      // Email Field
                      _styledField(
                        controller: _emailCtrl,
                        label: "Email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password Field
                      _styledField(
                        controller: _passwordCtrl,
                        label: "Password",
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),

                      const SizedBox(height: 40),

                      // Submit Button
                      _buildSubmitButton(),

                      const SizedBox(height: 20),

                      // Toggle Button
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          if (label == "Email" && !value.contains('@')) {
            return 'Invalid Email';
          }
          if (label == "Password" && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _isLoading ? null : _submit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF06B6D4)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _isLogin ? "Log In" : "Sign Up",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
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
        gradient: RadialGradient(colors: [color.withOpacity(0.5), Colors.transparent], radius: 0.8),
      ),
    );
  }
}
