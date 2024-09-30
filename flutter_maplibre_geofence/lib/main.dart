import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';

import 'circle_geofence.dart';
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
  _GeofenceHomePageState createState() => _GeofenceHomePageState();
}

class _GeofenceHomePageState extends State<GeofenceHomePage> {
  MapLibreMapController? mapController;
  Location location = Location();

  String _selectedGeofence = 'none'; // 'none', 'circle', 'polygon'

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
    print('Map style has been loaded.');
  }

  void _selectGeofence(String geofenceType) {
    setState(() {
      _selectedGeofence = geofenceType;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget geofenceWidget;

    if (_selectedGeofence == 'circle') {
      geofenceWidget = CircleGeofence(mapController: mapController);
    } else if (_selectedGeofence == 'polygon') {
      geofenceWidget = PolygonGeofence(mapController: mapController);
    } else {
      geofenceWidget = Container(); // Empty container when no geofence is selected
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Demo'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _selectGeofence,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'circle',
                  child: Text('Circle Geofence'),
                ),
                const PopupMenuItem<String>(
                  value: 'polygon',
                  child: Text('Polygon Geofence'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.7749, -122.4194), // San Francisco
              zoom: 14.0,
            ),
            styleString: "https://api.maptiler.com/maps/streets-v2/style.json?key=QBMCVBrM2oLPkQgiPdQV",
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
