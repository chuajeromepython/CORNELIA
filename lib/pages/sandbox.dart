import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gemini/flutter_gemini.dart';

// ── Analysis Type Definition ─────────────────────────────────────────────────

enum AnalysisType {
  sentimentDist,
  emotionDist,
  topicClustering,
  sentimentOverTime,
  emergingTrends,
  negativeOutliers,
  keywordNetwork,
  geminiNarrative,
}

extension AnalysisTypeExt on AnalysisType {
  String get label {
    switch (this) {
      case AnalysisType.sentimentDist:
        return 'Sentiment Distribution';
      case AnalysisType.emotionDist:
        return 'Emotion Distribution';
      case AnalysisType.topicClustering:
        return 'Topic Clustering';
      case AnalysisType.sentimentOverTime:
        return 'Sentiment Over Time';
      case AnalysisType.emergingTrends:
        return 'Emerging Trends';
      case AnalysisType.negativeOutliers:
        return 'Negative Outliers';
      case AnalysisType.keywordNetwork:
        return 'Keyword Network';
      case AnalysisType.geminiNarrative:
        return 'AI Narrative (Gemini)';
    }
  }

  String get modelName {
    switch (this) {
      case AnalysisType.sentimentDist:
        return 'cardiffnlp/twitter-roberta-base-sentiment-latest';
      case AnalysisType.emotionDist:
        return 'SamLowe/roberta-base-go_emotions';
      case AnalysisType.topicClustering:
        return 'all-MiniLM-L6-v2 + UMAP + HDBSCAN + KeyBERT';
      case AnalysisType.sentimentOverTime:
        return 'cardiffnlp/twitter-roberta-base-sentiment-latest';
      case AnalysisType.emergingTrends:
        return 'all-MiniLM-L6-v2 + KMeans';
      case AnalysisType.negativeOutliers:
        return 'cardiffnlp/twitter-roberta-base-sentiment-latest';
      case AnalysisType.keywordNetwork:
        return 'all-MiniLM-L6-v2 + HDBSCAN + co-occurrence';
      case AnalysisType.geminiNarrative:
        return 'gemini-2.0-flash';
    }
  }

  String get description {
    switch (this) {
      case AnalysisType.sentimentDist:
        return 'Classify each comment as positive, neutral, or negative and get percentage breakdown.';
      case AnalysisType.emotionDist:
        return 'Detect top 5 emotions (joy, anger, sadness, etc.) across your dataset.';
      case AnalysisType.topicClustering:
        return 'Group comments into semantic clusters and extract representative keywords per cluster.';
      case AnalysisType.sentimentOverTime:
        return 'Track how sentiment shifts day-by-day across your comment timeline.';
      case AnalysisType.emergingTrends:
        return 'Surface trending keywords over time using embedding-based clustering.';
      case AnalysisType.negativeOutliers:
        return 'Identify comments with the highest negative sentiment scores (score ≥ 0.90).';
      case AnalysisType.keywordNetwork:
        return 'Build a co-occurrence graph of top keywords across all comments.';
      case AnalysisType.geminiNarrative:
        return 'Generate an executive summary + key insights narrative using Gemini AI.';
    }
  }

  String get csvFormat {
    switch (this) {
      case AnalysisType.sentimentDist:
      case AnalysisType.emotionDist:
      case AnalysisType.topicClustering:
      case AnalysisType.negativeOutliers:
      case AnalysisType.keywordNetwork:
        return 'CSV with one column: text';
      case AnalysisType.sentimentOverTime:
        return 'CSV with two columns: date (YYYY-MM-DD), text';
      case AnalysisType.emergingTrends:
        return 'CSV with two columns: text, date (YYYY-MM-DD)';
      case AnalysisType.geminiNarrative:
        return 'CSV with one column: text';
    }
  }

  String get csvExample {
    switch (this) {
      case AnalysisType.sentimentDist:
      case AnalysisType.emotionDist:
      case AnalysisType.topicClustering:
      case AnalysisType.negativeOutliers:
      case AnalysisType.keywordNetwork:
      case AnalysisType.geminiNarrative:
        return 'text\n"This app is amazing!"\n"Could be better"\n"Terrible experience"';
      case AnalysisType.sentimentOverTime:
        return 'date,text\n2024-01-01,"This app is amazing!"\n2024-01-02,"Could be better"';
      case AnalysisType.emergingTrends:
        return 'text,date\n"This app is amazing!",2024-01-01\n"Could be better",2024-01-02';
    }
  }

