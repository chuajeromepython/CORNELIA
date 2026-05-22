import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ai/helper_functions/toast.dart';
import 'package:firebase_ai/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfile();
}

class _UserProfile extends State<UserProfile> {
  final user = FirebaseAuth.instance.currentUser!;

  static const _bg = Color(0xFF17171E);
  static const _surface = Color(0xFF0F1117);
  static const _accentBlue = Color(0xFF4FC3F7);
  static const _accentGreen = Color(0xFF81C784);
  static const _accentOrange = Color(0xFFFFB74D);
  static const _accentPurple = Color(0xFFBA68C8);
  static const _accentRed = Color(0xFFE57373);

  bool isLoadingUsername = true;
  bool isLoggingOut = false;
  bool isUploadingPhoto = false;

  String username = '';
  String fullname = '';
  String email = '';
  String age = '';
  String gender = '';
  String country = '';
  int commentsMade = 0;
  int topicsMade = 0;
  int viewedTopics = 0;
  String joinedDate = '—';
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  Future<void> loadUsername() async {
    setState(() => isLoadingUsername = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final createdAt = data['createdAt'] as Timestamp?;
        if (!mounted) return;
        setState(() {
          username = data['username'] ?? 'User';
          fullname = data['fullname'] ?? '';
          email = data['email'] ?? user.email ?? '';
          age = data['age']?.toString() ?? '';
          gender = data['gender'] ?? '';
          country = data['country'] ?? '';
          commentsMade = data['commentsMade'] ?? 0;
          topicsMade = data['topicsMade'] ?? 0;
          viewedTopics = data['viewedTopics'] ?? 0;
          photoUrl = data['profilePicURL'];
          joinedDate = createdAt != null
              ? DateFormat('MMM d, yyyy').format(createdAt.toDate())
              : '—';
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showSlidingToast(context, e.message.toString());
      setState(() => username = 'User');
    } finally {
      if (mounted) setState(() => isLoadingUsername = false);
    }
  }

  // ── Photo upload ─────────────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 256,
      maxHeight: 256,
    );
    if (picked == null) return;

    setState(() => isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profilePicURL': 'data:image/jpeg;base64,$base64String'},
      );

      if (!mounted) return;
      setState(() => photoUrl = 'data:image/jpeg;base64,$base64String');
      showSlidingToast(context, 'Profile picture updated');
    } catch (e) {
      if (!mounted) return;
      showSlidingToast(context, 'Failed to upload photo: $e');
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => isUploadingPhoto = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profilePicURL': FieldValue.delete()},
      );

      if (!mounted) return;
      setState(() => photoUrl = null);
      showSlidingToast(context, 'Profile picture removed');
    } catch (e) {
      if (!mounted) return;
      showSlidingToast(context, 'Failed to remove photo: $e');
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _sheetOption(
                  icon: FontAwesomeIcons.image,
                  color: _accentBlue,
                  label: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadPhoto();
                  },
                ),
                if (photoUrl != null) ...[
                  const SizedBox(height: 10),
                  _sheetOption(
                    icon: FontAwesomeIcons.trash,
                    color: _accentRed,
                    label: 'Remove Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
                ],
                const SizedBox(height: 10),
                _sheetOption(
                  icon: FontAwesomeIcons.xmark,
                  color: Colors.white38,
                  label: 'Cancel',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetOption({
    required FaIconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(child: FaIcon(icon, color: color, size: 13)),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color == Colors.white38 ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────────

  Widget _infoRow({
    required FaIconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(child: FaIcon(icon, color: color, size: 13)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: Colors.white.withValues(alpha: 0.06), height: 1);

  Widget _statCard({
    required FaIconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Center(child: FaIcon(icon, color: color, size: 13)),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────

  Widget _avatar() {
    return GestureDetector(
      onTap: isUploadingPhoto ? null : _showPhotoOptions,
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: _accentBlue.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: isUploadingPhoto
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accentBlue,
                      ),
                    ),
                  )
                : ClipOval(
                    child: photoUrl != null
                        ? Image.memory(
                            base64Decode(photoUrl!.split(',').last),
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                            errorBuilder: (_, __, ___) => const Center(
                              child: FaIcon(
                                FontAwesomeIcons.user,
                                color: _accentBlue,
                                size: 26,
                              ),
                            ),
                          )
                        : const Center(
                            child: FaIcon(
                              FontAwesomeIcons.user,
                              color: _accentBlue,
                              size: 26,
                            ),
                          ),
                  ),
          ),
          if (!isUploadingPhoto)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _accentBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 2),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.camera,
                    color: Colors.white,
                    size: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logOut() async {
    setState(() => isLoggingOut = true);
    await Future.delayed(const Duration(seconds: 2));
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      showSlidingToast(context, 'Logged out successfully');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          opaque: false,
          pageBuilder: (_, __, ___) => const LoginPage(),
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
      if (!mounted) return;
      showSlidingToast(context, e.message.toString());
    } finally {
      if (mounted) setState(() => isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _bg,
        elevation: 0,
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.circleUser, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: isLoadingUsername
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            )
          : RefreshIndicator(
              onRefresh: loadUsername,
              color: Colors.white,
              backgroundColor: _surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header card ────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          _avatar(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullname.isNotEmpty ? fullname : username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Member since $joinedDate',
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: isUploadingPhoto
                                      ? null
                                      : _showPhotoOptions,
                                  child: Text(
                                    photoUrl != null
                                        ? 'Change photo'
                                        : 'Add profile photo',
                                    style: TextStyle(
                                      color: _accentBlue.withValues(alpha: 0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Activity stats ─────────────────────────────────────
                    const Text(
                      'Activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statCard(
                          icon: FontAwesomeIcons.commentDots,
                          color: _accentBlue,
                          label: 'Comments',
                          value: commentsMade.toString(),
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          icon: FontAwesomeIcons.lightbulb,
                          color: _accentGreen,
                          label: 'Topics',
                          value: topicsMade.toString(),
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          icon: FontAwesomeIcons.eye,
                          color: _accentOrange,
                          label: 'Viewed',
                          value: viewedTopics.toString(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Personal info ──────────────────────────────────────
                    const Text(
                      'Personal Info',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            icon: FontAwesomeIcons.solidEnvelope,
                            color: _accentBlue,
                            label: 'EMAIL',
                            value: email,
                          ),
                          _divider(),
                          _infoRow(
                            icon: FontAwesomeIcons.cakeCandles,
                            color: _accentOrange,
                            label: 'AGE',
                            value: age,
                          ),
                          _divider(),
                          _infoRow(
                            icon: FontAwesomeIcons.venusMars,
                            color: _accentPurple,
                            label: 'GENDER',
                            value: gender,
                          ),
                          _divider(),
                          _infoRow(
                            icon: FontAwesomeIcons.earthAsia,
                            color: _accentGreen,
                            label: 'COUNTRY',
                            value: country,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Account ────────────────────────────────────────────
                    const Text(
                      'Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            icon: FontAwesomeIcons.fingerprint,
                            color: Colors.white38,
                            label: 'USER ID',
                            value: user.uid,
                          ),
                          _divider(),
                          _infoRow(
                            icon: FontAwesomeIcons.calendarDay,
                            color: _accentBlue,
                            label: 'JOINED',
                            value: joinedDate,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Logout ─────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentRed.withValues(alpha: 0.12),
                          foregroundColor: _accentRed,
                          elevation: 0,
                          side: BorderSide(
                            color: _accentRed.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: isLoggingOut ? null : logOut,
                        child: isLoggingOut
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _accentRed,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.arrowRightFromBracket,
                                    size: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
