import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:civic_contribution/domain/constants.dart';
import 'package:civic_contribution/domain/models/issue.dart';
import 'map_adapter.dart';

class OsmMapAdapter implements MapAdapter {
  @override
  Widget buildMap({
    required LatLng center,
    required double zoom,
    required List<Issue> issues,
    required Function(Issue) onMarkerTap,
  }) {
    return _OsmMap(
      center: center,
      zoom: zoom,
      issues: issues,
      onMarkerTap: onMarkerTap,
    );
  }
}

class _OsmMap extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final List<Issue> issues;
  final Function(Issue) onMarkerTap;

  const _OsmMap({
    required this.center,
    required this.zoom,
    required this.issues,
    required this.onMarkerTap,
  });

  @override
  State<_OsmMap> createState() => _OsmMapState();
}

class _OsmMapState extends State<_OsmMap> {
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(_OsmMap old) {
    super.didUpdateWidget(old);
    final centerChanged = widget.center != old.center;

    // Move to new center only on explicit center updates.
    if (centerChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.move(widget.center, widget.zoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
        minZoom: 5,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hackathon.civic_contribution',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: widget.issues
              .where((issue) => issue.hasValidLocation) // Filter valid locations
              .map((issue) {
            return Marker(
              point: LatLng(
                issue.location.latitude,
                issue.location.longitude,
              ),
              width: 56,
              height: 56,
              child: GestureDetector(
                onTap: () => widget.onMarkerTap(issue),
                child: _MarkerWidget(issue: issue),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MarkerWidget extends StatelessWidget {
  final Issue issue;
  const _MarkerWidget({required this.issue});

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(issue.status);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              issue.category.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        // Teardrop tail
        CustomPaint(
          size: const Size(12, 8),
          painter: _TailPainter(color: color),
        ),
      ],
    );
  }

  Color _colorForStatus(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending:
        return Colors.orange;
      case IssueStatus.assigned:
        return Colors.blue;
      case IssueStatus.inProgress:
        return Colors.purple;
      case IssueStatus.resolved:
        return Colors.teal;
      case IssueStatus.verified:
        return Colors.green;
    }
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  const _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

