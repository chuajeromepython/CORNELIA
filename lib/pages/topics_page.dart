import 'package:firebase_ai/data_analysis_tools/bar.dart';
import 'package:firebase_ai/data_analysis_tools/choropleth.dart';
import 'package:firebase_ai/data_analysis_tools/controversy.dart';
import 'package:firebase_ai/data_analysis_tools/dead_internet.dart';
import 'package:firebase_ai/data_analysis_tools/donut.dart';
import 'package:firebase_ai/data_analysis_tools/emerging_issues.dart';
import 'package:firebase_ai/data_analysis_tools/exec_summary.dart';
import 'package:firebase_ai/data_analysis_tools/intertopic.dart';
import 'package:firebase_ai/data_analysis_tools/key_insights.dart';
import 'package:firebase_ai/data_analysis_tools/line.dart';
import 'package:firebase_ai/data_analysis_tools/line_emerging.dart';
import 'package:firebase_ai/data_analysis_tools/neg_outliers.dart';
import 'package:firebase_ai/data_analysis_tools/networkg.dart';
import 'package:firebase_ai/data_analysis_tools/sentiment_age.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_ai/data_analysis_tools/toxicity.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_ai/helper_functions/popup.dart';
import 'package:firebase_ai/helper_functions/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:intl/intl.dart';

class Topic extends StatefulWidget {
  final String title;
  final String topicId;
  final String author;
  final Map<String, dynamic> sentimentData;
  final List<dynamic> emotionData;
  final List<(String, String)> sentimentDataSOT;
  final List<Map<String, dynamic>> emergingTrends;
  final Map<String, dynamic> themesData;
  final List<Map<String, dynamic>> choroplethData;
  final Map<String, dynamic> networkData;
  final List<dynamic> heatmapdata;
  final String executiveSummary;
  final List<Map<String, dynamic>> keyInsights;
  final List<Map<String, dynamic>> emergingIssues;
  final List<Map<String, dynamic>> negativeOutliers;
  final List<Map<String, dynamic>> negativeOutlierAnalyses;
  final Map<String, dynamic> deadInternetTheory;

  const Topic({
    super.key,
    required this.title,
    required this.topicId,
    required this.author,
    required this.sentimentData,
    required this.emotionData,
    required this.sentimentDataSOT,
    required this.emergingTrends,
    required this.themesData,
    required this.choroplethData,
    required this.networkData,
    required this.heatmapdata,
    required this.executiveSummary,
    required this.keyInsights,
    required this.emergingIssues,
    required this.negativeOutliers,
    required this.negativeOutlierAnalyses,
    required this.deadInternetTheory,
  });

  @override
  State<Topic> createState() => _TopicState();
}

class _TopicState extends State<Topic> {
  final TextEditingController comment = TextEditingController();
  bool _isSending = false;
  bool _isRefreshing = false;

  // ── Favorite state ───────────────────────────────────────────────────────
  bool _isFav = false;
  bool _favLoading = true;

  // Mutable analytics state
  late Map<String, dynamic> _sentimentData;
  late List<dynamic> _emotionData;
  late List<(String, String)> _sentimentDataSOT;
  late List<Map<String, dynamic>> _emergingTrends;
  late Map<String, dynamic> _themesData;
  late List<Map<String, dynamic>> _choroplethData;
  late Map<String, dynamic> _networkData;
  late List<dynamic> _heatmapdata;
  late String _executiveSummary;
  late List<Map<String, dynamic>> _keyInsights;
  late List<Map<String, dynamic>> _emergingIssues;
  late List<Map<String, dynamic>> _negativeOutliers;
  late List<Map<String, dynamic>> _negativeOutlierAnalyses;
  late Map<String, dynamic> _deadInternetTheory;

