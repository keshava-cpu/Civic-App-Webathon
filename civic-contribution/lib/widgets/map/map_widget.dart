import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/issue.dart';
import 'map_adapter.dart';
import 'osm_map_adapter.dart';

class MapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Issue> issues;
  final Function(Issue) onMarkerTap;
  final MapAdapter? adapter;

  const MapWidget({
    super.key,
    required this.center,
    required this.zoom,
    required this.issues,
    required this.onMarkerTap,
    this.adapter,
  });

  @override
  Widget build(BuildContext context) {
    final mapAdapter = adapter ?? OsmMapAdapter();
    return mapAdapter.buildMap(
      center: center,
      zoom: zoom,
      issues: issues,
      onMarkerTap: onMarkerTap,
    );
  }
}
