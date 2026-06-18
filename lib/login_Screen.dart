import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_Screen.dart';
import 'patient_Dashboard.dart';
import 'admin_Dashboard.dart';
import 'doctor_Dashboard.dart';

class login_Screen extends StatefulWidget {
  const login_Screen({super.key});

  @override
  State<login_Screen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<login_Screen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _getUserRole(String uid) async {
    // final user = FirebaseAuth.instance.currentUser;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    if (doc.exists && doc.data()!.containsKey("role")) {
      return doc["role"];
    }
    return "patient";
  }

  void _navigateToRole(String role) {
    Widget dashboard = role == "admin"
        ? admin_Dashboard()
        : role == "doctor"
        ? doctor_Dashboard()
        : patient_Dashboard();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  // Email Login
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final role = await _getUserRole(cred.user!.uid);

      _navigateToRole(role);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Successful")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
    final user = FirebaseAuth.instance.currentUser!;
    final ref = FirebaseFirestore.instance.collection("users").doc(user.uid);

    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        "email": user.email,
        "role": "patient", // default
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  //Google Login
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCred.user!;
      // Create user record if first time
      final ref = FirebaseFirestore.instance.collection("users").doc(user.uid);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          "email": user.email,
          "role": "patient", // default
        });
      }
      final role = await _getUserRole(user.uid);
      _navigateToRole(role);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Google Login Successful")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F9B8E), Color.fromARGB(255, 104, 191, 201)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
                          "Welcome Back",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Login to your account",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Email
                        TextFormField(
                          key: const Key("emailField"), //this is new
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? "Email is required"
                              : null,
                        ),

                        const SizedBox(height: 16),
                        // Password
                        TextFormField(
                          key: const Key("passwordField"), //this is new
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? "Password is required"
                              : null,
                        ),

                        const SizedBox(height: 24),
                        // Login btn
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            key: const Key("loginButton"), //this is new
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F9B8E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loginUser,
                            child: Text(
                              "LOGIN",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("OR"),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 12),
                        // Google btn
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            label: const Text(
                              "Sign in with Google",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        TextButton(
                          key: const Key("registerButton"), // this is new
                          child: const Text(
                            "Don’t have an account? Create one",
                            style: TextStyle(
                              color: Color.fromARGB(255, 18, 118, 108),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => register_Screen(),
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
      ),
    );
  }
}
