// polygon_geofence_page.dart

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

class PolygonGeofencePage extends StatefulWidget {
  const PolygonGeofencePage({super.key});

  @override
  PolygonGeofencePageState createState() => PolygonGeofencePageState();
}

class PolygonGeofencePageState extends State<PolygonGeofencePage> {
  MapLibreMapController? mapController;
  Location location = Location();
  List<LatLng> geofencePolygon = [
    const LatLng(37.7749, -122.4194), // Point A
    const LatLng(37.7799, -122.4194), // Point B
    const LatLng(37.7799, -122.4144), // Point C
    const LatLng(37.7749, -122.4144), // Point D
    const LatLng(37.7749, -122.4194), // Closing the polygon back to Point A
  ];
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

  // Add geofence polygon to the map as a fill
  Future<void> _addGeofenceLayer() async {
    if (mapController == null) {
      print('mapController is null, retrying _addGeofenceLayer...');
      Future.delayed(const Duration(milliseconds: 100), _addGeofenceLayer);
      return;
    }
    print('Adding geofence layer.');

    Fill fill = await mapController!.addFill(
      FillOptions(
        geometry: [geofencePolygon],
        fillColor: "#FF0000",
        fillOpacity: 0.3,
      ),
    );

    geofenceFill = fill; // Store the fill layer

    // Adjust the camera to fit the polygon
    LatLngBounds bounds = _getPolygonBounds(geofencePolygon);
    mapController!.moveCamera(CameraUpdate.newLatLngBounds(bounds));
  }

  LatLngBounds _getPolygonBounds(List<LatLng> polygon) {
    double? minLat, maxLat, minLng, maxLng;

    for (LatLng point in polygon) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  // Check if the user's current location is inside the geofence polygon
  void _checkGeofence(LatLng userLocation) {
    if (_isPointInPolygon(userLocation, geofencePolygon)) {
      print("User is inside the geofence");
    } else {
      print("User is outside the geofence");
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int i, j = polygon.length - 1;
    bool oddNodes = false;

    for (i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude < point.longitude && polygon[j].longitude >= point.longitude || polygon[j].longitude < point.longitude && polygon[i].longitude >= point.longitude) &&
          (polygon[i].latitude <= point.latitude || polygon[j].latitude <= point.latitude)) {
        if (polygon[i].latitude + (point.longitude - polygon[i].longitude) / (polygon[j].longitude - polygon[i].longitude) * (polygon[j].latitude - polygon[i].latitude) < point.latitude) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }

    return oddNodes;
  }

  // Initialize the map controller and add the geofence when the map is created
  void _onMapCreated(MapLibreMapController controller) {
    print('Map has been created.');
    mapController = controller;
    _addGeofenceLayer();
  }

  void _onStyleLoaded() {
    print('Map style has been loaded.');
    _addGeofenceLayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polygon Geofence'),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition: CameraPosition(
              target: geofencePolygon[0],
              zoom: 14.0,
            ),
            styleString: "https://api.maptiler.com/maps/streets-v2/style.json?key=QBMCVBrM2oLPkQgiPdQV",
            rotateGesturesEnabled: true,
          ),
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

  @override
  void dispose() {
    super.dispose();
    // Remove geofence fill if necessary
    if (geofenceFill != null) {
      mapController?.removeFill(geofenceFill!);
    }
  }
}