  /// Returns the Gemini prompt for image text extraction.
  /// [rangeStart] and [rangeEnd] are optional fallback date bounds when no
  /// dates are visible in the image (only relevant for date-column analyses).
  String imageExtractionPrompt({DateTime? rangeStart, DateTime? rangeEnd}) {
    switch (this) {
      case AnalysisType.sentimentDist:
      case AnalysisType.emotionDist:
      case AnalysisType.topicClustering:
      case AnalysisType.negativeOutliers:
      case AnalysisType.keywordNetwork:
      case AnalysisType.geminiNarrative:
        return '''
You are a data extraction assistant. Extract every comment, review, or text entry visible in this image.

Output ONLY a valid CSV with the following structure — no markdown, no backticks, no explanation:

text
"<comment 1>"
"<comment 2>"
...

Rules:
- Header must be exactly: text
- Each row is one extracted text entry, wrapped in double quotes
- Escape any internal double quotes by doubling them ("")
- Do not include row numbers, timestamps, or extra columns
- If no text is found, return just the header: text
''';

      case AnalysisType.sentimentOverTime:
        {
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final start = rangeStart != null
              ? rangeStart.toIso8601String().substring(0, 10)
              : today;
          final end = rangeEnd != null
              ? rangeEnd.toIso8601String().substring(0, 10)
              : today;
          final hasFallbackRange = rangeStart != null && rangeEnd != null;
          final fallbackNote = hasFallbackRange
              ? 'If a comment has no visible date, distribute it proportionally across the date range $start to $end.'
              : 'If a comment has no visible date, use today\'s date: $today.';
          return '''
You are a data extraction assistant. Look at this image and extract every comment, review, or user-written message you can see.

You MUST output one CSV data row for every comment found. Do NOT stop after the header line. Do NOT output placeholder text like "YYYY-MM-DD" or "<comment>".

Start your output with this exact header line:
date,text

Then immediately follow with one line per comment, using real values like:
2024-03-15,"Great product, really happy with it"

Rules:
- Replace the date with the real date shown next to the comment (format YYYY-MM-DD). If only month/year is visible, use the 1st of that month.
- $fallbackNote
- Wrap the comment text in double quotes. Escape any double quotes inside the text by doubling them ("").
- No markdown, no backticks, no explanation — raw CSV lines only.
- If the image contains 10 comments, output 10 data rows. Output ALL of them.
''';
        }

      case AnalysisType.emergingTrends:
        {
          // emergingTrends expects: text,date
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final start = rangeStart != null
              ? rangeStart.toIso8601String().substring(0, 10)
              : today;
          final end = rangeEnd != null
              ? rangeEnd.toIso8601String().substring(0, 10)
              : today;
          final hasFallbackRange = rangeStart != null && rangeEnd != null;
          final fallbackNote = hasFallbackRange
              ? 'If a comment has no visible date, distribute it proportionally across the date range $start to $end.'
              : 'If a comment has no visible date, use today\'s date: $today.';
          return '''
You are a data extraction assistant. Look at this image and extract every comment, review, or user-written message you can see.

You MUST output one CSV data row for every comment found. Do NOT stop after the header line. Do NOT output placeholder text like "YYYY-MM-DD" or "<comment>".

Start your output with this exact header line:
text,date

Then immediately follow with one line per comment, using real values like:
"Great product, really happy with it",2024-03-15

Rules:
- Replace the date with the real date shown next to the comment (format YYYY-MM-DD). If only month/year is visible, use the 1st of that month.
- $fallbackNote
- Wrap the comment text in double quotes. Escape any double quotes inside the text by doubling them ("").
- No markdown, no backticks, no explanation — raw CSV lines only.
- If the image contains 10 comments, output 10 data rows. Output ALL of them.
''';
        }
    }
  }

  IconData get icon {
    switch (this) {
      case AnalysisType.sentimentDist:
        return Icons.sentiment_satisfied_alt;
      case AnalysisType.emotionDist:
        return Icons.psychology;
      case AnalysisType.topicClustering:
        return Icons.bubble_chart;
      case AnalysisType.sentimentOverTime:
        return Icons.show_chart;
      case AnalysisType.emergingTrends:
        return Icons.trending_up;
      case AnalysisType.negativeOutliers:
        return Icons.warning_amber;
      case AnalysisType.keywordNetwork:
        return Icons.share;
      case AnalysisType.geminiNarrative:
        return Icons.auto_awesome;
    }
  }

  Color get accent {
    switch (this) {
      case AnalysisType.sentimentDist:
        return const Color(0xFF4FC3F7);
      case AnalysisType.emotionDist:
        return const Color(0xFFBA68C8);
      case AnalysisType.topicClustering:
        return const Color(0xFF81C784);
      case AnalysisType.sentimentOverTime:
        return const Color(0xFF4FC3F7);
      case AnalysisType.emergingTrends:
        return const Color(0xFFFFB74D);
      case AnalysisType.negativeOutliers:
        return const Color(0xFFEF5350);
      case AnalysisType.keywordNetwork:
        return const Color(0xFF26C6DA);
      case AnalysisType.geminiNarrative:
        return const Color(0xFF9CCC65);
    }
  }

  bool get requiresGemini => this == AnalysisType.geminiNarrative;
}

// ── Log Entry ────────────────────────────────────────────────────────────────

enum LogLevel { info, success, error, result }

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime time;

  LogEntry(this.message, this.level) : time = DateTime.now();
}

// ── Upload Mode ───────────────────────────────────────────────────────────────

enum UploadMode { csv, image }

// ── Sandbox Page ─────────────────────────────────────────────────────────────

class SandboxPage extends StatefulWidget {
  const SandboxPage({super.key});

  @override
  State<SandboxPage> createState() => _SandboxPageState();
}

