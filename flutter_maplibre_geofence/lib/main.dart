import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'geofence_component.dart';
import 'geofence_interfaces.dart';

// import 'package:flutter/foundation.dart' show kIsWeb;
// import './common/service/web_specific_code.dart' if (dart.library.io) 'mobile_specific_code.dart';

void main() {
  // if (kIsWeb) {
  //   initializeForWeb();
  // }
  runApp(const MaterialApp(home: GeofenceHomePage()));
}

class GeofenceHomePage extends StatefulWidget {
  const GeofenceHomePage({super.key});

  @override
  State createState() => GeofenceHomePageState();
}

class GeofenceHomePageState extends State<GeofenceHomePage> {
  MapLibreMapController? mapController;

  // Initial polygons with the new Geofence class
  final List<Geofence> initialPolygons = [
    Geofence(
      name: "San Francisco Geofence 1",
      orgId: "SF111",
      polygon: [
        const LatLng(37.7749, -122.4194), // Polygon 1 - Point A
        const LatLng(37.7799, -122.4194), // Point B
        const LatLng(37.7799, -122.4144), // Point C
        const LatLng(37.7749, -122.4144), // Point D
      ],
    ),
    Geofence(
      name: "San Francisco Geofence 2",
      orgId: "SF222",
      polygon: [
        const LatLng(37.7849, -122.4294), // Polygon 2 - Point A
        const LatLng(37.7899, -122.4294), // Point B
        const LatLng(37.7899, -122.4244), // Point C
        const LatLng(37.7849, -122.4244), // Point D
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Demo'),
      ),
      body: GeofenceComponent(initialPolygons: initialPolygons),
    );
  }
}
