import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:civic_contribution/domain/models/issue.dart';

abstract class MapAdapter {
  Widget buildMap({
    required LatLng center,
    required double zoom,
    required List<Issue> issues,
    required Function(Issue) onMarkerTap,
  });
}