class _SandboxPageState extends State<SandboxPage>
    with TickerProviderStateMixin {
  static const String _flaskBase =
      'https://chuajeromeflutterfirebase-flutterapp.hf.space';

  AnalysisType? _selectedType;

  // ── Upload state ──────────────────────────────────────────────────────────
  UploadMode _uploadMode = UploadMode.csv;

  // CSV state
  String? _csvFileName;
  List<List<dynamic>>? _parsedRows;

  // Image state
  String? _imageFileName;
  Uint8List? _imageBytes;
  bool _isExtractingFromImage = false;

  // Date range fallback (for sentimentOverTime + emergingTrends in image mode)
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;

  bool _isRunning = false;

  final List<LogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  // ── Logging ──────────────────────────────────────────────────────────────

  void _log(String msg, [LogLevel level = LogLevel.info]) {
    setState(() => _logs.add(LogEntry(msg, level)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(
          _logScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get _needsDateRange =>
      _uploadMode == UploadMode.image &&
      (_selectedType == AnalysisType.sentimentOverTime ||
          _selectedType == AnalysisType.emergingTrends);

  void _clearUpload() {
    setState(() {
      _csvFileName = null;
      _parsedRows = null;
      _imageFileName = null;
      _imageBytes = null;
      _dateRangeStart = null;
      _dateRangeEnd = null;
      _logs.clear();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _dateRangeStart != null && _dateRangeEnd != null
          ? DateTimeRange(start: _dateRangeStart!, end: _dateRangeEnd!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4FC3F7),
            onPrimary: Colors.black,
            surface: Color(0xFF1A1D27),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateRangeStart = picked.start;
        _dateRangeEnd = picked.end;
      });
    }
  }

  // ── CSV Parsing ──────────────────────────────────────────────────────────

  List<List<dynamic>> _parseCsv(String raw) {
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.map((line) {
      final List<dynamic> row = [];
      bool inQuotes = false;
      StringBuffer field = StringBuffer();
      for (int i = 0; i < line.length; i++) {
        final ch = line[i];
        if (ch == '"') {
          inQuotes = !inQuotes;
        } else if (ch == ',' && !inQuotes) {
          row.add(field.toString().trim());
          field = StringBuffer();
        } else {
          field.write(ch);
        }
      }
      row.add(field.toString().trim());
      return row;
    }).toList();
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null) return;

    final file = result.files.first;
    final raw = utf8.decode(file.bytes!);
    final rows = _parseCsv(raw);

    setState(() {
      _csvFileName = file.name;
      _parsedRows = rows;
      _imageFileName = null;
      _imageBytes = null;
      _logs.clear();
    });
    _log(
      '✓ Loaded "${file.name}" — ${rows.length - 1} data rows detected',
      LogLevel.success,
    );
  }

  // ── Image Pick & Gemini Extraction ────────────────────────────────────────

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;

    final file = result.files.first;

    setState(() {
      _imageFileName = file.name;
      _imageBytes = file.bytes;
      _csvFileName = null;
      _parsedRows = null;
      _logs.clear();
    });

    _log('✓ Image "${file.name}" loaded — ready to extract', LogLevel.success);
    _log(
      '⚙ Tap "Extract Text via Gemini" to convert image → CSV',
      LogLevel.info,
    );
  }

  Future<void> _extractTextFromImage() async {
    if (_imageBytes == null || _selectedType == null) return;

    setState(() {
      _isExtractingFromImage = true;
      _logs.clear();
    });

    _log('⚙ Sending image to Gemini Vision...');
    _log('⚙ Extracting texts in "${_selectedType!.csvFormat}" format...');
    _log('⚙ Please wait — Gemini is reading the image...');

    try {
      final prompt = _selectedType!.imageExtractionPrompt(
        rangeStart: _dateRangeStart,
        rangeEnd: _dateRangeEnd,
      );

      final response = await Gemini.instance.prompt(
        parts: [Part.uint8List(_imageBytes!), Part.text(prompt)],
      );

      final raw = response?.output ?? '';
      // Strip markdown fences if Gemini adds them despite instructions
      final csvText = raw
          .replaceAll(RegExp(r'```csv\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      if (csvText.isEmpty) {
        _log('✗ Gemini returned empty output.', LogLevel.error);
        return;
      }

      // ── Diagnostics: dump raw Gemini output ─────────────────────────
      _log('⚙ Raw Gemini output (first 300 chars):', LogLevel.info);
      _log(
        '  ${csvText.length > 300 ? csvText.substring(0, 300) : csvText}',
        LogLevel.info,
      );

      final rows = _parseCsv(csvText);

      // ── Diagnostics: dump parsed row count + first two rows ──────────
      _log('⚙ Parsed ${rows.length} row(s) total.', LogLevel.info);
      if (rows.isNotEmpty) {
        _log('⚙ Row 0 (header?): ${rows[0].join(" | ")}', LogLevel.info);
      }
      if (rows.length >= 2) {
        _log('⚙ Row 1 (first data): ${rows[1].join(" | ")}', LogLevel.info);
      }

      if (rows.isEmpty || rows.length < 2) {
        _log(
          '✗ No text rows could be extracted from the image.',
          LogLevel.error,
        );
        return;
      }

      // ── Debug: show detected header ──────────────────────────────────
      _log('⚙ Header detected: ${rows.first.join(" | ")}', LogLevel.info);

      setState(() {
        _parsedRows = rows;
        _csvFileName = '${_imageFileName ?? 'image'}_extracted.csv';
      });

      _log(
        '✓ Extraction complete! ${rows.length - 1} text rows extracted.',
        LogLevel.success,
      );
      _log('', LogLevel.result);
      _log('━━━ EXTRACTED CSV PREVIEW (first 5 rows) ━━━', LogLevel.result);
      _log('  ${rows.first.join(',')}', LogLevel.result); // header
      for (final row in rows.skip(1).take(5)) {
        final preview = row.join(',');
        _log(
          '  ${preview.length > 80 ? '${preview.substring(0, 80)}…' : preview}',
          LogLevel.result,
        );
      }
      if (rows.length > 6) {
        _log('  … and ${rows.length - 6} more rows', LogLevel.result);
      }
      _log('', LogLevel.result);
      _log(
        '✓ CSV is ready — tap "Run ${_selectedType!.label}" to proceed.',
        LogLevel.success,
      );
    } on GeminiException catch (e) {
      _log('✗ Gemini error: $e', LogLevel.error);
    } catch (e) {
      _log('✗ Extraction failed: $e', LogLevel.error);
    } finally {
      if (mounted) setState(() => _isExtractingFromImage = false);
    }
  }

  // ── Extract data by analysis type ────────────────────────────────────────

  /// Normalises a raw header cell: lowercase, trim whitespace,
  /// strip BOM (U+FEFF) and Windows carriage-returns (\r).
  String _normaliseHeader(dynamic cell) => cell
      .toString()
      .toLowerCase()
      .trim()
      .replaceAll('\uFEFF', '')
      .replaceAll('\r', '');

  List<String>? _extractTexts() {
    if (_parsedRows == null || _parsedRows!.length < 2) return null;
    final header = _parsedRows!.first.map(_normaliseHeader).toList();
    final textIdx = header.indexOf('text');
    if (textIdx == -1) return null;
    return _parsedRows!
        .skip(1)
        .map((row) => row[textIdx].toString().trim())
        .toList();
  }

  List<Map<String, String>>? _extractDateText() {
    if (_parsedRows == null || _parsedRows!.length < 2) return null;
    final header = _parsedRows!.first.map(_normaliseHeader).toList();
    final dateIdx = header.indexOf('date');
    final textIdx = header.indexOf('text');
    if (dateIdx == -1 || textIdx == -1) return null;
    return _parsedRows!
        .skip(1)
        .map(
          (row) => {
            'date': row[dateIdx].toString().trim(),
            'text': row[textIdx].toString().trim(),
          },
        )
        .toList();
  }

  List<Map<String, String>>? _extractTextDate() {
    if (_parsedRows == null || _parsedRows!.length < 2) return null;
    final header = _parsedRows!.first.map(_normaliseHeader).toList();
    final dateIdx = header.indexOf('date');
    final textIdx = header.indexOf('text');
    if (dateIdx == -1 || textIdx == -1) return null;
    return _parsedRows!
        .skip(1)
        .map(
          (row) => {
            'text': row[textIdx].toString().trim(),
            'date': row[dateIdx].toString().trim(),
          },
        )
        .toList();
  }

  // ── Run Analysis ─────────────────────────────────────────────────────────

  Future<void> _runAnalysis() async {
    if (_selectedType == null) {
      _log('✗ Please select an analysis type first.', LogLevel.error);
      return;
    }
    if (_parsedRows == null || _parsedRows!.length < 2) {
      _log('✗ Please upload a valid CSV file first.', LogLevel.error);
      return;
    }

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    try {
      await _dispatchAnalysis(_selectedType!);
    } catch (e) {
      _log('✗ Unexpected error: $e', LogLevel.error);
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  Future<void> _dispatchAnalysis(AnalysisType type) async {
    switch (type) {
      case AnalysisType.sentimentDist:
        await _runSentimentDist();
      case AnalysisType.emotionDist:
        await _runEmotionDist();
      case AnalysisType.topicClustering:
        await _runTopicClustering();
      case AnalysisType.sentimentOverTime:
        await _runSentimentOverTime();
      case AnalysisType.emergingTrends:
        await _runEmergingTrends();
      case AnalysisType.negativeOutliers:
        await _runNegativeOutliers();
      case AnalysisType.keywordNetwork:
        await _runKeywordNetwork();
      case AnalysisType.geminiNarrative:
        await _runGeminiNarrative();
    }
  }

  Future<void> _runSentimentDist() async {
    _log('⚙ Extracting texts from CSV...');
    final texts = _extractTexts();
    if (texts == null) {
      _log('✗ CSV must have a "text" column.', LogLevel.error);
      return;
    }
    _log('⚙ Sending ${texts.length} comments to RoBERTa sentiment model...');
    _log('⚙ Model running in the background, please wait...');

    final resp = await http.post(
      Uri.parse('$_flaskBase/roberta-base-sentiment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': texts}),
    );

    if (resp.statusCode != 200) {
      _log('✗ Flask returned ${resp.statusCode}: ${resp.body}', LogLevel.error);
      return;
    }

    final result = jsonDecode(resp.body)['results'] as Map<String, dynamic>;
    _log('✓ Analysis complete!', LogLevel.success);
    _log('', LogLevel.result);
    _log('━━━ SENTIMENT DISTRIBUTION ━━━', LogLevel.result);
    result.forEach((k, v) => _log('  $k: $v%', LogLevel.result));
  }

  Future<void> _runEmotionDist() async {
    _log('⚙ Extracting texts from CSV...');
    final texts = _extractTexts();
    if (texts == null) {
      _log('✗ CSV must have a "text" column.', LogLevel.error);
      return;
    }
    _log('⚙ Sending ${texts.length} comments to GoEmotions model...');
    _log('⚙ Model running in the background, please wait...');

    final resp = await http.post(
      Uri.parse('$_flaskBase/roberta-base-go'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': texts}),
    );

    if (resp.statusCode != 200) {
      _log('✗ Flask returned ${resp.statusCode}', LogLevel.error);
      return;
    }

    final results = jsonDecode(resp.body)['results'] as List;
    _log('✓ Analysis complete!', LogLevel.success);
    _log('', LogLevel.result);
    _log('━━━ TOP EMOTIONS ━━━', LogLevel.result);
    for (final e in results) {
      _log('  ${e['label']}: ${e['value']}%', LogLevel.result);
    }
  }

  Future<void> _runTopicClustering() async {
    _log('⚙ Extracting texts from CSV...');
    final texts = _extractTexts();
    if (texts == null) {
      _log('✗ CSV must have a "text" column.', LogLevel.error);
      return;
    }
    _log('⚙ Encoding comments via all-MiniLM-L6-v2...');
    _log('⚙ Running UMAP + HDBSCAN clustering...');
    _log('⚙ Extracting theme keywords via KeyBERT...');
    _log('⚙ Model running in the background, please wait...');

    final resp = await http.post(
      Uri.parse('$_flaskBase/all-MiniLM-L6-v2'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': texts}),
    );

    if (resp.statusCode != 200) {
      _log('✗ Flask returned ${resp.statusCode}', LogLevel.error);
      return;
    }

    final results = jsonDecode(resp.body)['results'] as Map<String, dynamic>;
    _log(
      '✓ Clustering complete! Found ${results.length} clusters.',
      LogLevel.success,
    );
    _log('', LogLevel.result);
    _log('━━━ TOPIC CLUSTERS ━━━', LogLevel.result);
    results.forEach((theme, data) {
      final d = data as Map<String, dynamic>;
      _log('  ▸ ${theme.toUpperCase()}', LogLevel.result);
      _log('    Comments: ${d['comments']}', LogLevel.result);
      _log(
        '    Keywords: ${(d['keywords'] as List).join(', ')}',
        LogLevel.result,
      );
    });
  }

  Future<void> _runSentimentOverTime() async {
    _log('⚙ Extracting date+text pairs from CSV...');
    final data = _extractDateText();
    if (data == null) {
      _log('✗ CSV must have "date" and "text" columns.', LogLevel.error);
      return;
    }
    _log('⚙ Sending ${data.length} dated comments to RoBERTa SOT model...');
    _log('⚙ Model running in the background, please wait...');

    final resp = await http.post(
      Uri.parse('$_flaskBase/roberta-base-sentiment-SOT'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': data}),
    );

    if (resp.statusCode != 200) {
      _log('✗ Flask returned ${resp.statusCode}', LogLevel.error);
      return;
    }

    final results = jsonDecode(resp.body)['results'] as List;
    _log('✓ Analysis complete!', LogLevel.success);
    _log('', LogLevel.result);
    _log('━━━ SENTIMENT OVER TIME ━━━', LogLevel.result);
    for (final e in results) {
      _log(
        '  ${e['date']}  →  ${e['label'].toString().toUpperCase()}',
        LogLevel.result,
      );
    }
  }

  Future<void> _runEmergingTrends() async {
    _log('⚙ Extracting text+date pairs from CSV...');
    final data = _extractTextDate();
    if (data == null) {
      _log('✗ CSV must have "text" and "date" columns.', LogLevel.error);
      return;
    }
    _log('⚙ Embedding comments + KMeans clustering...');
    _log('⚙ Extracting trending keywords per time window...');
    _log('⚙ Model running in the background, please wait...');

    final resp = await http.post(
      Uri.parse('$_flaskBase/all-MiniLM-L6-v2-ETO'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': data}),
    );

    if (resp.statusCode != 200) {
      _log('✗ Flask returned ${resp.statusCode}', LogLevel.error);
      return;
    }

    final results = jsonDecode(resp.body)['results'] as List;
    _log('✓ Analysis complete!', LogLevel.success);
    _log('', LogLevel.result);
    _log('━━━ EMERGING TRENDS ━━━', LogLevel.result);
    for (final e in results) {
      _log(
        '  [${e['time']}] "${e['keyword']}"  ×${e['count']}',
        LogLevel.result,
      );
    }
  }

  Future<void> _runNegativeOutliers() async {
    _log('⚙ Extracting texts from CSV...');
    final texts = _extractTexts();
    if (texts == null) {
      _log('✗ CSV must have a "text" column.', LogLevel.error);
      return;
    }
    _log('⚙ Scoring negativity with RoBERTa full-score model...');
    _log('⚙ Filtering outliers with score ≥ 0.90...');
    _log('⚙ Model running in the background, please wait...');

    final resp = await http.post(
      Uri.parse('$_flaskBase/roberta-base-sentiment-SCORES'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': texts}),
    );

    if (resp.statusCode != 200) {
      _log('✗ Flask returned ${resp.statusCode}', LogLevel.error);
      return;
    }

    final results =
        (jsonDecode(resp.body)['results'] as List)
            .map((e) => e as Map<String, dynamic>)
            .where((e) => (e['score'] as num).toDouble() >= 0.90)
            .toList()
          ..sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

    _log(
      '✓ Analysis complete! Found ${results.length} negative outlier(s).',
      LogLevel.success,
    );
    _log('', LogLevel.result);
    _log('━━━ NEGATIVE OUTLIERS (score ≥ 0.90) ━━━', LogLevel.result);
    if (results.isEmpty) {
      _log('  No outliers found in this dataset.', LogLevel.result);
    } else {
      for (final e in results) {
        final score = (e['score'] as num).toStringAsFixed(4);
        final text = e['text'].toString();
        final preview = text.length > 80 ? '${text.substring(0, 80)}…' : text;
        _log('  [$score] "$preview"', LogLevel.result);
      }
    }
  }

  Future<void> _runKeywordNetwork() async {
    _log('⚙ Extracting texts from CSV...');
    final texts = _extractTexts();
    if (texts == null) {
      _log('✗ CSV must have a "text" column.', LogLevel.error);
      return;
    }
    _log('⚙ Embedding comments + HDBSCAN clustering...');
    _log('⚙ Building keyword co-occurrence graph...');
    _log('⚙ Model running in the background, please wait...');

    final resp = await http.post(
      Uri.parse('$_flaskBase/all-MiniLM-L6-v2-G'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': texts}),
    );

    if (resp.statusCode != 200) {
      _log('✗ Flask returned ${resp.statusCode}', LogLevel.error);
      return;
    }

    final results = jsonDecode(resp.body)['results'] as Map<String, dynamic>;
    final nodes = results['nodes'] as List;
    final edges = results['edges'] as List;

    _log(
      '✓ Graph built! ${nodes.length} nodes, ${edges.length} edges.',
      LogLevel.success,
    );
    _log('', LogLevel.result);
    _log('━━━ TOP KEYWORDS (nodes) ━━━', LogLevel.result);
    for (final n in nodes.take(10)) {
      final weight = ((n['weight'] as num) * 100).toStringAsFixed(1);
      _log(
        '  ▸ ${n['id']}  (freq: ${n['frequency']}, weight: $weight%)',
        LogLevel.result,
      );
    }
    _log('', LogLevel.result);
    _log('━━━ TOP CO-OCCURRENCES (edges) ━━━', LogLevel.result);
    for (final e in edges.take(10)) {
      final w = ((e['weight'] as num) * 100).toStringAsFixed(1);
      _log('  ${e['source']} ↔ ${e['target']}  (weight: $w%)', LogLevel.result);
    }
  }

  Future<void> _runGeminiNarrative() async {
    _log('⚙ Extracting texts from CSV...');
    final texts = _extractTexts();
    if (texts == null) {
      _log('✗ CSV must have a "text" column.', LogLevel.error);
      return;
    }

    _log('⚙ Sending ${texts.length} comments to Gemini...');
    _log('⚙ Gemini generating executive summary + key insights...');
    _log('⚙ This may take a moment — AI thinking in the background...');

    try {
      final prompt =
          '''
You are an expert comment section analyst. Return ONLY a valid JSON object, no markdown, no backticks, no explanation.

JSON structure:
{
  "executive_summary": "<1 paragraph, plain prose>",
  "key_insights": [
    { "label": "Dominant Sentiment", "body": "<2 sentences>" },
    { "label": "Rising Concern", "body": "<2 sentences>" },
    { "label": "Notable Pattern", "body": "<2 sentences>" },
    { "label": "Alert", "body": "<2 sentences>" }
  ],
  "overall_tone": "<one word: Positive / Mixed / Negative / Neutral>"
}

RULES:
- executive_summary: 3-5 sentences, plain prose
- key_insights: exactly 4, distinct labels, 2-sentence body each
- overall_tone: single word only
- No extra fields, no markdown

--- COMMENTS (${texts.length} total) ---
${texts.take(50).map((t) => '- $t').join('\n')}
''';

      final response = await Gemini.instance.prompt(parts: [Part.text(prompt)]);
      final raw = response?.output ?? '';
      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

      _log('✓ Gemini response received!', LogLevel.success);
      _log('', LogLevel.result);
      _log('━━━ EXECUTIVE SUMMARY ━━━', LogLevel.result);
      _log('  ${parsed['executive_summary']}', LogLevel.result);
      _log('', LogLevel.result);
      _log('━━━ KEY INSIGHTS ━━━', LogLevel.result);
      for (final insight in (parsed['key_insights'] as List)) {
        _log('  ▸ ${insight['label']}', LogLevel.result);
        _log('    ${insight['body']}', LogLevel.result);
      }
      _log('', LogLevel.result);
      _log('━━━ OVERALL TONE ━━━', LogLevel.result);
      _log('  ${parsed['overall_tone']}', LogLevel.result);
    } on GeminiException catch (e) {
      _log('✗ Gemini error: $e', LogLevel.error);
    } catch (e) {
      _log('✗ Failed to parse Gemini response: $e', LogLevel.error);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17171E),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF17171E),
        elevation: 0,
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.flask, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Sandbox Mode',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildHeroIntro(),
          const SizedBox(height: 20),
          _buildSectionLabel('01', 'Choose Analysis Type'),
          const SizedBox(height: 20),
          _buildAnalysisGrid(),
          const SizedBox(height: 20),
          _buildSectionLabel('02', 'Upload Your Data'),
          const SizedBox(height: 20),
          _buildUploadPanel(),
          const SizedBox(height: 20),
          _buildSectionLabel('03', 'Run Analysis'),
          const SizedBox(height: 20),
          _buildRunButton(),
          const SizedBox(height: 20),
          _buildSectionLabel('', 'Console Output'),
          const SizedBox(height: 20),
          _buildTerminal(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Hero Intro ────────────────────────────────────────────────────────────

  Widget _buildHeroIntro() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SvgPicture.asset(
                  'assets/cornelia_ai_logo_flower-cropped.svg',
                  height: 240,
                  width: 240,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CORNELIA Sandbox',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Experiment with CORNELIA\'s AI models using your own data. '
                  'Upload a CSV or a screenshot/photo of comments, pick an analysis type, '
                  'and run any of our eight AI-powered pipelines — from sentiment '
                  'scoring to Gemini-generated narratives — without needing a live topic.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12.5,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(FontAwesomeIcons.flask, 'Flask Models'),
                    _chip(FontAwesomeIcons.robot, 'Gemini AI'),
                    _chip(FontAwesomeIcons.fileCsv, 'CSV Upload'),
                    _chip(FontAwesomeIcons.image, 'Image → CSV'),
                    _chip(FontAwesomeIcons.terminal, 'Live Console'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(FaIconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10, color: Colors.white38),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String number, String title) {
    return Row(
      children: [
        if (number.isNotEmpty) ...[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF4FC3F7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Analysis Grid ─────────────────────────────────────────────────────────

  Widget _buildAnalysisGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: AnalysisType.values.length,
      itemBuilder: (context, index) {
        final type = AnalysisType.values[index];
        final isSelected = _selectedType == type;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = isSelected ? null : type;
              _logs.clear();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? type.accent.withValues(alpha: 0.12)
                  : const Color(0xFF0F1117),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? type.accent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.06),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: type.accent.withValues(
                          alpha: isSelected ? 0.2 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(type.icon, color: type.accent, size: 13),
                    ),
                    const Spacer(),
                    if (type.requiresGemini)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF9CCC65,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(
                              0xFF9CCC65,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: Color(0xFF9CCC65),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _MarqueeText(
                  text: type.modelName,
                  color: type.accent.withValues(alpha: isSelected ? 0.7 : 0.35),
                ),
                const Spacer(),
                Text(
                  type.label,
                  style: TextStyle(
                    color: isSelected ? type.accent : Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Upload Panel ──────────────────────────────────────────────────────────

  Widget _buildUploadPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mode toggle ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: _buildModeToggle(),
          ),

          // ── Format hint ─────────────────────────────────────────────────
          if (_selectedType != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: _buildFormatHint(),
            ),

          // ── Upload area ─────────────────────────────────────────────────
          if (_uploadMode == UploadMode.csv)
            _buildCsvUpload()
          else
            _buildImageUpload(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _modeTab(UploadMode.csv, FontAwesomeIcons.fileCsv, 'CSV File'),
          _modeTab(
            UploadMode.image,
            FontAwesomeIcons.image,
            'Image / Screenshot',
          ),
        ],
      ),
    );
  }

  Widget _modeTab(UploadMode mode, FaIconData icon, String label) {
    final isActive = _uploadMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_uploadMode == mode) return;
          setState(() {
            _uploadMode = mode;
            _logs.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4FC3F7).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF4FC3F7).withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 11,
                color: isActive ? const Color(0xFF4FC3F7) : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF4FC3F7) : Colors.white38,
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatHint() {
    final isImage = _uploadMode == UploadMode.image;
    final accent = _selectedType!.accent;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImage ? Icons.image_search : Icons.info_outline,
                color: accent,
                size: 13,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isImage
                      ? 'Gemini will extract texts → "${_selectedType!.csvFormat}"'
                      : 'Required format for "${_selectedType!.label}"',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!isImage) ...[
            const SizedBox(height: 6),
            Text(
              _selectedType!.csvFormat,
              style: TextStyle(
                color: accent.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _selectedType!.csvExample,
                style: const TextStyle(
                  color: Color(0xFF9CCC65),
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Upload any image containing visible text (screenshots, photos, scans). '
              'Gemini Vision will read the text and format it into the correct CSV structure automatically.',
              style: TextStyle(
                color: accent.withValues(alpha: 0.7),
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── CSV upload ─────────────────────────────────────────────────────────────

  Widget _buildCsvUpload() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isRunning ? null : _pickCsv,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _csvFileName != null
                    ? const Color(0xFF4FC3F7).withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _csvFileName != null
                      ? const Color(0xFF4FC3F7).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  FaIcon(
                    _csvFileName != null
                        ? FontAwesomeIcons.circleCheck
                        : FontAwesomeIcons.fileCsv,
                    color: _csvFileName != null
                        ? const Color(0xFF4FC3F7)
                        : Colors.white24,
                    size: 22,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _csvFileName ?? 'Tap to upload CSV',
                    style: TextStyle(
                      color: _csvFileName != null
                          ? const Color(0xFF4FC3F7)
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_csvFileName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${(_parsedRows?.length ?? 1) - 1} rows loaded — tap to replace',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Clear button ──────────────────────────────────────────────
          if (_csvFileName != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isRunning ? null : _clearUpload,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF5350),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Clear file',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Image upload ───────────────────────────────────────────────────────────

  Widget _buildImageUpload() {
    final hasImage = _imageBytes != null;
    final csvReady = hasImage && _parsedRows != null;
    final busy = _isExtractingFromImage || _isRunning;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Image drop zone
          GestureDetector(
            onTap: busy ? null : _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasImage
                    ? const Color(0xFFBA68C8).withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasImage
                      ? const Color(0xFFBA68C8).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: hasImage
                  // ── Image preview ──────────────────────────────────
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(
                            _imageBytes!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Dim overlay
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                        // File name + tap-to-replace
                        Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.image,
                                color: const Color(0xFFBA68C8),
                                size: 13,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  _imageFileName ?? 'image',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (csvReady)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF81C784,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF81C784,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'CSV ready',
                                    style: TextStyle(
                                      color: Color(0xFF81C784),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: busy ? null : _pickImage,
                                child: const Text(
                                  'replace',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  // ── Empty state ────────────────────────────────────
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.image,
                            color: Colors.white24,
                            size: 26,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tap to upload image',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PNG, JPG, WEBP, GIF — screenshots, photos, scans',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // ── Date range picker (sentimentOverTime / emergingTrends only) ────
          if (hasImage && _needsDateRange) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: busy ? null : _pickDateRange,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: (_dateRangeStart != null)
                      ? const Color(0xFFFFB74D).withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_dateRangeStart != null)
                        ? const Color(0xFFFFB74D).withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      color: _dateRangeStart != null
                          ? const Color(0xFFFFB74D)
                          : Colors.white38,
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _dateRangeStart != null && _dateRangeEnd != null
                            ? '${_dateRangeStart!.toIso8601String().substring(0, 10)}  →  ${_dateRangeEnd!.toIso8601String().substring(0, 10)}'
                            : 'Set fallback date range (optional)',
                        style: TextStyle(
                          color: _dateRangeStart != null
                              ? const Color(0xFFFFB74D)
                              : Colors.white38,
                          fontSize: 12,
                          fontWeight: _dateRangeStart != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (_dateRangeStart != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _dateRangeStart = null;
                          _dateRangeEnd = null;
                        }),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white24,
                          size: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 2),
              child: Text(
                _dateRangeStart == null
                    ? 'If no dates are visible in the image, today\'s date will be used.'
                    : 'Gemini will distribute undated comments across this range.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // ── Extract button ─────────────────────────────────────────────
          if (hasImage) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap:
                  (_isExtractingFromImage ||
                      _isRunning ||
                      _selectedType == null)
                  ? null
                  : _extractTextFromImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _selectedType != null
                      ? const Color(0xFFBA68C8).withValues(alpha: 0.13)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedType != null
                        ? const Color(0xFFBA68C8).withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isExtractingFromImage)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Opacity(
                          opacity: 0.4 + _pulseController.value * 0.6,
                          child: const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFBA68C8),
                            ),
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.auto_fix_high_rounded,
                        color: Color(0xFFBA68C8),
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isExtractingFromImage
                          ? 'Gemini is reading the image...'
                          : _selectedType == null
                          ? 'Select an analysis type first'
                          : csvReady
                          ? 'Re-extract text from image'
                          : 'Extract Text via Gemini',
                      style: TextStyle(
                        color: _selectedType != null
                            ? const Color(0xFFBA68C8)
                            : Colors.white24,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── CSV row count + clear ──────────────────────────────────
            if (csvReady) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF81C784),
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${(_parsedRows?.length ?? 1) - 1} rows extracted — ready to run analysis',
                    style: const TextStyle(
                      color: Color(0xFF81C784),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],

            // ── Clear button ───────────────────────────────────────────
            const SizedBox(height: 8),
            GestureDetector(
              onTap: busy ? null : _clearUpload,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF5350),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Clear image',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Run Button ────────────────────────────────────────────────────────────

  Widget _buildRunButton() {
    final canRun =
        _selectedType != null &&
        _parsedRows != null &&
        !_isRunning &&
        !_isExtractingFromImage;
    final accent = _selectedType?.accent ?? const Color(0xFF4FC3F7);

    // Determine label
    String label;
    if (_isRunning) {
      label = 'Running Analysis...';
    } else if (_selectedType == null) {
      label = 'Select an analysis type to continue';
    } else if (_parsedRows == null) {
      if (_uploadMode == UploadMode.image && _imageBytes != null) {
        label = 'Extract text from image first';
      } else {
        label = 'Upload data to continue';
      }
    } else {
      label = 'Run ${_selectedType!.label}';
    }

    return GestureDetector(
      onTap: canRun ? _runAnalysis : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: canRun
              ? accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canRun
                ? accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRunning)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Opacity(
                  opacity: 0.4 + _pulseController.value * 0.6,
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Icon(
                Icons.play_arrow_rounded,
                color: canRun ? accent : Colors.white24,
                size: 20,
              ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: canRun ? accent : Colors.white24,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Terminal ──────────────────────────────────────────────────────────────

  Widget _buildTerminal() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF080B10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFEF5350)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFB74D)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF81C784)),
                const SizedBox(width: 12),
                const Text(
                  'cornelia-sandbox — output',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                if (_logs.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _logs.clear()),
                    child: const Text(
                      'clear',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.terminal,
                          color: Colors.white12,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Output will appear here when you run an analysis',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _logScroll,
                    padding: const EdgeInsets.all(14),
                    itemCount: _logs.length,
                    itemBuilder: (context, i) {
                      final entry = _logs[i];
                      if (entry.message.isEmpty)
                        return const SizedBox(height: 6);
                      final color = switch (entry.level) {
                        LogLevel.error => const Color(0xFFEF5350),
                        LogLevel.success => const Color(0xFF81C784),
                        LogLevel.result => const Color(0xFF4FC3F7),
                        LogLevel.info => Colors.white38,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          entry.message,
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isRunning || _isExtractingFromImage)
                        ? const Color(0xFFFFB74D)
                        : _logs.any((l) => l.level == LogLevel.error)
                        ? const Color(0xFFEF5350)
                        : _logs.any((l) => l.level == LogLevel.result)
                        ? const Color(0xFF81C784)
                        : Colors.white24,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  (_isRunning || _isExtractingFromImage)
                      ? 'RUNNING'
                      : _logs.isEmpty
                      ? 'IDLE'
                      : _logs.any((l) => l.level == LogLevel.error)
                      ? 'ERROR'
                      : 'DONE',
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_logs.where((l) => l.level == LogLevel.result).length} result lines',
                  style: const TextStyle(color: Colors.white12, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Marquee Text ──────────────────────────────────────────────────────────────

class _MarqueeText extends StatefulWidget {
  final String text;
  final Color color;

  const _MarqueeText({required this.text, required this.color});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _controller;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) return;

      while (mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted || !_controller.hasClients) break;
        await _controller.animateTo(
          max,
          duration: Duration(milliseconds: (max * 18).toInt()),
          curve: Curves.linear,
        );
        if (!mounted || !_controller.hasClients) break;
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted || !_controller.hasClients) break;
        _controller.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: 9,
          fontFamily: 'monospace',
          letterSpacing: 0.2,
        ),
        maxLines: 1,
      ),
    );
  }
}
