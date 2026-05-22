import 'dart:convert';
import 'package:firebase_ai/pages/add_tags_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/pages/topics_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/helper_functions/toast.dart';
import 'package:firebase_ai/helper_functions/popup.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _Search();
}

class _Search extends State<Search> {
  String query = '';
  bool _animateResults = false;

  static const _bg = Color(0xFF17171E);
  static const _surface = Color(0xFF0F1117);
  static const _accentBlue = Color(0xFF4FC3F7);
  static const _accentGreen = Color(0xFF81C784);
  static const _accentOrange = Color(0xFFFFB74D);

  // ── Firestore helpers ────────────────────────────────────────────────────

  Stream<QuerySnapshot> searchTags(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance
          .collection('topics')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    final q = query.toLowerCase();
    return FirebaseFirestore.instance
        .collection('topics')
        .where('titleLower', isGreaterThanOrEqualTo: q)
        .where('titleLower', isLessThan: '$q\uf8ff')
        .snapshots();
  }

  Future<DocumentSnapshot> _fetchAnalyticsWithRetry(String topicId) async {
    const delays = [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 6),
    ];
    FirebaseException? lastError;

    for (int i = 0; i < 3; i++) {
      try {
        return await FirebaseFirestore.instance
            .collection('topics')
            .doc(topicId)
            .collection('analytics')
            .doc('latest')
            .get();
      } on FirebaseException catch (e) {
        lastError = e;
        if (e.code != 'unavailable' || i == 2) rethrow;
        await Future.delayed(delays[i]);
      }
    }
    throw lastError!;
  }

  // ── Track unique topic view ──────────────────────────────────────────────

  Future<void> _trackUniqueView(String topicId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final viewRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('viewedTopics')
        .doc(topicId);

    final viewSnap = await viewRef.get();
    if (!viewSnap.exists) {
      await Future.wait([
        viewRef.set({'viewedAt': FieldValue.serverTimestamp()}),
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'viewedTopics': FieldValue.increment(1),
        }),
      ]);
    }
  }

  // ── Open topic ───────────────────────────────────────────────────────────

  Future<void> _openTopic(
    BuildContext context,
    Map<String, dynamic> data,
    int count,
    String topicId,
  ) async {
    try {
      final analyticsDoc = await _fetchAnalyticsWithRetry(topicId);

      await _trackUniqueView(topicId);

      if (!mounted) return;

      Map<String, dynamic> sentimentData = {};
      List<dynamic> emotionData = [];
      List<(String, String)> sentimentSOT = [];
      List<Map<String, dynamic>> emergingTrends = [];
      Map<String, dynamic> themesData = {};
      List<Map<String, dynamic>> choroplethData = [];
      Map<String, dynamic> networkData = {};
      List<dynamic> heatmapdata = [];
      String executiveSummary = '';
      List<Map<String, dynamic>> keyInsights = [];
      List<Map<String, dynamic>> emergingIssues = [];
      List<Map<String, dynamic>> negativeOutliers = [];
      List<Map<String, dynamic>> negativeOutlierAnalyses = [];
      Map<String, dynamic> deadInternetTheory = {};

      if (analyticsDoc.exists && analyticsDoc.data() != null) {
        final analyticsData = analyticsDoc.data() as Map<String, dynamic>;
        final raw = (analyticsData['sentimentSOT_dist'] as List?) ?? [];
        sentimentSOT = raw
            .map((e) => (e['date'] as String, e['label'] as String))
            .toList();
        sentimentData = analyticsData['sentiment_dist'] ?? {};
        emotionData = analyticsData['emotion_dist'] ?? [];
        emergingTrends = ((analyticsData['emergingTrends_dist'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        themesData = Map<String, dynamic>.from(
          analyticsData['themes_dist'] as Map? ?? {},
        );
        choroplethData = ((analyticsData['choropleth_data'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        networkData = Map<String, dynamic>.from(
          analyticsData['network_connections'] as Map? ?? {},
        );
        heatmapdata = List<dynamic>.from(
          analyticsData['correlation_data'] as List? ?? [],
        );
        executiveSummary = analyticsData['executive_summary'] ?? '';
        keyInsights = ((analyticsData['key_insights'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        emergingIssues = ((analyticsData['emerging_issues'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        negativeOutliers = ((analyticsData['negative_outliers'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        negativeOutlierAnalyses =
            ((analyticsData['negative_outlier_analyses'] as List?) ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
        deadInternetTheory = Map<String, dynamic>.from(
          analyticsData['dead_internet_theory'] as Map? ?? {},
        );
      }

      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          opaque: false,
          pageBuilder: (_, __, ___) => Topic(
            title: data["title"] ?? "Topic",
            topicId: topicId,
            author: data["createdBy"] ?? "Unknown",
            sentimentData: sentimentData,
            emotionData: emotionData,
            sentimentDataSOT: sentimentSOT,
            emergingTrends: emergingTrends,
            themesData: themesData,
            choroplethData: choroplethData,
            networkData: networkData,
            heatmapdata: heatmapdata,
            executiveSummary: executiveSummary,
            keyInsights: keyInsights,
            emergingIssues: emergingIssues,
            negativeOutliers: negativeOutliers,
            negativeOutlierAnalyses: negativeOutlierAnalyses,
            deadInternetTheory: deadInternetTheory,
          ),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(opacity: curved, child: child);
          },
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showSlidingToast(context, "Failed to load topic: ${e.message}");
    }
  }

  // ── UI helpers ───────────────────────────────────────────────────────────

  Widget _statusBadge(int count) {
    final isActive = count >= 10;
    final color = isActive ? _accentGreen : _accentOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showInactiveSheet(String title, String topicId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _accentOrange.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _accentOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _accentOrange.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: _accentOrange,
                      size: 20,
                    ),
                  ),
                ),
                const Text(
                  'Not enough data yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This topic needs at least 10 or more comments before analysis is available.\n\nYou can still view the discussion and add comments.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentBlue.withValues(alpha: 0.15),
                          foregroundColor: _accentBlue,
                          elevation: 0,
                          side: BorderSide(
                            color: _accentBlue.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _openCommentsSheet(topicId, title);
                        },
                        child: const Text(
                          'View Comments',
                          style: TextStyle(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
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

  void _openCommentsSheet(String topicId, String title) {
    final controller = TextEditingController();
    bool isSending = false;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    Stream<QuerySnapshot> getComments() {
      return FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    Future<void> addComment(StateSetter setModalState) async {
      if (isSending) return;
      final text = controller.text.trim();
      if (text.isEmpty) {
        showSlidingToast(context, 'Your comment is empty.');
        return;
      }
      setModalState(() => isSending = true);
      try {
        final user = FirebaseAuth.instance.currentUser!;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final name = (userDoc.data() as Map<String, dynamic>)['username'];
        await FirebaseFirestore.instance
            .collection('topics')
            .doc(topicId)
            .collection('comments')
            .add({
              'text': text,
              'createdAt': FieldValue.serverTimestamp(),
              'createdBy': name,
              'userUid': user.uid,
              'likes': [],
              'dislikes': [],
            });
        await FirebaseFirestore.instance
            .collection('topics')
            .doc(topicId)
            .update({'commentNo': FieldValue.increment(1)});
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'commentsMade': FieldValue.increment(1)});
        controller.clear();
        if (!mounted) return;
        showSlidingToast(context, 'Comment added');
      } on FirebaseException catch (e) {
        showPopUp(context, e.message.toString());
      } finally {
        setModalState(() => isSending = false);
      }
    }

    // ── Like / Dislike helpers ─────────────────────────────────────────────

    Future<void> toggleLike(
      String commentId,
      List<String> likes,
      List<String> dislikes,
    ) async {
      final ref = FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('comments')
          .doc(commentId);

      if (likes.contains(currentUid)) {
        await ref.update({
          'likes': FieldValue.arrayRemove([currentUid]),
        });
      } else {
        await ref.update({
          'likes': FieldValue.arrayUnion([currentUid]),
          'dislikes': FieldValue.arrayRemove([currentUid]),
        });
      }
    }

    Future<void> toggleDislike(
      String commentId,
      List<String> likes,
      List<String> dislikes,
    ) async {
      final ref = FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('comments')
          .doc(commentId);

      if (dislikes.contains(currentUid)) {
        await ref.update({
          'dislikes': FieldValue.arrayRemove([currentUid]),
        });
      } else {
        await ref.update({
          'dislikes': FieldValue.arrayUnion([currentUid]),
          'likes': FieldValue.arrayRemove([currentUid]),
        });
      }
    }

    // ── Profile avatar widget ──────────────────────────────────────────────

    Widget buildAvatar(String? userUid) {
      const fallback = Center(
        child: FaIcon(FontAwesomeIcons.user, size: 14, color: _accentBlue),
      );

      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _accentBlue.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: _accentBlue.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: userUid == null
            ? fallback
            : FutureBuilder<DocumentSnapshot?>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userUid)
                    .get(),
                builder: (context, snap) {
                  if (!snap.hasData || !snap.data!.exists) return fallback;
                  final userData = snap.data!.data() as Map<String, dynamic>;
                  final pic = userData['profilePicURL'] as String?;
                  if (pic == null || pic.isEmpty) return fallback;
                  try {
                    final bytes = base64Decode(pic.split(',').last);
                    return Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => fallback,
                    );
                  } catch (_) {
                    return fallback;
                  }
                },
              ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: DraggableScrollableSheet(
                initialChildSize: 0.8,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.06),
                          height: 1,
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: getComments(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white54,
                                  ),
                                );
                              }
                              final docs = snapshot.data!.docs;
                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No comments yet',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                );
                              }
                              return ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  height: 1,
                                ),
                                itemBuilder: (context, i) {
                                  final doc = docs[i];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final userUid = data['userUid'] as String?;
                                  final isAnon =
                                      data['isAnon'] as bool? ?? false;

                                  final List<String> likes = List<String>.from(
                                    data['likes'] ?? [],
                                  );
                                  final List<String> dislikes =
                                      List<String>.from(data['dislikes'] ?? []);
                                  final bool hasLiked = likes.contains(
                                    currentUid,
                                  );
                                  final bool hasDisliked = dislikes.contains(
                                    currentUid,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        buildAvatar(isAnon ? null : userUid),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['createdBy'] ?? 'User',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                data['text'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 13,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),

                                              // ── Like / Dislike row ──
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => toggleLike(
                                                      doc.id,
                                                      likes,
                                                      dislikes,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        FaIcon(
                                                          hasLiked
                                                              ? FontAwesomeIcons
                                                                    .thumbsUp
                                                              : FontAwesomeIcons
                                                                    .thumbsUp,
                                                          size: 12,
                                                          color: hasLiked
                                                              ? _accentBlue
                                                              : Colors.white24,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${likes.length}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: hasLiked
                                                                ? _accentBlue
                                                                : Colors
                                                                      .white24,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  GestureDetector(
                                                    onTap: () => toggleDislike(
                                                      doc.id,
                                                      likes,
                                                      dislikes,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        FaIcon(
                                                          hasDisliked
                                                              ? FontAwesomeIcons
                                                                    .thumbsDown
                                                              : FontAwesomeIcons
                                                                    .thumbsDown,
                                                          size: 12,
                                                          color: hasDisliked
                                                              ? _accentOrange
                                                              : Colors.white24,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${dislikes.length}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: hasDisliked
                                                                ? _accentOrange
                                                                : Colors
                                                                      .white24,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: SafeArea(
                            top: false,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Write a comment...',
                                        hintStyle: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 14,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          borderSide: BorderSide(
                                            color: _accentBlue.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) =>
                                          addComment(setModalState),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _accentBlue.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _accentBlue.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: isSending
                                          ? null
                                          : () => addComment(setModalState),
                                      icon: isSending
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _accentBlue,
                                              ),
                                            )
                                          : const FaIcon(
                                              FontAwesomeIcons.paperPlane,
                                              color: _accentBlue,
                                              size: 15,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> data, int count, String topicId) {
    final isActive = count >= 10;
    final accentColor = isActive ? _accentGreen : _accentOrange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (count < 10) {
            _showInactiveSheet(data['title'] ?? 'Topic', topicId);
          } else {
            _openTopic(context, data, count, topicId);
          }
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.commentDots,
                  color: accentColor,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 1 ? '1 comment' : '$count comments',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _statusBadge(count),
            const SizedBox(width: 10),
            FaIcon(
              FontAwesomeIcons.angleRight,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
            FaIcon(FontAwesomeIcons.magnifyingGlass, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Search Topics',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accentBlue.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const FaIcon(
                FontAwesomeIcons.plus,
                color: _accentBlue,
                size: 14,
              ),
              onPressed: () => Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  opaque: false,
                  pageBuilder: (_, __, ___) => const AddTags(),
                  transitionsBuilder: (_, animation, __, child) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    );
                    return FadeTransition(opacity: curved, child: child);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // ── Search field ───────────────────────────────────────
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g., Deep Learning',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 10),
                  child: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: Colors.white38,
                    size: 15,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(),
                filled: true,
                fillColor: _surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _accentBlue.withValues(alpha: 0.5),
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                  _animateResults = true;
                });
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) setState(() => _animateResults = false);
                });
              },
            ),

            const SizedBox(height: 20),

            // ── Section label ──────────────────────────────────────
            const Text(
              'Topics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            // ── Results ────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: searchTags(query),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    );
                  }
                  final docs = snapshot.data!.docs.take(5).toList();
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.magnifyingGlass,
                                color: Colors.white24,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No topics found',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final count = data['commentNo'] ?? 0;
                      final card = _buildCard(data, count, docs[index].id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _animateResults
                            ? TweenAnimationBuilder(
                                duration: Duration(
                                  milliseconds: 350 + (index * 80),
                                ),
                                tween: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ),
                                builder: (context, offset, child) {
                                  return Transform.translate(
                                    offset: Offset(offset.dx * 300, 0),
                                    child: Opacity(
                                      opacity: 1 - offset.dx,
                                      child: child,
                                    ),
                                  );
                                },
                                child: card,
                              )
                            : card,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
