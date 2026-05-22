import 'dart:async';
import 'dart:convert';
import 'package:firebase_ai/helper_functions/toast.dart';
import 'package:firebase_ai/pages/topics_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() => _Analytics();
}

class _Analytics extends State<Analytics> {
  final user = FirebaseAuth.instance.currentUser!;

  static const _surface = Color(0xFF1E1E2E);

  bool _isLoading = true;

  String fullname = '';
  int topicsMade = 0;
  int commentsMade = 0;
  int topicsCommentedOn = 0;
  String mostActiveDay = '—';
  String joinedDate = '—';
  String? profilePicURL;

  List<Map<String, dynamic>> _favorites = [];

  final List<_Badge> _allBadges = [
    _Badge(
      icon: FontAwesomeIcons.commentDots,
      label: 'First Comment',
      description: 'Left your first comment',
      color: Color(0xFF4FC3F7),
      threshold: 1,
      field: 'commentsMade',
    ),
    _Badge(
      icon: FontAwesomeIcons.fire,
      label: 'Active Voice',
      description: 'Made 10 comments',
      color: Color(0xFFFFB74D),
      threshold: 10,
      field: 'commentsMade',
    ),
    _Badge(
      icon: FontAwesomeIcons.solidStar,
      label: 'Power User',
      description: 'Made 50 comments',
      color: Color(0xFFBA68C8),
      threshold: 50,
      field: 'commentsMade',
    ),
    _Badge(
      icon: FontAwesomeIcons.lightbulb,
      label: 'Topic Starter',
      description: 'Created your first topic',
      color: Color(0xFF81C784),
      threshold: 1,
      field: 'topicsMade',
    ),
    _Badge(
      icon: FontAwesomeIcons.earthAsia,
      label: 'Community Builder',
      description: 'Created 5 topics',
      color: Color(0xFFE57373),
      threshold: 5,
      field: 'topicsMade',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Favorites — loaded as part of _loadData, no separate spinner ────────

  void _parseFavoritesFromDoc(Map<String, dynamic> data) {
    final raw = data['favorites'];
    _favorites = raw == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
          );
  }

  Future<void> _navigateToTopicAnalytics(
    BuildContext ctx,
    String topicId,
    String title,
  ) async {
    final results = await Future.wait([
      FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('analytics')
          .doc('latest')
          .get(),
      FirebaseFirestore.instance.collection('topics').doc(topicId).get(),
    ]);

    if (!ctx.mounted) return;

    final aData =
        (results[0] as DocumentSnapshot).data() as Map<String, dynamic>? ?? {};
    final tData =
        (results[1] as DocumentSnapshot).data() as Map<String, dynamic>? ?? {};

    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => Topic(
          title: title,
          topicId: topicId,
          author: tData['author'] as String? ?? '',
          sentimentData: Map<String, dynamic>.from(
            aData['sentiment_dist'] ?? {},
          ),
          emotionData: List<dynamic>.from(aData['emotion_dist'] ?? []),
          sentimentDataSOT: (aData['sentimentSOT_dist'] as List? ?? [])
              .map((e) => (e['date'] as String, e['label'] as String))
              .toList(),
          emergingTrends: List<Map<String, dynamic>>.from(
            (aData['emergingTrends_dist'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          themesData: Map<String, dynamic>.from(aData['themes_dist'] ?? {}),
          choroplethData: List<Map<String, dynamic>>.from(
            (aData['choropleth_data'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          networkData: Map<String, dynamic>.from(
            aData['network_connections'] ?? {},
          ),
          heatmapdata: List<dynamic>.from(aData['correlation_data'] ?? []),
          executiveSummary: aData['executive_summary'] as String? ?? '',
          keyInsights: List<Map<String, dynamic>>.from(
            (aData['key_insights'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          emergingIssues: List<Map<String, dynamic>>.from(
            (aData['emerging_issues'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          negativeOutliers: List<Map<String, dynamic>>.from(
            (aData['negative_outliers'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          negativeOutlierAnalyses: List<Map<String, dynamic>>.from(
            (aData['negative_outlier_analyses'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          ),
          deadInternetTheory: Map<String, dynamic>.from(
            aData['dead_internet_theory'] ?? {},
          ),
        ),
      ),
    );
  }

  // ── Profile / stats ──────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final createdAt = data['createdAt'] as Timestamp?;
        final pic = data['profilePicURL'] as String?;
        if (!mounted) return;
        setState(() {
          fullname = data['fullname'] ?? 'User';
          topicsMade = data['topicsMade'] ?? 0;
          commentsMade = data['commentsMade'] ?? 0;
          topicsCommentedOn = data['viewedTopics'] ?? 0;
          joinedDate = createdAt != null
              ? DateFormat('MMM yyyy').format(createdAt.toDate())
              : '—';
          profilePicURL = (pic != null && pic.isNotEmpty) ? pic : null;
          _parseFavoritesFromDoc(data);
        });
      }
    } catch (e) {
      if (!mounted) return;
      showSlidingToast(context, 'Failed to load profile: $e');
    }

    try {
      final commentedTopics = await FirebaseFirestore.instance
          .collectionGroup('comments')
          .where('userUid', isEqualTo: user.uid)
          .get();

      final dayCount = <String, int>{};
      for (final doc in commentedTopics.docs) {
        final ts = doc.data()['createdAt'] as Timestamp?;
        if (ts != null) {
          final day = DateFormat('EEEE').format(ts.toDate());
          dayCount[day] = (dayCount[day] ?? 0) + 1;
        }
      }

      final activeDay = dayCount.entries.isEmpty
          ? '—'
          : (dayCount.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;

      if (!mounted) return;
      setState(() => mostActiveDay = activeDay);
    } catch (e) {
      debugPrint('collectionGroup error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 23, 23, 30),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 23, 23, 30),
        elevation: 0,
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.chartLine, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
        },
        color: Colors.white,
        backgroundColor: _surface,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile header ──────────────────────────
                    _ProfileHeader(
                      fullname: fullname,
                      joinedDate: joinedDate,
                      email: user.email ?? '',
                      profilePicURL: profilePicURL,
                    ),
                    const SizedBox(height: 20),

                    // ── Favorites ───────────────────────────────
                    _FavoritesSection(
                      favorites: _favorites,
                      onNavigate: (topicId, title) =>
                          _navigateToTopicAnalytics(context, topicId, title),
                    ),

                    // ── Primary stats ───────────────────────────
                    const _SectionLabel('Activity Overview'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: FontAwesomeIcons.commentDots,
                            label: 'Comments',
                            value: commentsMade.toString(),
                            color: const Color(0xFF4FC3F7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: FontAwesomeIcons.lightbulb,
                            label: 'Topics Created',
                            value: topicsMade.toString(),
                            color: const Color(0xFF81C784),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: FontAwesomeIcons.earthAsia,
                            label: 'Topics Joined',
                            value: topicsCommentedOn == 0
                                ? '—'
                                : topicsCommentedOn.toString(),
                            color: const Color(0xFFFFB74D),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: FontAwesomeIcons.calendarDay,
                            label: 'Most Active',
                            value: mostActiveDay,
                            color: const Color(0xFFBA68C8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Engagement score ────────────────────────
                    const _SectionLabel('Engagement Score'),
                    const SizedBox(height: 10),
                    _EngagementScore(
                      commentsMade: commentsMade,
                      topicsMade: topicsMade,
                      topicsCommentedOn: topicsCommentedOn,
                    ),

                    const SizedBox(height: 20),

                    // ── Badges ──────────────────────────────────
                    const _SectionLabel('Achievements'),
                    const SizedBox(height: 10),
                    _BadgesGrid(
                      badges: _allBadges,
                      commentsMade: commentsMade,
                      topicsMade: topicsMade,
                    ),

                    const SizedBox(height: 20),

                    // ── Tips ────────────────────────────────────
                    const _SectionLabel('Tips'),
                    const SizedBox(height: 10),
                    _TipsCard(
                      commentsMade: commentsMade,
                      topicsMade: topicsMade,
                      topicsCommentedOn: topicsCommentedOn,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Favorites Section ─────────────────────────────────────────────────────────

class _FavoritesSection extends StatefulWidget {
  final List<Map<String, dynamic>> favorites;
  final Future<void> Function(String topicId, String title) onNavigate;

  const _FavoritesSection({required this.favorites, required this.onNavigate});

  @override
  State<_FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends State<_FavoritesSection> {
  final PageController _pageController = PageController(viewportFraction: 0.80);
  Timer? _timer;
  int _currentPage = 0;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(_FavoritesSection old) {
    super.didUpdateWidget(old);
    if (old.favorites != widget.favorites) {
      _timer?.cancel();
      if (widget.favorites.length > 1) _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || widget.favorites.isEmpty) return;
      final max = widget.favorites.length.clamp(0, 5);
      final next = (_currentPage + 1) % max;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _go(String topicId, String title) async {
    _timer?.cancel();
    await widget.onNavigate(topicId, title);
    if (mounted && widget.favorites.length > 1) _startAutoScroll();
  }

  Widget _carouselCard(Map<String, dynamic> fav) {
    final topicId = fav['topicId'] as String;
    final title = fav['title'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1117),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.28)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.pinkAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.solidHeart,
                      color: Colors.pinkAccent,
                      size: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _go(topicId, title),
                icon: const FaIcon(FontAwesomeIcons.chartLine, size: 12),
                label: const Text(
                  'Go to Analytics Page',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent.withValues(alpha: 0.18),
                  foregroundColor: Colors.pinkAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Colors.pinkAccent.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listRow(Map<String, dynamic> fav, int index) {
    final topicId = fav['topicId'] as String;
    final title = fav['title'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ListTile(
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.pinkAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        trailing: TextButton.icon(
          onPressed: () => _go(topicId, title),
          icon: const FaIcon(
            FontAwesomeIcons.chartLine,
            size: 11,
            color: Colors.pinkAccent,
          ),
          label: const Text(
            'Analytics',
            style: TextStyle(fontSize: 11, color: Colors.pinkAccent),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Empty state ────────────────────────────────────────────────────────
    if (widget.favorites.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.solidHeart,
              size: 14,
              color: Colors.pinkAccent.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No favorites yet. Tap ♥ on a topic to save it here.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final carouselItems = widget.favorites.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.solidHeart,
              color: Colors.pinkAccent,
              size: 14,
            ),
            const SizedBox(width: 8),
            const Text(
              'Favorites',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.favorites.length} saved',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Carousel ─────────────────────────────────────────────────────
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: carouselItems.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _carouselCard(carouselItems[i]),
          ),
        ),

        // ── Dot indicators ────────────────────────────────────────────────
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(carouselItems.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? Colors.pinkAccent
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),

        // ── View full list toggle ─────────────────────────────────────────
        if (widget.favorites.length > 1) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.list,
                    size: 11,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _expanded
                        ? 'Hide full list'
                        : 'View all ${widget.favorites.length} favorites',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: List.generate(
                  widget.favorites.length,
                  (i) => _listRow(widget.favorites[i], i),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String fullname;
  final String joinedDate;
  final String email;
  final String? profilePicURL;

  const _ProfileHeader({
    required this.fullname,
    required this.joinedDate,
    required this.email,
    required this.profilePicURL,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (profilePicURL != null) {
      try {
        final bytes = base64Decode(profilePicURL!.split(',').last);
        avatar = CircleAvatar(radius: 28, backgroundImage: MemoryImage(bytes));
      } catch (_) {
        avatar = _defaultAvatar();
      }
    } else {
      avatar = _defaultAvatar();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  'Member since $joinedDate',
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
        ),
      ),
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.user,
          color: Color(0xFF4FC3F7),
          size: 22,
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(child: FaIcon(icon, color: color, size: 14)),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Engagement Score ──────────────────────────────────────────────────────────

class _EngagementScore extends StatelessWidget {
  final int commentsMade;
  final int topicsMade;
  final int topicsCommentedOn;

  const _EngagementScore({
    required this.commentsMade,
    required this.topicsMade,
    required this.topicsCommentedOn,
  });

  double get _score {
    final raw = (commentsMade * 2) + (topicsMade * 5) + (topicsCommentedOn * 3);
    return (raw / 200 * 100).clamp(0, 100);
  }

  String get _tier {
    if (_score >= 80) return 'Elite';
    if (_score >= 60) return 'Advanced';
    if (_score >= 40) return 'Intermediate';
    if (_score >= 20) return 'Rising';
    return 'Newcomer';
  }

  Color get _tierColor {
    if (_score >= 80) return const Color(0xFFBA68C8);
    if (_score >= 60) return const Color(0xFFFFB74D);
    if (_score >= 40) return const Color(0xFF4FC3F7);
    if (_score >= 20) return const Color(0xFF81C784);
    return Colors.white38;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tierColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _tier,
                style: TextStyle(
                  color: _tierColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${_score.toStringAsFixed(0)} / 100',
                style: TextStyle(
                  color: _tierColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _score / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(_tierColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Score is based on your comments, topics created, and topics joined.',
            style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class _Badge {
  final FaIconData icon;
  final String label;
  final String description;
  final Color color;
  final int threshold;
  final String field;

  const _Badge({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.threshold,
    required this.field,
  });
}

class _BadgesGrid extends StatelessWidget {
  final List<_Badge> badges;
  final int commentsMade;
  final int topicsMade;

  const _BadgesGrid({
    required this.badges,
    required this.commentsMade,
    required this.topicsMade,
  });

  bool _isUnlocked(_Badge badge) {
    final value = badge.field == 'commentsMade' ? commentsMade : topicsMade;
    return value >= badge.threshold;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: badges.map((badge) {
          final unlocked = _isUnlocked(badge);
          return Tooltip(
            message: badge.description,
            waitDuration: Duration.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: unlocked
                    ? badge.color.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: unlocked
                      ? badge.color.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    badge.icon,
                    size: 12,
                    color: unlocked ? badge.color : Colors.white24,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    badge.label,
                    style: TextStyle(
                      color: unlocked ? badge.color : Colors.white24,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(width: 6),
                    const FaIcon(
                      FontAwesomeIcons.lock,
                      size: 9,
                      color: Colors.white24,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Tips Card ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  final int commentsMade;
  final int topicsMade;
  final int topicsCommentedOn;

  const _TipsCard({
    required this.commentsMade,
    required this.topicsMade,
    required this.topicsCommentedOn,
  });

  List<String> get _tips {
    final tips = <String>[];
    if (commentsMade == 0) {
      tips.add('Leave your first comment to start building your profile.');
    }
    if (topicsMade == 0) {
      tips.add('Create a topic to start a discussion and gather insights.');
    }
    if (commentsMade > 0 && commentsMade < 10) {
      tips.add(
        'You need ${10 - commentsMade} more comments to unlock the Active Voice badge.',
      );
    }
    if (topicsCommentedOn < 3) {
      tips.add('Try joining more discussions to boost your engagement score.');
    }
    if (tips.isEmpty) {
      tips.add("You're doing great! Keep engaging with the community.");
    }
    return tips;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 11,
                  color: Color(0xFF4FC3F7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