  @override
  void initState() {
    super.initState();
    _sentimentData = widget.sentimentData;
    _emotionData = widget.emotionData;
    _sentimentDataSOT = widget.sentimentDataSOT;
    _emergingTrends = widget.emergingTrends;
    _themesData = widget.themesData;
    _choroplethData = widget.choroplethData;
    _networkData = widget.networkData;
    _heatmapdata = widget.heatmapdata;
    _executiveSummary = widget.executiveSummary;
    _keyInsights = widget.keyInsights;
    _emergingIssues = widget.emergingIssues;
    _negativeOutliers = widget.negativeOutliers;
    _negativeOutlierAnalyses = widget.negativeOutlierAnalyses;
    _deadInternetTheory = widget.deadInternetTheory;
    _checkFavorite();
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  // ── Favorites ────────────────────────────────────────────────────────────

  Future<void> _checkFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _favLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final raw = doc.data()?['favorites'] as List?;
      final isFav = raw?.any((e) => e['topicId'] == widget.topicId) ?? false;
      if (mounted)
        setState(() {
          _isFav = isFav;
          _favLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    if (_isFav) {
      setState(() => _isFav = false);
      try {
        final doc = await ref.get();
        final raw = List<Map<String, dynamic>>.from(
          ((doc.data()?['favorites'] as List?) ?? []).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
        raw.removeWhere((e) => e['topicId'] == widget.topicId);
        await ref.update({'favorites': raw});
        if (mounted) showSlidingToast(context, 'Removed from favorites');
      } catch (_) {
        if (mounted) setState(() => _isFav = true);
      }
    } else {
      setState(() => _isFav = true);
      try {
        final doc = await ref.get();
        final raw = List<Map<String, dynamic>>.from(
          ((doc.data()?['favorites'] as List?) ?? []).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
        if (!raw.any((e) => e['topicId'] == widget.topicId)) {
          raw.add({'topicId': widget.topicId, 'title': widget.title});
          await ref.update({'favorites': raw});
        }
        if (mounted) showSlidingToast(context, 'Added to favorites');
      } catch (_) {
        if (mounted) setState(() => _isFav = false);
      }
    }
  }

  // ── Analytics availability ───────────────────────────────────────────────

  bool get _hasAnalytics =>
      _sentimentData.isNotEmpty ||
      _emotionData.isNotEmpty ||
      _emergingTrends.isNotEmpty ||
      _themesData.isNotEmpty ||
      _choroplethData.isNotEmpty ||
      _networkData.isNotEmpty ||
      _heatmapdata.isNotEmpty ||
      _executiveSummary.isNotEmpty ||
      _keyInsights.isNotEmpty ||
      _emergingIssues.isNotEmpty ||
      _negativeOutliers.isNotEmpty ||
      _negativeOutlierAnalyses.isNotEmpty ||
      _deadInternetTheory.isNotEmpty ||
      _sentimentDataSOT.isNotEmpty;

  Widget _noDataPlaceholder(String label) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, color: Colors.white24, size: 28),
          const SizedBox(height: 8),
          Text(
            "$label will appear after analysis",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Comment fetch helpers ────────────────────────────────────────────────

  Future<List<String>> _fetchCommentTexts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()['text'] as String).toList();
  }

  Future<List<(String, String)>> _fetchCommentsWithDate() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final text = data['text'] as String;
      final timestamp = data['createdAt'] as Timestamp;
      final dateStr = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
      return (dateStr, text);
    }).toList();
  }

  Future<List<(String, String)>> _fetchCommentsWithDateInv() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final text = data['text'] as String;
      final timestamp = data['createdAt'] as Timestamp;
      final dateStr = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
      return (text, dateStr);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCommentsWithMeta() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();

    const Map<String, String> geoJsonFixes = {
      'United States': 'United States of America',
      'South Korea': 'Republic of Korea',
      'North Korea': 'Dem. Rep. Korea',
      'Czech Republic': 'Czechia',
      'Gibraltar': 'Gibraltar',
      'DR Congo': 'Dem. Rep. Congo',
      'Republic of the Congo': 'Congo',
      'Tanzania': 'United Rep. of Tanzania',
      'Syria': 'Syrian Arab Republic',
      'Laos': 'Lao PDR',
      'Vietnam': 'Viet Nam',
      'Ivory Coast': "Côte d'Ivoire",
      'Bosnia and Herzegovina': 'Bosnia and Herz.',
      'North Macedonia': 'Macedonia',
      'Dominican Republic': 'Dominican Rep.',
      'Central African Republic': 'Central African Rep.',
      'Equatorial Guinea': 'Eq. Guinea',
      'Western Sahara': 'W. Sahara',
      'Solomon Islands': 'Solomon Is.',
      'Falkland Islands': 'Falkland Is.',
      'East Timor': 'Timor-Leste',
      'Swaziland': 'eSwatini',
      'Cape Verde': 'Cabo Verde',
      'Myanmar': 'Myanmar',
      'Iran': 'Iran (Islamic Republic of)',
      'Moldova': 'Republic of Moldova',
      'Venezuela': 'Venezuela (Bolivarian Republic of)',
      'Bolivia': 'Bolivia (Plurinational State of)',
      'Brunei': 'Brunei Darussalam',
    };

    final List<Map<String, dynamic>> result = [];
    for (final doc in snapshot.docs) {
      final commentData = doc.data();
      final uid = commentData['userUid'] as String?;
      if (uid == null) continue;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) continue;
      final userData = userDoc.data()!;
      final rawCountry = userData['country'] ?? 'Unknown';
      String displayName = rawCountry;
      if (rawCountry.length == 2) {
        try {
          displayName = CountryParser.parseCountryCode(rawCountry).name;
        } catch (_) {
          displayName = rawCountry;
        }
      }
      final geoCountry = geoJsonFixes[displayName] ?? displayName;
      result.add({
        'text': commentData['text'] as String,
        'country': geoCountry,
        'gender': userData['gender'] ?? 'Unknown',
      });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchCommentsWithAge() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();
    final List<Map<String, dynamic>> result = [];
    for (final doc in snapshot.docs) {
      final commentData = doc.data();
      final uid = commentData['userUid'] as String?;
      if (uid == null) continue;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) continue;
      final userData = userDoc.data()!;
      result.add({
        'text': commentData['text'] as String,
        'age': userData["age"],
      });
    }
    return result;
  }

  // ── Flask AI calls ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _runRobertaSentiment(List<String> data) async {
    print("calling roberta-base");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/roberta-base-sentiment",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"data": data}),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return Map<String, dynamic>.from(jsonDecode(response.body)["results"]);
    }
    throw Exception("roberta-base-sentiment failed: ${response.statusCode}");
  }

  Future<List<dynamic>> _runRobertaGo(List<String> data) async {
    print("calling base go");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/roberta-base-go",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"data": data}),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return List<dynamic>.from(jsonDecode(response.body)["results"]);
    }
    throw Exception("roberta-base-go failed: ${response.statusCode}");
  }

  Future<Map<String, dynamic>> _runMiniLm(List<String> data) async {
    print("calling mini");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/all-MiniLM-L6-v2",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"data": data}),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return Map<String, dynamic>.from(jsonDecode(response.body)["results"]);
    }
    throw Exception("all-MiniLM-L6-v2 failed: ${response.statusCode}");
  }

  Future<List<(String, String)>> _runSentimentSOT(
    List<(String, String)> data,
  ) async {
    print("caling sentimentSOT");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/roberta-base-sentiment-SOT",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "data": data.map((e) => {"date": e.$1, "text": e.$2}).toList(),
          }),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return (jsonDecode(response.body)["results"] as List)
          .map((e) => (e["date"] as String, e["label"] as String))
          .toList();
    }
    throw Exception(
      "roberta-base-sentiment-SOT failed: ${response.statusCode}",
    );
  }

  Future<List<Map<String, dynamic>>> _runEmergingTrends(
    List<(String, String)> data,
  ) async {
    print("calling emerging trends");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/all-MiniLM-L6-v2-ETO",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "data": data.map((e) => {"text": e.$1, "date": e.$2}).toList(),
          }),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return (jsonDecode(response.body)["results"] as List)
          .map(
            (e) => {
              "time": e["time"] as String,
              "count": e["count"] as int,
              "keyword": e["keyword"] as String,
            },
          )
          .toList();
    }
    throw Exception("all-MiniLM-L6-v2-ETO failed: ${response.statusCode}");
  }

  Future<List<Map<String, dynamic>>> _runChoropleth(
    List<Map<String, dynamic>> data,
  ) async {
    print("calling sentimentCO");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/roberta-base-sentimentCO",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"data": data}),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return (jsonDecode(response.body)["results"] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    throw Exception("roberta-base-sentimentCO failed: ${response.statusCode}");
  }

  Future<Map<String, dynamic>> _runNetwork(List<String> data) async {
    print("Calling network");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/all-MiniLM-L6-v2-G",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"data": data}),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return Map<String, dynamic>.from(jsonDecode(response.body)["results"]);
    }
    throw Exception("all-MiniLM-L6-v2-G failed: ${response.statusCode}");
  }

  Future<List<dynamic>> _runCorrelation(List<Map<String, dynamic>> data) async {
    print("calling COR");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/all-MiniLM-L6-v2-COR",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"data": data}),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return List<dynamic>.from(jsonDecode(response.body)["results"]);
    }
    throw Exception("all-MiniLM-L6-v2-COR failed: ${response.statusCode}");
  }

  Future<List<Map<String, dynamic>>> _runNegativeOutliers(
    List<String> data,
  ) async {
    print("calling outliers");
    final response = await http
        .post(
          Uri.parse(
            "https://chuajeromeflutterfirebase-flutterapp.hf.space/roberta-base-sentiment-SCORES",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"data": data}),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode == 200) {
      print("DONE");
      return (jsonDecode(response.body)["results"] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    throw Exception(
      "roberta-base-sentiment-SCORES failed: ${response.statusCode}",
    );
  }

  // ── Gemini ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _generateGeminiResponse(
    List<String> texts,
  ) async {
    try {
      final sampledComments = (texts.toList()..shuffle()).take(15).toList();
      final highScoreOutliers = _negativeOutliers
          .where((c) => (c['score'] as num).toDouble() >= 0.90)
          .toList();

      final prompt =
          '''
You are an expert comment section analyst. Return ONLY a valid JSON object, no markdown, no backticks, no explanation.

JSON structure:
{
  "executive_summary": "<1 paragraph, \\n\\n separated, plain prose>",
  "key_insights": [
    { "label": "Dominant Sentiment", "body": "<2 sentences>" },
    { "label": "Rising Concern", "body": "<2 sentences>" },
    { "label": "Geographic Signal", "body": "<2 sentences>" },
    { "label": "Alert", "body": "<2 sentences>" }
  ],
  "emerging_issues": [
    { "label": "<title-cased keyword>", "count": <integer>, "percentage": <double>, "summary": "<1-2 sentences>" },
    { "label": "<title-cased keyword>", "count": <integer>, "percentage": <double>, "summary": "<1-2 sentences>" },
    { "label": "<title-cased keyword>", "count": <integer>, "percentage": <double>, "summary": "<1-2 sentences>" },
    { "label": "<title-cased keyword>", "count": <integer>, "percentage": <double>, "summary": "<1-2 sentences>" },
    { "label": "<title-cased keyword>", "count": <integer>, "percentage": <double>, "summary": "<1-2 sentences>" }
  ],
  "negative_outlier_analyses": [
    { "id": <integer>, "analysis": "<2-3 sentences>" }
  ],
  "dead_internet_theory": {
    "repetitive_phrasing_rate": "<e.g. '23%'>",
    "coordinated_clusters": <integer>,
    "avg_outlier_score": "<e.g. '0.91'>",
    "narrative": "<2 paragraphs, \\n\\n separated, plain prose>"
  }
}

RULES:
- executive_summary: 1 paragraph, 3-5 sentences, plain prose
- key_insights: exactly 4, distinct labels, 2-sentence body each
- emerging_issues: STRICTLY from EMERGING TRENDS, no invented keywords; sum count per keyword across all dates; percentage=(count/total)*100 to 1 decimal; top 5 by count descending, min 4; summary derived from keyword and surrounding trend data
- negative_outlier_analyses: STRICTLY from NEGATIVE OUTLIER COMMENTS below, score>=0.90 only; include ALL qualifying; analysis covers hyperbolic language/hostility/coordinated phrasing/frustration; [] if none
- dead_internet_theory: from ALL data; repetitive_phrasing_rate=% of near-identical phrasing as string; coordinated_clusters=count of clusters with uniform sentiment as integer; avg_outlier_score=mean score of outliers>=0.90 to 2 decimals as string, "0.00" if none; narrative=2 paragraphs balanced authenticity analysis
- No extra fields, no markdown, no formatting outside JSON
- Insufficient data: executive_summary/narrative as plain explanation, all arrays=[], counts=0, percentages=0.0, scores="0.00", rates="0%"

--- SENTIMENT ---
${jsonEncode(_sentimentData)}

--- EMOTIONS ---
${jsonEncode(_emotionData)}

--- THEMES ---
${jsonEncode(_themesData)}

--- SENTIMENT OVER TIME ---
${jsonEncode(_sentimentDataSOT.take(20).map((e) => {"date": e.$1, "label": e.$2}).toList())}

--- EMERGING TRENDS ---
${jsonEncode(_emergingTrends)}

--- GEOGRAPHIC ---
${jsonEncode(_choroplethData.take(10).toList())}

--- AGE SENTIMENT ---
${jsonEncode(_heatmapdata.map((e) => {'ageGroup': e['ageGroup'], 'dominantSentiment': e['dominantSentiment'], 'sentimentBreakdown': e['sentimentBreakdown']}).toList())}

--- KEYWORDS ---
${jsonEncode({'nodes': (_networkData['nodes'] as List? ?? []).take(10).toList(), 'edges': (_networkData['edges'] as List? ?? []).take(15).toList()})}

--- NEGATIVE OUTLIER SCORES ---
${jsonEncode(highScoreOutliers)}

--- NEGATIVE OUTLIER COMMENTS ---
${highScoreOutliers.map((c) => '- [id: ${c['id']}] ${c['text']}').join('\n')}

--- SAMPLE COMMENTS ---
${sampledComments.map((t) => '- $t').join('\n')}
''';
      final response = await Gemini.instance.prompt(parts: [Part.text(prompt)]);
      final raw = response?.output ?? '';
      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } on GeminiException catch (e) {
      if (mounted) showSlidingToast(context, 'Gemini error: $e');
      return {};
    } catch (e) {
      if (mounted)
        showSlidingToast(context, 'Failed to parse Gemini response: $e');
      return {};
    }
  }

  Future<void> _wakeSpace() async {
    print("Waking up Spaces");
    const maxAttempts = 10;
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final res = await http
            .get(
              Uri.parse(
                "https://chuajeromeflutterfirebase-flutterapp.hf.space/health",
              ),
            )
            .timeout(const Duration(seconds: 30));
        if (res.statusCode == 200) {
          print("Space is awake after ${i + 1} attempt(s)");
          return;
        }
      } catch (_) {
        print("Attempt ${i + 1} failed, retrying...");
      }
      await Future.delayed(const Duration(seconds: 10));
    }
    print("Space may not be fully ready, proceeding anyway");
  }

  // ── Pull-to-refresh ──────────────────────────────────────────────────────

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    await _wakeSpace();

    try {
      final texts = await _fetchCommentTexts();
      final withDates = await _fetchCommentsWithDate();
      final withDatesInv = await _fetchCommentsWithDateInv();
      final commentsWithRegion = await _fetchCommentsWithMeta();
      final commentsWithAge = await _fetchCommentsWithAge();

      final freshSentiment = await _runRobertaSentiment(texts);
      print("1/9 done");
      final freshEmotion = await _runRobertaGo(texts);
      print("2/9 done");
      final freshThemes = await _runMiniLm(texts);
      print("3/9 done");
      final freshSOT = await _runSentimentSOT(withDates);
      print("4/9 done");
      final freshTrends = await _runEmergingTrends(withDatesInv);
      print("5/9 done");
      final freshChoropleth = await _runChoropleth(commentsWithRegion);
      print("6/9 done");
      final freshNetwork = await _runNetwork(texts);
      print("7/9 done");
      final freshHeatmap = await _runCorrelation(commentsWithAge);
      print("8/9 done");
      final freshNegativeOutliers = await _runNegativeOutliers(texts);
      print("9/9 done");

      if (!mounted) return;
      setState(() {
        _sentimentData = freshSentiment;
        _emotionData = freshEmotion;
        _themesData = freshThemes;
        _sentimentDataSOT = freshSOT;
        _emergingTrends = freshTrends;
        _choroplethData = freshChoropleth;
        _networkData = freshNetwork;
        _heatmapdata = freshHeatmap;
        _negativeOutliers = freshNegativeOutliers;
      });

      final gemini = await _generateGeminiResponse(texts);

      if (gemini.isNotEmpty && mounted) {
        setState(() {
          _executiveSummary = gemini['executive_summary'] as String? ?? '';
          _keyInsights = List<Map<String, dynamic>>.from(
            (gemini['key_insights'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
          _emergingIssues = List<Map<String, dynamic>>.from(
            (gemini['emerging_issues'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
          _negativeOutlierAnalyses = List<Map<String, dynamic>>.from(
            (gemini['negative_outlier_analyses'] as List? ?? []).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
          _deadInternetTheory = Map<String, dynamic>.from(
            gemini['dead_internet_theory'] as Map? ?? {},
          );
        });
      }

      final sotForFirestore = freshSOT
          .map((e) => {"date": e.$1, "label": e.$2})
          .toList();

      FirebaseFirestore.instance
          .collection('topics')
          .doc(widget.topicId)
          .collection('analytics')
          .doc('latest')
          .set({
            'sentiment_dist': freshSentiment,
            'emotion_dist': freshEmotion,
            'themes_dist': freshThemes,
            'sentimentSOT_dist': sotForFirestore,
            'emergingTrends_dist': freshTrends,
            'choropleth_data': freshChoropleth,
            'network_connections': freshNetwork,
            'correlation_data': freshHeatmap,
            'negative_outliers': freshNegativeOutliers,
            'executive_summary': gemini['executive_summary'] ?? '',
            'key_insights': gemini['key_insights'] ?? [],
            'emerging_issues': gemini['emerging_issues'] ?? [],
            'negative_outlier_analyses':
                gemini['negative_outlier_analyses'] ?? [],
            'dead_internet_theory': gemini['dead_internet_theory'] ?? {},
            'updatedAt': FieldValue.serverTimestamp(),
            'lastAnalyzedCommentCount': texts.length,
          }, SetOptions(merge: true));

      if (!mounted) return;
      showSlidingToast(context, "Analytics updated!");
    } catch (e) {
      if (!mounted) return;
      showSlidingToast(context, "Refresh failed: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // ── Comments ─────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> _getComments() {
    return FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addComment() async {
    if (_isSending) return;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user!.uid;
    final cmt = comment.text.trim();
    if (cmt.isEmpty) {
      if (!mounted) return;
      showSlidingToast(context, "Your comment is empty.");
      return;
    }
    setState(() => _isSending = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() as Map<String, dynamic>;
      await FirebaseFirestore.instance
          .collection('topics')
          .doc(widget.topicId)
          .collection('comments')
          .add({
            'text': cmt,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': data["username"],
            'userUid': uid,
            'likes': [],
            'dislikes': [],
          });
      await FirebaseFirestore.instance
          .collection('topics')
          .doc(widget.topicId)
          .update({'commentNo': FieldValue.increment(1)});
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'commentsMade': FieldValue.increment(1),
      });
      comment.clear();
      if (!mounted) return;
      showSlidingToast(context, "Comment added");
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showPopUp(context, e.message.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Like / Dislike ────────────────────────────────────────────────────────

  Future<void> _toggleLike(
    String commentId,
    List<String> likes,
    List<String> dislikes,
  ) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
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

  Future<void> _toggleDislike(
    String commentId,
    List<String> likes,
    List<String> dislikes,
  ) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
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

  void _openCommentsSheet() {
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 23, 23, 30),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _getComments(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No comments yet",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            }
                            final comments = snapshot.data!.docs;
                            final currentUid =
                                FirebaseAuth.instance.currentUser?.uid ?? '';

                            return ListView.builder(
                              controller: controller,
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final doc = comments[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final userUid = data['userUid'] as String?;
                                final List<String> likes = List<String>.from(
                                  data['likes'] ?? [],
                                );
                                final List<String> dislikes = List<String>.from(
                                  data['dislikes'] ?? [],
                                );
                                final bool hasLiked = likes.contains(
                                  currentUid,
                                );
                                final bool hasDisliked = dislikes.contains(
                                  currentUid,
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      userUid == null
                                          ? const CircleAvatar(
                                              radius: 18,
                                              child: Icon(
                                                Icons.person,
                                                size: 18,
                                              ),
                                            )
                                          : FutureBuilder<DocumentSnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(userUid)
                                                  .get(),
                                              builder: (context, snap) {
                                                String? pic;
                                                if (snap.hasData &&
                                                    snap.data!.exists) {
                                                  final u =
                                                      snap.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final p =
                                                      u['profilePicURL']
                                                          as String?;
                                                  if (p != null && p.isNotEmpty)
                                                    pic = p;
                                                }
                                                if (pic != null) {
                                                  try {
                                                    final bytes = base64Decode(
                                                      pic.split(',').last,
                                                    );
                                                    return CircleAvatar(
                                                      radius: 18,
                                                      backgroundImage:
                                                          MemoryImage(bytes),
                                                    );
                                                  } catch (_) {}
                                                }
                                                return const CircleAvatar(
                                                  radius: 18,
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 18,
                                                  ),
                                                );
                                              },
                                            ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['createdBy'] ?? "User",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              data['text'] ?? "",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _toggleLike(
                                                    doc.id,
                                                    likes,
                                                    dislikes,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        hasLiked
                                                            ? Icons.thumb_up
                                                            : Icons
                                                                  .thumb_up_outlined,
                                                        size: 16,
                                                        color: hasLiked
                                                            ? Colors.blueAccent
                                                            : Colors.white38,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${likes.length}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: hasLiked
                                                              ? Colors
                                                                    .blueAccent
                                                              : Colors.white38,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                GestureDetector(
                                                  onTap: () => _toggleDislike(
                                                    doc.id,
                                                    likes,
                                                    dislikes,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        hasDisliked
                                                            ? Icons.thumb_down
                                                            : Icons
                                                                  .thumb_down_outlined,
                                                        size: 16,
                                                        color: hasDisliked
                                                            ? Colors.redAccent
                                                            : Colors.white38,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${dislikes.length}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: hasDisliked
                                                              ? Colors.redAccent
                                                              : Colors.white38,
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: comment,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: "Write a comment...",
                                      hintStyle: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF2A2A2A),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(25),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) async {
                                      if (isSending) return;
                                      setModalState(() => isSending = true);
                                      await addComment();
                                      if (context.mounted) {
                                        setModalState(() => isSending = false);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: isSending
                                      ? null
                                      : () async {
                                          setModalState(() => isSending = true);
                                          await addComment();
                                          if (context.mounted) {
                                            setModalState(
                                              () => isSending = false,
                                            );
                                          }
                                        },
                                  icon: isSending
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send,
                                          color: Colors.white,
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
            );
          },
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 23, 23, 30),
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.angleLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MarqueeText(
              text: "${widget.title} — Insights",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "Pull down to refresh analytics",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // ── Favorite heart ───────────────────────────────────
          if (_favLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white38,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isFav ? Icons.favorite : Icons.favorite_border,
                color: _isFav ? Colors.pinkAccent : Colors.white54,
              ),
              tooltip: _isFav ? 'Remove from favorites' : 'Add to favorites',
              onPressed: _toggleFavorite,
            ),

          // ── Refresh ──────────────────────────────────────────
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _onRefresh,
              tooltip: "Re-run AI analysis",
            ),

          // ── Comments ─────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.comment, color: Colors.white),
            onPressed: _openCommentsSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.white,
        backgroundColor: const Color(0xFF1E1E2E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_hasAnalytics)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 16, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "No analytics yet. Pull down or tap ↻ to run the AI analysis.",
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isRefreshing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Running AI models… this may take a moment",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),

              const Text(
                "Summary",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 20),
              _executiveSummary.isEmpty
                  ? _noDataPlaceholder("Executive Summary")
                  : ExecutiveSummaryCard(
                      key: ValueKey(_executiveSummary.hashCode),
                      executiveSummary: _executiveSummary,
                    ),
              const SizedBox(height: 20),
              _keyInsights.isEmpty
                  ? _noDataPlaceholder("Key Insights")
                  : KeyInsightsCard(
                      key: ValueKey(_keyInsights.hashCode),
                      insights: _keyInsights,
                    ),

              const SizedBox(height: 20),
              const Text(
                "Discussion Breakdown",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 20),
              _themesData.isEmpty
                  ? _noDataPlaceholder("Intertopic Distance Map")
                  : SizedBox(
                      height: 450,
                      width: 450,
                      child: IntertopicDistanceMap(
                        key: ValueKey(_themesData.hashCode),
                        themesData: _themesData,
                      ),
                    ),
              const SizedBox(height: 20),
              _sentimentData.isEmpty
                  ? _noDataPlaceholder("Sentiment Distribution")
                  : SyncfusionDonutMini(
                      key: ValueKey(_sentimentData.hashCode),
                      data: _sentimentData,
                    ),
              const SizedBox(height: 20),
              _emotionData.isEmpty
                  ? _noDataPlaceholder("Emotion Distribution")
                  : SyncfusionBarPlot(
                      key: ValueKey(_emotionData.hashCode),
                      data: _emotionData,
                    ),
              const SizedBox(height: 20),
              _emergingIssues.isEmpty
                  ? _noDataPlaceholder("Emerging Issues")
                  : EmergingIssuesChart(
                      key: ValueKey(_emergingIssues.hashCode),
                      data: _emergingIssues,
                    ),
              const SizedBox(height: 20),
              _networkData.isEmpty
                  ? _noDataPlaceholder("Keyword Relationships")
                  : SizedBox(
                      height: 400,
                      width: 400,
                      child: KeywordGraphChart(
                        key: ValueKey(_networkData.hashCode),
                        networkData: _networkData,
                      ),
                    ),

              const SizedBox(height: 20),
              const Text(
                "Time Series Analysis",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 20),
              _sentimentDataSOT.isEmpty
                  ? _noDataPlaceholder("Sentiment Over Time")
                  : SizedBox(
                      height: 350,
                      child: SentimentOverTimeChart(
                        key: ValueKey(_sentimentDataSOT.hashCode),
                        data: _sentimentDataSOT,
                      ),
                    ),
              const SizedBox(height: 20),
              _emergingTrends.isEmpty
                  ? _noDataPlaceholder("Emerging Trends Over Time")
                  : SizedBox(
                      height: 350,
                      child: EmergingTrendsChart(
                        key: ValueKey(_emergingTrends.hashCode),
                        data: _emergingTrends,
                      ),
                    ),

              const SizedBox(height: 20),
              const Text(
                "Demographics",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 20),
              _choroplethData.isEmpty
                  ? _noDataPlaceholder("Comments Origin")
                  : SizedBox(
                      height: 400,
                      width: 400,
                      child: ChoroplethMap(
                        key: ValueKey(_choroplethData.hashCode),
                        choroplethData: _choroplethData,
                      ),
                    ),
              const SizedBox(height: 20),
              _heatmapdata.isEmpty
                  ? _noDataPlaceholder("Age Group × Aspect Sentiment")
                  : SentimentHeatMap(
                      key: ValueKey(_heatmapdata.hashCode),
                      data: _heatmapdata,
                    ),

              const SizedBox(height: 20),
              const Text(
                "Deep Insights",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 20),
              _negativeOutliers.isEmpty && _negativeOutlierAnalyses.isEmpty
                  ? _noDataPlaceholder("Negative Outliers")
                  : NegativeOutliersChart(
                      key: ValueKey(
                        _negativeOutliers.hashCode ^
                            _negativeOutlierAnalyses.hashCode,
                      ),
                      data: _negativeOutliers,
                      analyses: _negativeOutlierAnalyses,
                    ),
              const SizedBox(height: 20),
              _deadInternetTheory.isEmpty
                  ? _noDataPlaceholder("Dead Internet Theory")
                  : DeadInternetTheoryCard(
                      key: ValueKey(_deadInternetTheory.hashCode),
                      data: _deadInternetTheory,
                    ),
              const SizedBox(height: 20),
              _sentimentData.isEmpty && _emotionData.isEmpty
                  ? _noDataPlaceholder("Toxicity Level")
                  : ToxicityGauge(
                      key: ValueKey(
                        'toxicity_${_sentimentData.hashCode ^ _emotionData.hashCode}',
                      ),
                      sentimentData: _sentimentData,
                      emotionData: _emotionData,
                    ),
              const SizedBox(height: 20),
              _sentimentData.isEmpty
                  ? _noDataPlaceholder("Controversy Index")
                  : ControversyIndexWidget(
                      key: ValueKey('controversy_${_sentimentData.hashCode}'),
                      positive:
                          (_sentimentData['positive'] as num?)?.toDouble() ??
                          0.0,
                      neutral:
                          (_sentimentData['neutral'] as num?)?.toDouble() ??
                          0.0,
                      negative:
                          (_sentimentData['negative'] as num?)?.toDouble() ??
                          0.0,
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  Future<void> _startScrolling() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    while (mounted) {
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 30).toInt()),
        curve: Curves.linear,
      );
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style),
    );
  }
}
