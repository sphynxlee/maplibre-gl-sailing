import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

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
  LatLng geofenceCenter = const LatLng(37.7749, -122.4194);  // Example center (San Francisco)
  double geofenceRadius = 500.0;  // 500 meters

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();  // Check for location permissions when the app starts
    location.onLocationChanged.listen((LocationData currentLocation) {
      print("Location updated: ${currentLocation.latitude}, ${currentLocation.longitude}");
      _checkGeofence(LatLng(currentLocation.latitude!, currentLocation.longitude!));
    });
    // Add this line to ensure the geofence is added even if onMapCreated is not called
    WidgetsBinding.instance.addPostFrameCallback((_) => _addGeofenceLayer());
  }

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

  void _addGeofenceLayer() {
    if (mapController == null) {
      // If mapController is null, retry after a short delay
      Future.delayed(Duration(milliseconds: 100), _addGeofenceLayer);
      return;
    }

    mapController!.addCircle(
      CircleOptions(
        geometry: geofenceCenter,
        circleRadius: geofenceRadius,  // Use meters directly
        circleColor: "#FF0000",
        circleOpacity: 0.3,
        circleStrokeWidth: 2,  // Add a stroke to make the circle more visible
        circleStrokeColor: "#FF0000",
      ),
    );

    // Center the map on the geofence
    mapController!.moveCamera(CameraUpdate.newLatLngZoom(geofenceCenter, 14));
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

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
    _addGeofenceLayer();
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: geofenceCenter,  // Use geofenceCenter here
        zoom: 14.0,  // Increase initial zoom level
      ),
      rotateGesturesEnabled: true,
      styleString: MapLibreStyles.demo,
    );
  }
}
