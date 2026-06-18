import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class register_Screen extends StatefulWidget {
  const register_Screen({super.key});

  @override
  State<register_Screen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<register_Screen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      await FirebaseFirestore.instance
          .collection("users")
          .doc(cred.user!.uid)
          .set({
            "email": cred.user!.email,
            "username": usernameController.text.trim(),
            "role": "patient",
            "createdAt": Timestamp.now(),
          });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration successful")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration failed: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F9B8E), Color(0xFF1FC8DB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_hospital,
                        size: 80,
                        color: Color(0xFF0F9B8E),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Create Account",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email
                      _field(
                        controller: emailController,
                        label: "Email",
                        icon: Icons.email,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Email required";
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return "Enter a valid email";
                          }
                          if (!RegExp(
                            r'@[^@]+.(com)$',
                            caseSensitive: false,
                          ).hasMatch(v)) {
                            return "Email domain must be .com";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Username
                      _field(
                        controller: usernameController,
                        label: "Username",
                        icon: Icons.person,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Username required";
                          }
                          if (v.length < 3) {
                            return "Minimum 3 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Password
                      _passwordField(
                        controller: passwordController,
                        label: "Password",
                        hidden: hidePassword,
                        toggle: () =>
                            setState(() => hidePassword = !hidePassword),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Password required";
                          }
                          if (v.length < 7) {
                            return "Minimum 7 characters";
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(v)) {
                            return "Add at least one uppercase letter";
                          }
                          if (!RegExp(r'[0-9]').hasMatch(v)) {
                            return "Add at least one number";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Confirm pw
                      _passwordField(
                        controller: confirmPasswordController,
                        label: "Confirm Password",
                        hidden: hideConfirmPassword,
                        toggle: () => setState(
                          () => hideConfirmPassword = !hideConfirmPassword,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Confirm password";
                          }
                          if (v != passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9B8E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "REGISTER",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // reusable field
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  //Password field
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hidden,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
}
