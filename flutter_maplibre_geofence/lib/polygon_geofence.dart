// polygon_geofence.dart

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

class PolygonGeofence extends StatefulWidget {
  final MapLibreMapController? mapController;

  const PolygonGeofence({Key? key, required this.mapController}) : super(key: key);

  @override
  _PolygonGeofenceState createState() => _PolygonGeofenceState();
}

class _PolygonGeofenceState extends State<PolygonGeofence> {
  List<LatLng> geofencePolygon = [
    LatLng(37.7749, -122.4194), // Point A
    LatLng(37.7799, -122.4194), // Point B
    LatLng(37.7799, -122.4144), // Point C
    LatLng(37.7749, -122.4144), // Point D
    LatLng(37.7749, -122.4194), // Closing the polygon back to Point A
  ];
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
  void didUpdateWidget(covariant PolygonGeofence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController == null && widget.mapController != null) {
      _addGeofenceLayer();
    }
  }

  // Add geofence polygon to the map as a fill
  Future<void> _addGeofenceLayer() async {
    if (widget.mapController == null) {
      return;
    }
    print('Adding polygon geofence layer.');

    Fill fill = await widget.mapController!.addFill(
      FillOptions(
        geometry: [geofencePolygon],
        fillColor: "#FF0000",
        fillOpacity: 0.3,
      ),
    );

    geofenceFill = fill; // Store the fill layer

    // Adjust the camera to fit the polygon
    LatLngBounds bounds = _getPolygonBounds(geofencePolygon);
    widget.mapController!.moveCamera(CameraUpdate.newLatLngBounds(bounds));
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
      if ((polygon[i].longitude < point.longitude && polygon[j].longitude >= point.longitude ||
           polygon[j].longitude < point.longitude && polygon[i].longitude >= point.longitude) &&
          (polygon[i].latitude <= point.latitude || polygon[j].latitude <= point.latitude)) {
        if (polygon[i].latitude + (point.longitude - polygon[i].longitude) / (polygon[j].longitude - polygon[i].longitude) * (polygon[j].latitude - polygon[i].latitude) < point.latitude) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }

    return oddNodes;
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
