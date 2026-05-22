import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/helper_functions/toast.dart';
import 'package:firebase_ai/pages/home_page.dart';
import 'package:firebase_ai/pages/register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';

// ── Design tokens (mirrors Sandbox) ─────────────────────────────────────────
const _bg = Color(0xFF17171E);
const _surface = Color(0xFF0F1117);
const _accent = Color(0xFF4FC3F7);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoggingIn = false;
  bool _isGoogleSigningIn = false;

  // ── Google sign-in ────────────────────────────────────────────────────────

  Future<void> signIn() async {
    setState(() => _isGoogleSigningIn = true);

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '606289969596-t6j7ukt3evgato5eiqdehl638htja005.apps.googleusercontent.com',
      );

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential cred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      User user = cred.user!;
      String uid = user.uid;
      String? fullname = user.displayName;
      String? email = user.email;

      DocumentReference userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      DocumentSnapshot doc = await userRef.get();

      if (!doc.exists) {
        final usernameController = TextEditingController();
        final ageController = TextEditingController();
        String? selectedCountry;
        String? gender;

        if (!mounted) return;
        final userDetails = await showModalBottomSheet<Map<String, String>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // drag handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tell us a bit about yourself to get started.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sandboxField(
                        controller: usernameController,
                        label: 'Username',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 10),
                      _sandboxField(
                        controller: ageController,
                        label: 'Age',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      // Country picker
                      GestureDetector(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: false,
                            onSelect: (Country country) {
                              setModalState(() {
                                selectedCountry = country.name;
                              });
                            },
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                color: Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedCountry ?? 'Select country',
                                style: TextStyle(
                                  color: selectedCountry == null
                                      ? Colors.white38
                                      : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Gender
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gender',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: ['Male', 'Female'].map((g) {
                                return Row(
                                  children: [
                                    Radio<String>(
                                      value: g,
                                      groupValue: gender,
                                      activeColor: _accent,
                                      onChanged: (value) {
                                        setModalState(() => gender = value);
                                      },
                                    ),
                                    Text(
                                      g,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, null),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _sandboxPrimaryButton(
                              label: 'Submit',
                              onPressed: () {
                                if (usernameController.text.isNotEmpty &&
                                    ageController.text.isNotEmpty &&
                                    selectedCountry != null &&
                                    gender != null) {
                                  Navigator.pop(context, {
                                    'username': usernameController.text.trim(),
                                    'age': ageController.text.trim(),
                                    'country': selectedCountry!,
                                    'gender': gender!,
                                  });
                                  showSlidingToast(
                                    context,
                                    "Thank you. We won't ask you again.",
                                  );
                                } else {
                                  showSlidingToast(
                                    context,
                                    'Please fill all fields',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        if (userDetails == null) {
          await user.delete();
          await FirebaseAuth.instance.signOut();
          setState(() => _isGoogleSigningIn = false);
          return;
        }
        await userRef.set({
          'username': userDetails['username'],
          'fullname': fullname ?? '',
          'country': userDetails['country'],
          'age': userDetails['age'],
          'gender': userDetails['gender'],
          'email': email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'commentsMade': 0,
          'topicsMade': 0,
          'viewedTopics': 0,
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      showSlidingToast(context, 'Logged in successfully');
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          opaque: false,
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(opacity: curved, child: child);
          },
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      showSlidingToast(context, e.message.toString());
    } finally {
      if (mounted) setState(() => _isGoogleSigningIn = false);
    }
  }

  Future<Map<String, String>?> showUserDetailsModal(
    BuildContext context,
  ) async {
    final usernameCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    String? gender;

    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _sandboxField(
                  controller: usernameCtrl,
                  label: 'Username',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 10),
                _sandboxField(
                  controller: countryCtrl,
                  label: 'Country',
                  icon: Icons.flag_outlined,
                ),
                const SizedBox(height: 10),
                // Gender dropdown styled
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: gender,
                    dropdownColor: _surface,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      labelStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.wc_outlined,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => gender = value,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _sandboxPrimaryButton(
                        label: 'Submit',
                        onPressed: () {
                          if (usernameCtrl.text.isNotEmpty &&
                              countryCtrl.text.isNotEmpty &&
                              gender != null) {
                            Navigator.pop(context, {
                              'username': usernameCtrl.text.trim(),
                              'country': countryCtrl.text.trim(),
                              'gender': gender!,
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Reset password ────────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _formKey.currentState!.save();
      if (!mounted) return;
      showSlidingToast(
        context,
        'A password reset link has been sent to your email address.',
      );
    } on FirebaseAuthException catch (e) {
      showSlidingToast(context, e.message.toString());
    }
  }

  // ── Email login ───────────────────────────────────────────────────────────

  Future<void> logIn() async {
    setState(() => _isLoggingIn = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      showSlidingToast(context, 'Logged in successfully');
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(opacity: curved, child: child);
          },
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      showSlidingToast(context, e.message.toString());
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Shared styled helpers ─────────────────────────────────────────────────

  /// A text field styled to match the Sandbox dark theme.
  static Widget _sandboxField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: _accent,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF5350), fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _accent, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// A solid accent-tinted primary button (used in modals).
  static Widget _sandboxPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── Forgot password bottom sheet ──────────────────────────────────────────

  void _showForgotPasswordSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // icon badge
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(
                    Icons.lock_reset_outlined,
                    color: _accent,
                    size: 20,
                  ),
                ),
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Enter your email and we'll send you a reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 20),
                _sandboxField(
                  controller: controller,
                  label: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _sandboxPrimaryButton(
                        label: 'Send link',
                        onPressed: () {
                          resetPassword(controller.text.trim());
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // ── Hero card ────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Logo
                        SvgPicture.asset(
                          'assets/cornelia_ai_logo_flower-cropped.svg',
                          height: 150,
                          width: 150,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Form card ────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // section label
                          _sectionLabel('Credentials'),
                          const SizedBox(height: 14),

                          // Email
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sandboxField(
                              controller: emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Password
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sandboxField(
                              controller: passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscureText,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                  () => _obscureText = !_obscureText,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Forgot password
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _showForgotPasswordSheet,
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _accent.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Sign-in button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(
                                  0xFF4FC3F7,
                                ).withValues(alpha: 0.12),
                                foregroundColor: Color(0xFF4FC3F7),
                                elevation: 0,
                                side: BorderSide(
                                  color: Color(
                                    0xFF4FC3F7,
                                  ).withValues(alpha: 0.35),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onPressed: _isLoggingIn
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        logIn();
                                      } else {
                                        showSlidingToast(
                                          context,
                                          'Invalid Form! Please try again.',
                                        );
                                        Future.delayed(
                                          const Duration(seconds: 2),
                                          () {
                                            if (mounted) {
                                              _formKey.currentState!.reset();
                                            }
                                          },
                                        );
                                      }
                                    },
                              child: _isLoggingIn
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'SIGN IN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Google button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(
                                  0xFF4FC3F7,
                                ).withValues(alpha: 0.12),
                                foregroundColor: Color(0xFF4FC3F7),
                                elevation: 0,
                                side: BorderSide(
                                  color: Color(
                                    0xFF4FC3F7,
                                  ).withValues(alpha: 0.35),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onPressed: _isGoogleSigningIn ? null : signIn,
                              child: _isGoogleSigningIn
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FaIcon(
                                          FontAwesomeIcons.google,
                                          color: Colors.redAccent,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Sign in with Google',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?  ",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                milliseconds: 400,
                              ),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      RegisterPage(),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    final curved = CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    );
                                    return FadeTransition(
                                      opacity: curved,
                                      child: child,
                                    );
                                  },
                            ),
                          );
                        },
                        child: const Text(
                          'Register here.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section label (mirrors Sandbox 01/02 labels without number) ───────────
  Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
