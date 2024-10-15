import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'geofence_component.dart';

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

  // Initial polygons
  List<Map<String, dynamic>> initialPolygons = [
    {
      'name': "San Francisco Geofence 1",
      'orgId': "SF111",
      'polygon': [
        [
          {'latitude': 37.7749, 'longitude': -122.4194}, // Polygon 1 - Point A
          {'latitude': 37.7799, 'longitude': -122.4194}, // Point B
          {'latitude': 37.7799, 'longitude': -122.4144}, // Point C
          {'latitude': 37.7749, 'longitude': -122.4144}, // Point D
        ],
        // Additional polygons can be added here
      ],
    },
    {
      'name': "San Francisco Geofence 2",
      'orgId': "SF222",
      'polygon': [
        [
          {'latitude': 37.7849, 'longitude': -122.4294}, // Polygon 2 - Point A
          {'latitude': 37.7899, 'longitude': -122.4294}, // Point B
          {'latitude': 37.7899, 'longitude': -122.4244}, // Point C
          {'latitude': 37.7849, 'longitude': -122.4244}, // Point D
        ],
        // Additional polygons can be added here
      ],
    }
    // Add more polygons as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Demo'),
      ),
      body: GeofenceComponent(initialGeofence: initialPolygons[0]),
    );
  }
}
