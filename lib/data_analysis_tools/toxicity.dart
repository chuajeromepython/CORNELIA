import 'package:flutter/material.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ToxicityGauge extends StatelessWidget {
  final Map<String, dynamic> sentimentData;
  final List<dynamic> emotionData;

  const ToxicityGauge({
    super.key,
    required this.sentimentData,
    required this.emotionData,
  });

  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);

  static const _segments = [
    ('Low', 0.0, 30.0, Color(0xFF81C784)),
    ('Moderate', 30.0, 60.0, Color(0xFFFFB74D)),
    ('High', 60.0, 80.0, Color(0xFFE57373)),
    ('Severe', 80.0, 100.0, Color(0xFFBA68C8)),
  ];

  double _computeScore() {
    final negativePercent =
        (sentimentData['negative'] as num?)?.toDouble() ?? 0.0;
    const emotionWeights = {
      'Anger': 1.0,
      'Disgust': 0.9,
      'Fear': 0.7,
      'Sadness': 0.5,
      'Surprise': 0.2,
    };
    double emotionScore = 0.0;
    for (final e in emotionData) {
      final label = e['label'] as String? ?? '';
      final value = (e['value'] as num?)?.toDouble() ?? 0.0;
      emotionScore += (emotionWeights[label] ?? 0.0) * value;
    }
    return ((negativePercent * 0.6) + (emotionScore * 0.4)).clamp(0, 100);
  }

  String _toxicityLevel(double score) {
    if (score >= 80) return 'Severe';
    if (score >= 60) return 'High';
    if (score >= 30) return 'Moderate';
    return 'Low';
  }

  String _toxicitySummary(String level) {
    switch (level) {
      case 'Severe':
        return 'The comment section exhibits widespread hostility, with a significant portion of comments containing aggressive, threatening, or deeply offensive language.';
      case 'High':
        return 'A notable amount of hostile and inflammatory language is present, with several comments crossing the line into personal attacks or abusive rhetoric.';
      case 'Moderate':
        return 'Some comments contain harsh or dismissive language, though the majority of the discussion remains within acceptable boundaries of disagreement.';
      default:
        return 'The comment section maintains a largely civil tone, with most commenters expressing their views respectfully even when in disagreement.';
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Severe':
        return const Color(0xFFBA68C8);
      case 'High':
        return const Color(0xFFE57373);
      case 'Moderate':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF81C784);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _computeScore();
    final level = _toxicityLevel(score);
    final summary = _toxicitySummary(level);
    final levelColor = _levelColor(level);

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Toxicity Level',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Tooltip(
                        message:
                            'Measures how toxic the overall discussion is.',
                        waitDuration: Duration.zero,
                        showDuration: const Duration(seconds: 5),
                        exitDuration: const Duration(seconds: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.circleInfo,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Overall hostility detected in comments',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              // ── Level badge ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Level',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level,
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Arc Gauge ──
          Center(
            child: SizedBox(
              width: 220,
              height: 130,
              child: CustomPaint(
                painter: _ArcGaugePainter(score: score, segments: _segments),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const Text(
                        'out of 100',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Segment Legend ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _segments.map((s) {
              final isActive =
                  score >= s.$2 && score < s.$3 ||
                  (s.$3 == 100.0 && score == 100.0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive ? s.$4 : s.$4.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.$1,
                    style: TextStyle(
                      color: isActive ? s.$4 : Colors.white24,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Summary ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: levelColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: levelColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double score;
  final List<(String, double, double, Color)> segments;

  const _ArcGaugePainter({required this.score, required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final radius = size.width / 2 - 10;
    const strokeWidth = 16.0;
    const startAngle = pi;
    const sweepTotal = pi;

    final trackPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    for (final seg in segments) {
      final segStart = startAngle + (seg.$2 / 100) * sweepTotal;
      final segSweep = ((seg.$3 - seg.$2) / 100) * sweepTotal;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        segStart,
        segSweep,
        false,
        Paint()
          ..color = seg.$4.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    final activeSweep = (score / 100) * sweepTotal;
    final activeColor = _colorForScore(score);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      activeSweep,
      false,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    final needleAngle = startAngle + (score / 100) * sweepTotal;
    final needleEnd = Offset(
      cx + (radius) * cos(needleAngle),
      cy + (radius) * sin(needleAngle),
    );
    canvas.drawLine(
      Offset(cx, cy),
      needleEnd,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = Colors.white);
  }

  Color _colorForScore(double score) {
    for (final seg in segments) {
      if (score >= seg.$2 && score < seg.$3) return seg.$4;
      if (seg.$3 == 100.0 && score == 100.0) return seg.$4;
    }
    return Colors.white;
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) => old.score != score;
}
