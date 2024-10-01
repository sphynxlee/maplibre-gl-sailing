// circle_geofence.dart

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math'; // For math functions

class CircleGeofence extends StatefulWidget {
  final MapLibreMapController? mapController;

  const CircleGeofence({super.key, required this.mapController});

  @override
  CircleGeofenceState createState() => CircleGeofenceState();
}

class CircleGeofenceState extends State<CircleGeofence> {
  LatLng geofenceCenter = const LatLng(37.7749, -122.4194); // Example center (San Francisco)
  double geofenceRadius = 500.0; // 500 meters 2
  Fill? geofenceFill; // Store the geofence fill layer
  Location location = Location();

  @override
  void initState() {
    super.initState();
    if (widget.mapController != null) {
      _addGeofenceLayer();
    }
    // Listen to location changes
    location.onLocationChanged.listen((LocationData currentLocation) {
      print("Location updated: ${currentLocation.latitude}, ${currentLocation.longitude}");
      _checkGeofence(LatLng(currentLocation.latitude!, currentLocation.longitude!));
    });
  }

  @override
  void didUpdateWidget(covariant CircleGeofence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController == null && widget.mapController != null) {
      _addGeofenceLayer();
    }
  }

  // Add geofence circle to the map as a polygon
  Future<void> _addGeofenceLayer() async {
    if (widget.mapController == null) {
      return;
    }
    print('Adding circle geofence layer.');

    List<LatLng> circlePolygon = _createCirclePolygon(geofenceCenter, geofenceRadius);

    Fill fill = await widget.mapController!.addFill(
      FillOptions(
        geometry: [circlePolygon],
        fillColor: "#FF0000",
        fillOpacity: 0.3,
      ),
    );

    geofenceFill = fill; // Store the fill layer

    widget.mapController!.moveCamera(CameraUpdate.newLatLngZoom(geofenceCenter, 14));
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
      double lngRadians = lng +
          atan2(
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

  @override
  void dispose() {
    super.dispose();
    // Remove geofence fill if necessary
    if (geofenceFill != null && widget.mapController != null) {
      widget.mapController?.removeFill(geofenceFill!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // No UI needed here
  }
}
