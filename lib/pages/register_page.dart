import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ai/helper_functions/toast.dart';
import 'package:firebase_ai/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ── Design tokens (mirrors Login page) ──────────────────────────────────────
const _bg = Color(0xFF17171E);
const _surface = Color(0xFF0F1117);
const _accent = Color(0xFF4FC3F7);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPage();
}

class _RegisterPage extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ageController = TextEditingController();
  bool _obscureTextp = true;
  bool _obscureTextc = true;
  bool _isRegistering = false;
  Country? selectedCountry;
  String? selectedGender;

  Future<void> register() async {
    setState(() => _isRegistering = true);
    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      String uid = cred.user!.uid;
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      DocumentSnapshot doc = await userRef.get();
      if (!doc.exists) {
        await addUser(uid);
      }
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      showSlidingToast(context, "Registered successfully");
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(opacity: curved, child: child);
          },
        ),
      );
    } on FirebaseAuthException catch (e) {
      showSlidingToast(context, e.message.toString());
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> addUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'username': usernameController.text.trim(),
      'fullname': fullnameController.text.trim(),
      'country': selectedCountry?.name ?? '',
      'gender': selectedGender ?? '',
      'age': ageController.text.trim(),
      'email': emailController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'commentsMade': 0,
      'topicsMade': 0,
      'viewedTopics': 0,
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    fullnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // ── Shared styled helpers (mirrors LoginPage) ─────────────────────────────

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
                        SvgPicture.asset(
                          'assets/cornelia_ai_logo_flower-cropped.svg',
                          height: 150,
                          width: 150,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Join CORNELIA',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create your account to get started',
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
                          // ── Profile section ──────────────────────────────
                          _sectionLabel('Profile'),
                          const SizedBox(height: 14),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sandboxField(
                              controller: usernameController,
                              label: 'Username',
                              icon: Icons.supervised_user_circle_outlined,
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sandboxField(
                              controller: fullnameController,
                              label: 'Full name',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sandboxField(
                              controller: ageController,
                              label: 'Age',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your age';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ── Country picker ───────────────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: FormField<Country>(
                              validator: (value) {
                                if (selectedCountry == null) {
                                  return 'Please select your country';
                                }
                                return null;
                              },
                              builder: (FormFieldState<Country> state) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showCountryPicker(
                                          context: context,
                                          showPhoneCode: false,
                                          onSelect: (Country country) {
                                            setState(() {
                                              selectedCountry = country;
                                            });
                                            state.didChange(country);
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
                                          color: Colors.white.withValues(
                                            alpha: 0.04,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: state.hasError
                                                ? const Color(0xFFEF5350)
                                                : Colors.white.withValues(
                                                    alpha: 0.12,
                                                  ),
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
                                            Expanded(
                                              child: Text(
                                                selectedCountry == null
                                                    ? 'Select country'
                                                    : '${selectedCountry!.flagEmoji} ${selectedCountry!.name}',
                                                style: TextStyle(
                                                  color: selectedCountry == null
                                                      ? Colors.white38
                                                      : Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.white38,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (state.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                          top: 6,
                                        ),
                                        child: Text(
                                          state.errorText!,
                                          style: const TextStyle(
                                            color: Color(0xFFEF5350),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ── Gender picker ────────────────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: FormField<String>(
                              validator: (value) {
                                if (selectedGender == null) {
                                  return 'Please select your gender';
                                }
                                return null;
                              },
                              builder: (FormFieldState<String> state) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.04,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: state.hasError
                                              ? const Color(0xFFEF5350)
                                              : Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Gender',
                                            style: TextStyle(
                                              color: state.hasError
                                                  ? const Color(0xFFEF5350)
                                                  : Colors.white.withValues(
                                                      alpha: 0.5,
                                                    ),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Row(
                                            children: ['Male', 'Female'].map((
                                              g,
                                            ) {
                                              return Expanded(
                                                child: Row(
                                                  children: [
                                                    Radio<String>(
                                                      value: g,
                                                      groupValue:
                                                          selectedGender,
                                                      activeColor: _accent,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          selectedGender =
                                                              value;
                                                        });
                                                        state.didChange(value);
                                                      },
                                                    ),
                                                    Text(
                                                      g,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (state.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                          top: 6,
                                        ),
                                        child: Text(
                                          state.errorText!,
                                          style: const TextStyle(
                                            color: Color(0xFFEF5350),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Credentials section ──────────────────────────
                          _sectionLabel('Credentials'),
                          const SizedBox(height: 14),

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

                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sandboxField(
                              controller: passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscureTextp,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureTextp
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                  () => _obscureTextp = !_obscureTextp,
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
                          const SizedBox(height: 10),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: _sandboxField(
                              controller: confirmPasswordController,
                              label: 'Confirm password',
                              icon: Icons.lock_person_rounded,
                              obscureText: _obscureTextc,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureTextc
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                  () => _obscureTextc = !_obscureTextc,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                if (value != passwordController.text.trim()) {
                                  return "Passwords don't match";
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Sign-up button ───────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF4FC3F7,
                                ).withValues(alpha: 0.12),
                                foregroundColor: const Color(0xFF4FC3F7),
                                elevation: 0,
                                side: BorderSide(
                                  color: const Color(
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
                              onPressed: _isRegistering
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        register();
                                      } else {
                                        showSlidingToast(
                                          context,
                                          "Invalid Form! Please try again.",
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
                              child: _isRegistering
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'SIGN UP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Login link ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?  ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign in here.',
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
}
