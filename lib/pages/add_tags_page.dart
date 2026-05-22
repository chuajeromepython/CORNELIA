import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ai/helper_functions/toast.dart';
import 'package:firebase_ai/helper_functions/popup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';

class AddTags extends StatefulWidget {
  const AddTags({super.key});

  @override
  State<AddTags> createState() => _AddTags();
}

class _AddTags extends State<AddTags> {
  final user = FirebaseAuth.instance.currentUser!;
  final tagController = TextEditingController();
  final commentController = TextEditingController();
  String anonymousNickname = '';
  bool usingAnon = false;
  bool isCreating = false;

  static const _bg = Color(0xFF17171E);
  static const _surface = Color(0xFF0F1117);
  static const _accentBlue = Color(0xFF4FC3F7);
  static const _accentGreen = Color(0xFF81C784);
  static const _accentPurple = Color(0xFFBA68C8);

  String randomId(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> createTopic() async {
    if (isCreating) return;
    final title = tagController.text.trim();
    final comment = commentController.text.trim();
    if (title.isEmpty || comment.isEmpty) {
      showPopUp(context, 'Please fill in both fields.');
      return;
    }
    setState(() => isCreating = true);
    try {
      final uid = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() as Map<String, dynamic>;
      final tagRef = FirebaseFirestore.instance.collection('topics').doc();
      await tagRef.set({
        'title': title,
        'titleLower': title.toLowerCase(),
        'commentNo': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });
      await tagRef.collection('comments').add({
        'text': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': usingAnon ? anonymousNickname : data['username'],
        'userUid': uid,
        'isAnon': usingAnon,
      });
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'commentsMade': FieldValue.increment(1),
        'topicsMade': FieldValue.increment(1),
      });
      if (!mounted) return;
      tagController.clear();
      commentController.clear();
      setState(() {
        usingAnon = false;
      });
      showSlidingToast(context, 'Topic created successfully');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showSlidingToast(context, e.message.toString());
    } finally {
      if (mounted) setState(() => isCreating = false);
    }
  }

  @override
  void dispose() {
    tagController.dispose();
    commentController.dispose();
    super.dispose();
  }

  // ── Shared input decoration ──────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required FaIconData icon,
    required Color accentColor,
    EdgeInsetsGeometry? contentPadding,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: TextStyle(color: accentColor.withValues(alpha: 0.7)),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 12),
        child: FaIcon(icon, color: accentColor, size: 15),
      ),
      prefixIconConstraints: const BoxConstraints(),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: _surface,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(14),
      ),
    );
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
            FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Create a Topic',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Profile avatar ─────────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _accentBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: _accentBlue.withValues(alpha: 0.6),
                      size: 13,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        textAlign: TextAlign.justify,
                        "You are about to create a topic. Once created, it will be posted with the visibility set to public by default. You can create a topic anonymously by toggling anonymous posting under Options below. Your name and profile picture won't show as the author.",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section label ──────────────────────────────────────────────
            const Text(
              'Topic Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // ── Topic field ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentBlue.withValues(alpha: 0.2)),
              ),
              child: TextField(
                cursorColor: _accentBlue,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                controller: tagController,
                decoration:
                    _inputDecoration(
                      label: 'Topic',
                      hint: 'e.g. Deep Learning',
                      icon: FontAwesomeIcons.tag,
                      accentColor: _accentBlue,
                    ).copyWith(
                      filled: false,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Comment field ──────────────────────────────────────────────
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentGreen.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: commentController,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: _accentGreen,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  labelText: 'Comment',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    color: _accentGreen.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      left: 14,
                      right: 12,
                      top: 14,
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.commentDots,
                      color: _accentGreen,
                      size: 15,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                  contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Anonymous toggle ───────────────────────────────────────────
            const Text(
              'Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentPurple.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _accentPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _accentPurple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.userSecret,
                        color: _accentPurple,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Post anonymously',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Your name and profile picture won't show as the author.",
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: usingAnon,
                      activeColor: _accentPurple,
                      activeTrackColor: _accentPurple.withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                      onChanged: (value) async {
                        setState(() {
                          anonymousNickname = randomId(10);
                        });
                        if (value) {
                          setState(() => usingAnon = true);
                          final result = await showModalBottomSheet<bool>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                      24,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      20,
                                      24,
                                      30,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: _accentPurple.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 4,
                                          margin: const EdgeInsets.only(
                                            bottom: 18,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 52,
                                          height: 52,
                                          margin: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _accentPurple.withValues(
                                              alpha: 0.12,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _accentPurple.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
                                          ),
                                          child: const Center(
                                            child: FaIcon(
                                              FontAwesomeIcons.userSecret,
                                              color: _accentPurple,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          "We've generated a random string for you.",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _accentPurple.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: _accentPurple.withValues(
                                                alpha: 0.25,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            anonymousNickname,
                                            style: const TextStyle(
                                              color: _accentPurple,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'This will be shown instead of your username.',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 22),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                ),
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _accentPurple
                                                      .withValues(alpha: 0.15),
                                                  foregroundColor:
                                                      _accentPurple,
                                                  elevation: 0,
                                                  side: BorderSide(
                                                    color: _accentPurple
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                ),
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text(
                                                  'Continue',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
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
                          if (mounted) {
                            setState(() {
                              usingAnon = result ?? false;
                            });
                          }
                        } else {
                          setState(() => usingAnon = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Create button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue.withValues(alpha: 0.15),
                  foregroundColor: _accentBlue,
                  elevation: 0,
                  side: BorderSide(color: _accentBlue.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isCreating ? null : createTopic,
                child: isCreating
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accentBlue,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.plus, size: 13),
                          SizedBox(width: 8),
                          Text(
                            'Create Topic',
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
    );
  }
}
