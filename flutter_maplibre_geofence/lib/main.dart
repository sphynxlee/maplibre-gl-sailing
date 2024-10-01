import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

import 'polygon_geofence.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geofence Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GeofenceHomePage(),
    );
  }
}

class GeofenceHomePage extends StatefulWidget {
  const GeofenceHomePage({super.key});

  @override
  GeofenceHomePageState createState() => GeofenceHomePageState();
}

class GeofenceHomePageState extends State<GeofenceHomePage> {
  MapLibreMapController? mapController;
  Location location = Location();

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    // Optionally, listen to location changes here.
  }

  // Checking and requesting location permissions
  void _checkLocationPermissions() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  // Initialize the map controller
  void _onMapCreated(MapLibreMapController controller) {
    print('Map has been created.');
    setState(() {
      mapController = controller;
    });
  }

  void _onStyleLoaded() {
    addImageFromAsset("custom-marker", "assets/symbols/custom-marker.png");
    addImageFromAsset("user-marker", "assets/symbols/user-marker.png");
    print('Map style has been loaded.');
  }

  // Adds an asset image to the currently displayed style
  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final list = bytes.buffer.asUint8List();
    return mapController!.addImage(name, list);
  }

  void _onMapClick(Point<double> point, LatLng coordinates) {
    print('Map click at: $coordinates');
  }

  @override
  Widget build(BuildContext context) {
    Widget geofenceWidget;

  geofenceWidget = PolygonGeofence(mapController: mapController);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Demo'),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapClick,
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.7749, -122.4194), // San Francisco
              zoom: 14.0,
            ),
            // styleString: "https://api.maptiler.com/maps/streets-v2/style.json?key=QBMCVBrM2oLPkQgiPdQV",
            styleString: 'https://api.maptiler.com/maps/streets/style.json?key=QBMCVBrM2oLPkQgiPdQV',
            rotateGesturesEnabled: true,
          ),
          geofenceWidget,
          const Positioned(
            bottom: 10,
            right: 10,
            child: Text(
              "© OpenStreetMap contributors",
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
