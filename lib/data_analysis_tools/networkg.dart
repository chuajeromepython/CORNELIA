import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────
class GraphNode {
  final String id;
  final String label;
  Offset position;
  Offset velocity;
  bool isPinned;

  GraphNode({
    required this.id,
    required this.label,
    required this.position,
    this.velocity = Offset.zero,
    this.isPinned = false,
  });
}

class GraphEdge {
  final String source;
  final String target;
  final String relation;
  final double weight;

  const GraphEdge({
    required this.source,
    required this.target,
    required this.relation,
    this.weight = 0.5,
  });
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  const GraphData({required this.nodes, required this.edges});
}

// ─────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────
class KeywordGraphChart extends StatefulWidget {
  final Map<String, dynamic> networkData;

  const KeywordGraphChart({super.key, required this.networkData});

  @override
  State<KeywordGraphChart> createState() => _KeywordGraphChartState();
}

class _KeywordGraphChartState extends State<KeywordGraphChart>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0F1117);
  static const _surface = Color(0xFF1E1E2E);
  static const _blue = Color(0xFF4FC3F7);
  static const _amber = Color(0xFFFFB74D);

  final List<Color> _nodeColors = const [
    Color(0xFF4FC3F7),
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFFCE93D8),
    Color(0xFF80DEEA),
  ];

  late GraphData _graph;
  String? _selectedNodeId;
  int? _draggingIndex;
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;

  Size _canvasSize = Size.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const double _repulsion = 0.00012;
  static const double _attraction = 0.10;
  static const double _damping = 0.75;
  static const double _minDist = 0.06;

  bool _showLabels = true;
  bool _showWeights = false;

  final Map<String, Color> _colorMap = {};

  // ─────────────────────────────────────────────
  // GRAPH BUILDER
  // ─────────────────────────────────────────────
  GraphData _buildGraphFromData(Map<String, dynamic> data) {
    final rawNodes = data['nodes'] as List<dynamic>;
    final rawEdges = data['edges'] as List<dynamic>;

    final nodes = rawNodes.asMap().entries.map((entry) {
      final n = entry.value as Map<String, dynamic>;
      final angle = 2 * pi * entry.key / rawNodes.length;
      const radius = 0.25;
      return GraphNode(
        id: n['id'] as String,
        label: n['label'] as String,
        position: Offset(0.5 + radius * cos(angle), 0.5 + radius * sin(angle)),
      );
    }).toList();

    final edges = rawEdges.map((e) {
      final edge = e as Map<String, dynamic>;
      return GraphEdge(
        source: edge['source'] as String,
        target: edge['target'] as String,
        relation: edge['relation'] as String,
        weight: (edge['weight'] as num).toDouble(),
      );
    }).toList();

    return GraphData(nodes: nodes, edges: edges);
  }

  @override
  void initState() {
    super.initState();
    _graph = _buildGraphFromData(widget.networkData);
    _assignNodeColors();
    _runLayout();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(KeywordGraphChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkData != widget.networkData) {
      setState(() {
        _graph = _buildGraphFromData(widget.networkData);
        _selectedNodeId = null;
        _scale = 1.0;
        _panOffset = Offset.zero;
        _colorMap.clear();
        _assignNodeColors();
        _runLayout();
      });
    }
  }

  void _assignNodeColors() {
    for (int i = 0; i < _graph.nodes.length; i++) {
      _colorMap[_graph.nodes[i].id] = _nodeColors[i % _nodeColors.length];
    }
  }

  void _runLayout() {
    final nodes = _graph.nodes;
    final edges = _graph.edges;
    final n = nodes.length;

    for (int iter = 0; iter < 300; iter++) {
      // Repulsion
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          final delta = nodes[i].position - nodes[j].position;
          final dist = max(delta.distance, _minDist);
          final force = _repulsion / (dist * dist);
          final dir = delta / dist;
          nodes[i].velocity += dir * force;
          nodes[j].velocity -= dir * force;
        }
      }

      // Attraction along edges
      for (final edge in edges) {
        final si = nodes.indexWhere((nd) => nd.id == edge.source);
        final ti = nodes.indexWhere((nd) => nd.id == edge.target);
        if (si == -1 || ti == -1) continue;
        final delta = nodes[ti].position - nodes[si].position;
        final force = delta * _attraction * edge.weight;
        nodes[si].velocity += force;
        nodes[ti].velocity -= force;
      }

      // Apply + damping + cap
      for (final node in nodes) {
        node.velocity *= _damping;
        if (node.velocity.distance > 0.01) {
          node.velocity = node.velocity / node.velocity.distance * 0.01;
        }
        node.position += node.velocity;
        node.position = Offset(
          node.position.dx.clamp(0.12, 0.88),
          node.position.dy.clamp(0.12, 0.88),
        );
      }
    }

    for (final node in nodes) {
      node.velocity = Offset.zero;
    }

    _recenterNormalized();
  }

  void _recenterNormalized() {
    if (_graph.nodes.isEmpty) return;
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final node in _graph.nodes) {
      minX = min(minX, node.position.dx);
      minY = min(minY, node.position.dy);
      maxX = max(maxX, node.position.dx);
      maxY = max(maxY, node.position.dy);
    }

    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    final dx = 0.5 - cx;
    final dy = 0.5 - cy;

    for (final node in _graph.nodes) {
      node.position = Offset(
        (node.position.dx + dx).clamp(0.12, 0.88),
        (node.position.dy + dy).clamp(0.12, 0.88),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Offset _toCanvas(Offset normalized, Size canvas) {
    final pixel = Offset(
      normalized.dx * canvas.width,
      normalized.dy * canvas.height,
    );
    return pixel * _scale + _panOffset;
  }

  int? _hitTest(Offset localPos, Size canvas) {
    for (int i = _graph.nodes.length - 1; i >= 0; i--) {
      final nodePixel = _toCanvas(_graph.nodes[i].position, canvas);
      final r = _nodeRadius(_graph.nodes[i].id) * _scale;
      if ((localPos - nodePixel).distance < r + 6) return i;
    }
    return null;
  }

  double _nodeRadius(String id) {
    final count = _connectionCount(id);
    return (14 + count * 2.0).clamp(14.0, 28.0);
  }

  List<GraphEdge> _connectedEdges(String nodeId) => _graph.edges
      .where((e) => e.source == nodeId || e.target == nodeId)
      .toList();

  int _connectionCount(String nodeId) => _graph.edges
      .where((e) => e.source == nodeId || e.target == nodeId)
      .length;

  void _resetGraph() {
    setState(() {
      _panOffset = Offset.zero;
      _scale = 1.0;
      _selectedNodeId = null;
      _colorMap.clear();
      _graph = _buildGraphFromData(widget.networkData);
      _assignNodeColors();
      _runLayout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildControls(),
          const SizedBox(height: 12),
          Expanded(child: _buildCanvas()),
          AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            offset: _selectedNodeId == null
                ? const Offset(0, 0.15)
                : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              opacity: _selectedNodeId == null ? 0.0 : 1.0,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _selectedNodeId == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildRelationPanel(),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Keyword Network',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                Tooltip(
                  message:
                      "Shows how frequently mentioned keywords relate to each other. Keywords that appear together often are connected by a line.",
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
            SizedBox(height: 4),
            Text(
              'Relationships between keywords',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Graph',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_graph.nodes.length} nodes · ${_graph.edges.length} edges',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        _LegendPill(
          label: "Labels",
          color: _blue,
          active: _showLabels,
          onTap: () => setState(() => _showLabels = !_showLabels),
        ),
        const SizedBox(width: 8),
        _LegendPill(
          label: "Weights",
          color: _amber,
          active: _showWeights,
          onTap: () => setState(() => _showWeights = !_showWeights),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _resetGraph,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white38, size: 13),
                SizedBox(width: 4),
                Text(
                  'Reset',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanvas() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333355), width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

            return GestureDetector(
              onTapDown: (d) {
                final idx = _hitTest(d.localPosition, _canvasSize);
                setState(() {
                  if (idx != null) {
                    final id = _graph.nodes[idx].id;
                    _selectedNodeId = (_selectedNodeId == id) ? null : id;
                  } else {
                    _selectedNodeId = null;
                  }
                });
              },
              onScaleStart: (d) {
                final idx = _hitTest(d.localFocalPoint, _canvasSize);
                if (idx != null) {
                  setState(() {
                    _draggingIndex = idx;
                    _graph.nodes[idx].isPinned = true;
                  });
                }
              },
              onScaleUpdate: (d) {
                if (_draggingIndex != null) {
                  setState(() {
                    final normDelta = Offset(
                      d.focalPointDelta.dx / (_canvasSize.width * _scale),
                      d.focalPointDelta.dy / (_canvasSize.height * _scale),
                    );
                    _graph.nodes[_draggingIndex!].position = Offset(
                      (_graph.nodes[_draggingIndex!].position.dx + normDelta.dx)
                          .clamp(0.02, 0.98),
                      (_graph.nodes[_draggingIndex!].position.dy + normDelta.dy)
                          .clamp(0.02, 0.98),
                    );
                    _graph.nodes[_draggingIndex!].velocity = Offset.zero;
                  });
                } else if (d.scale != 1.0) {
                  setState(
                    () => _scale = (_scale * (1 + (d.scale - 1) * 0.1)).clamp(
                      0.3,
                      3.0,
                    ),
                  );
                } else {
                  setState(() => _panOffset += d.focalPointDelta);
                }
              },
              onScaleEnd: (d) {
                if (_draggingIndex != null) {
                  setState(() {
                    _graph.nodes[_draggingIndex!].isPinned = false;
                    _draggingIndex = null;
                  });
                }
              },
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _GraphPainter(
                      nodes: _graph.nodes,
                      edges: _graph.edges,
                      colorMap: _colorMap,
                      selectedId: _selectedNodeId,
                      panOffset: _panOffset,
                      scale: _scale,
                      pulseValue: _pulseAnim.value,
                      showLabels: _showLabels,
                      showWeights: _showWeights,
                      connectionCount: _connectionCount,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRelationPanel() {
    final edges = _connectedEdges(_selectedNodeId!);
    final color = _colorMap[_selectedNodeId] ?? _blue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                _selectedNodeId!.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${edges.length} connection${edges.length != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: edges.map((e) {
              final other = e.source == _selectedNodeId ? e.target : e.source;
              final arrow = e.source == _selectedNodeId ? '→' : '←';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  '$arrow $other  ·  ${e.relation}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOM PAINTER
// ─────────────────────────────────────────────
class _GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, Color> colorMap;
  final String? selectedId;
  final Offset panOffset;
  final double scale;
  final double pulseValue;
  final bool showLabels;
  final bool showWeights;
  final int Function(String) connectionCount;

  const _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.colorMap,
    required this.selectedId,
    required this.panOffset,
    required this.scale,
    required this.pulseValue,
    required this.showLabels,
    required this.showWeights,
    required this.connectionCount,
  });

  Set<String> get _connectedIds {
    if (selectedId == null) return {};
    final ids = <String>{selectedId!};
    for (final e in edges) {
      if (e.source == selectedId) ids.add(e.target);
      if (e.target == selectedId) ids.add(e.source);
    }
    return ids;
  }

  Offset _transform(Offset normalized, Size size) {
    final pixel = Offset(
      normalized.dx * size.width,
      normalized.dy * size.height,
    );
    return pixel * scale + panOffset;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final connected = _connectedIds;
    final hasSelection = selectedId != null;

    // ── Edges ──────────────────────────────────────────────────
    for (final edge in edges) {
      final si = nodes.indexWhere((n) => n.id == edge.source);
      final ti = nodes.indexWhere((n) => n.id == edge.target);
      if (si == -1 || ti == -1) continue;

      final src = _transform(nodes[si].position, size);
      final tgt = _transform(nodes[ti].position, size);

      final isHighlighted =
          hasSelection &&
          connected.contains(edge.source) &&
          connected.contains(edge.target);

      final edgeColor = isHighlighted
          ? (colorMap[selectedId] ?? const Color(0xFF4FC3F7))
          : const Color(0xFF333355);
      final opacity = hasSelection ? (isHighlighted ? 0.9 : 0.15) : 0.5;

      canvas.drawLine(
        src,
        tgt,
        Paint()
          ..color = edgeColor.withValues(alpha: opacity)
          ..strokeWidth = isHighlighted
              ? (1.5 + edge.weight * 2.0) * scale
              : 1.0 * scale
          ..style = PaintingStyle.stroke,
      );

      if (showWeights && isHighlighted) {
        _drawLabel(
          canvas,
          '${(edge.weight * 100).round()}%',
          Offset((src.dx + tgt.dx) / 2, (src.dy + tgt.dy) / 2),
          const Color(0xFFFFB74D),
          9,
        );
      }

      if (isHighlighted) {
        _drawArrow(
          canvas,
          src,
          tgt,
          edgeColor.withValues(alpha: opacity),
          scale,
        );
      }
    }

    // ── Nodes ──────────────────────────────────────────────────
    for (final node in nodes) {
      final pos = _transform(node.position, size);
      final color = colorMap[node.id] ?? const Color(0xFF4FC3F7);
      final nodeIsSelected = node.id == selectedId;
      final isConnected = connected.contains(node.id);
      final fade = hasSelection && !isConnected;

      final baseRadius =
          (14 + connectionCount(node.id) * 2.0).clamp(14.0, 28.0) * scale;
      final radius = nodeIsSelected ? baseRadius * pulseValue : baseRadius;

      if (nodeIsSelected || isConnected) {
        canvas.drawCircle(
          pos,
          radius * 1.5,
          Paint()
            ..color = color.withValues(alpha: nodeIsSelected ? 0.25 : 0.1)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8),
        );
      }

      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = color.withValues(
            alpha: fade ? 0.12 : (nodeIsSelected ? 0.25 : 0.15),
          ),
      );

      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = color.withValues(
            alpha: fade ? 0.2 : (nodeIsSelected ? 1.0 : 0.7),
          )
          ..strokeWidth = (nodeIsSelected ? 2.0 : 1.2) * scale
          ..style = PaintingStyle.stroke,
      );

      if (showLabels) {
        _drawLabel(
          canvas,
          node.label,
          pos,
          fade
              ? Colors.white.withValues(alpha: 0.2)
              : (nodeIsSelected ? color : Colors.white.withValues(alpha: 0.85)),
          10 * scale,
        );
      }
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset pos,
    Color color,
    double fontSize,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize.clamp(8, 14),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double scale,
  ) {
    final dir = to - from;
    if (dir.distance == 0) return;
    final norm = dir / dir.distance;
    final arrowSize = 8.0 * scale;
    final tip = to - norm * (20 * scale);
    final left =
        tip - Offset(-norm.dy, norm.dx) * arrowSize * 0.5 - norm * arrowSize;
    final right =
        tip - Offset(norm.dy, -norm.dx) * arrowSize * 0.5 - norm * arrowSize;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_GraphPainter old) => true;
}

// ─────────────────────────────────────────────
// LEGEND PILL
// ─────────────────────────────────────────────
class _LegendPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _LegendPill({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.6) : Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? color : Colors.white24,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
