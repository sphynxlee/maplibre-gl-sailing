import 'package:maplibre_gl/maplibre_gl.dart';

class Geofence {
  final String name;
  final String orgId;
  final List<LatLng> polygon;

  Geofence({
    required this.name,
    required this.orgId,
    required this.polygon,
  });
}
