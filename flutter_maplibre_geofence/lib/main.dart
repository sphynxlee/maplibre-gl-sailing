import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math'; // Import this for math functions

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Geofence Demo')),
        body: const GeofencingMap(),
      ),
    );
  }
}

class GeofencingMap extends StatefulWidget {
  const GeofencingMap({super.key});

  @override
  GeofencingMapState createState() => GeofencingMapState();
}

class GeofencingMapState extends State<GeofencingMap> {
  MapLibreMapController? mapController;
  Location location = Location();
  LatLng geofenceCenter = const LatLng(37.7749, -122.4194); // Example center (San Francisco)
  double geofenceRadius = 500.0; // 500 meters
  Fill? geofenceFill; // Store the geofence fill layer

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions(); // Check for location permissions when the app starts
    location.onLocationChanged.listen((LocationData currentLocation) {
      print("Location updated: ${currentLocation.latitude}, ${currentLocation.longitude}");
      _checkGeofence(LatLng(currentLocation.latitude!, currentLocation.longitude!));
    });
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

  // Add geofence circle to the map as a polygon
  Future<void> _addGeofenceLayer() async {
    if (mapController == null) {
      Future.delayed(const Duration(milliseconds: 100), _addGeofenceLayer);
      return;
    }

    List<LatLng> circlePolygon = _createCirclePolygon(geofenceCenter, geofenceRadius);

    Fill fill = await mapController!.addFill(
      FillOptions(
        geometry: [circlePolygon],
        fillColor: "#FF0000",
        fillOpacity: 0.3,
      ),
    );

    geofenceFill = fill; // Store the fill layer

    mapController!.moveCamera(CameraUpdate.newLatLngZoom(geofenceCenter, 14));
  }

  // Create circle polygon coordinates
  List<LatLng> _createCirclePolygon(LatLng center, double radiusInMeters, {int points = 64}) {
    double earthRadius = 6378137.0; // Earth's radius in meters
    double lat = center.latitude * (pi / 180.0);
    double lng = center.longitude * (pi / 180.0);

    double d = radiusInMeters / earthRadius;

    List<LatLng> positions = [];

    for (int i = 0; i <= points; i++) {
      double bearing = i * 2 * pi / points;
      double latRadians = asin(sin(lat) * cos(d) + cos(lat) * sin(d) * cos(bearing));
      double lngRadians = lng + atan2(
        sin(bearing) * sin(d) * cos(lat),
        cos(d) - sin(lat) * sin(latRadians),
      );

      positions.add(LatLng(latRadians * (180.0 / pi), lngRadians * (180.0 / pi)));
    }

    return positions;
  }

  // Check if the user's current location is inside the geofence
  void _checkGeofence(LatLng userLocation) {
    double distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      geofenceCenter.latitude,
      geofenceCenter.longitude,
    );

    if (distance <= geofenceRadius) {
      print("User is inside the geofence");
    } else {
      print("User is outside the geofence");
    }
  }

  // Initialize the map controller and add the geofence when the map is created
  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
    _addGeofenceLayer();
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: geofenceCenter, // Use geofenceCenter here
        zoom: 14.0, // Zoom level for better visibility of the geofence
      ),
      rotateGesturesEnabled: true,
      styleString: "https://demotiles.maplibre.org/style.json", // Use a valid MapLibre style here
    );
  }

  @override
  void dispose() {
    super.dispose();
    // Remove geofence fill if necessary
    if (geofenceFill != null) {
      mapController?.removeFill(geofenceFill!);
    }
  }
}
