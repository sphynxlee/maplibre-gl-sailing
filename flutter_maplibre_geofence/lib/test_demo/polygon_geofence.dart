// polygon_geofence.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:location/location.dart';

class PolygonGeofence extends StatefulWidget {
  final MapLibreMapController? mapController;
  const PolygonGeofence({super.key, required this.mapController});

  @override
  PolygonGeofenceState createState() => PolygonGeofenceState();
}

class PolygonGeofenceState extends State<PolygonGeofence> {
  List<LatLng> geofencePolygon = [
    const LatLng(37.7749, -122.4194), // Point A
    const LatLng(37.7799, -122.4194), // Point B
    const LatLng(37.7799, -122.4144), // Point C
    const LatLng(37.7749, -122.4144), // Point D
    const LatLng(37.7749, -122.4194), // Closing the polygon back to Point A
  ];

  Map<String, int> symbolIdToIndex = {};
  List<Symbol> vertexMarkers = [];
  Fill? geofenceFill;
  Line? edgeLine;

  Location location = Location();
  LocationData? currentLocation;
  Symbol? userMarker;
  String TAG = "===== PolygonGeofence =====";

  @override
  void initState() {
    super.initState();
    if (widget.mapController != null) {
      _addGeofenceLayer();
      if (currentLocation != null) {
        _addUserMarker();
      }
    }

    // Listen to location changes
    location.onLocationChanged.listen((LocationData newLocation) {
      print('$TAG, Location updated: ${newLocation.latitude}, ${newLocation.longitude}');
      setState(() {
        // currentLocation = newLocation;
        currentLocation = LocationData.fromMap({
          'latitude': 37.7739,
          'longitude': -122.4194,
        });
      });
      _checkGeofence(LatLng(newLocation.latitude!, newLocation.longitude!));

      // Add or update the user marker if mapController is available
      if (widget.mapController != null) {
        _addUserMarker();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PolygonGeofence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController == null && widget.mapController != null) {
      _addGeofenceLayer();
      if (currentLocation != null) {
        _addUserMarker();
      }
      widget.mapController!.onSymbolTapped.add(_onSymbolTapped);
      // widget.mapController!.onSymbolDrag.add(_onSymbolDrag);
      // widget.mapController!.onSymbolDragEnd.add(_onSymbolDragEnd);
    }
  }

  Future<void> _addUserMarker() async {
    if (currentLocation != null && widget.mapController != null) {
      if (userMarker == null) {
        // First time, add the symbol
        userMarker = await widget.mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
            iconImage: 'user-marker', // Ensure this icon exists in your map style
          ),
        );
      } else {
        // Update existing symbol's position
        await widget.mapController!.updateSymbol(
          userMarker!,
          SymbolOptions(
            geometry: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          ),
        );
      }
    }
  }

  // Add geofence polygon to the map as a fill
  Future<void> _addGeofenceLayer() async {
    if (widget.mapController == null) {
      return;
    }
    print('$TAG, Adding polygon geofence layer.');

    // Remove existing fills, markers, and lines if they exist
    if (geofenceFill != null) {
      await widget.mapController!.removeFill(geofenceFill!);
      geofenceFill = null;
    }
    if (vertexMarkers.isNotEmpty) {
      await widget.mapController!.removeSymbols(vertexMarkers);
      vertexMarkers.clear();
      symbolIdToIndex.clear();
    }
    if (edgeLine != null) {
      await widget.mapController!.removeLine(edgeLine!);
      edgeLine = null;
    }

    // Add the polygon fill
    geofenceFill = await widget.mapController!.addFill(
      FillOptions(
        geometry: [geofencePolygon],
        fillColor: "#FF0000",
        fillOpacity: 0.3,
      ),
    );

    // Add markers for each vertex
    for (int i = 0; i < geofencePolygon.length; i++) {
      LatLng point = geofencePolygon[i];
      Symbol marker = await widget.mapController!.addSymbol(
        SymbolOptions(
          geometry: point,
          iconImage: 'custom-marker', // Ensure this icon is available in your style
          draggable: true,
        ),
      );
      symbolIdToIndex[marker.id] = i; // Map symbol ID to index
      vertexMarkers.add(marker);
    }

    // Draw the edges as a line
    edgeLine = await widget.mapController!.addLine(
      LineOptions(
        geometry: geofencePolygon,
        lineColor: "#0000FF",
        lineWidth: 2.0,
      ),
    );

    // Adjust the camera to fit the polygon
    // LatLngBounds bounds = _getPolygonBounds(geofencePolygon);
    // widget.mapController!.moveCamera(CameraUpdate.newLatLngBounds(bounds));
  }

  void _onSymbolTapped(Symbol symbol) {
    print('$TAG, Symbol tapped: ${symbol.id}');
  }

  void _onSymbolDrag(Symbol symbol) {
    int index = symbolIdToIndex[symbol.id]!;
    LatLng newPosition = symbol.options.geometry!;
    setState(() {
      geofencePolygon[index] = newPosition;
    });
    _updateGeofenceLayer();
  }

  void _onSymbolDragEnd(Symbol symbol) {
    // Finalize the drag
    _onSymbolDrag(symbol);
  }

  void handleMapClick(Point<double> point, LatLng coordinates) async {
    if (widget.mapController == null) return;

    // Check if the tap is near any edge
    int? nearestEdgeIndex = await _findNearestEdge(point);
    if (nearestEdgeIndex != null) {
      // Insert new vertex into the polygon
      setState(() {
        geofencePolygon.insert(nearestEdgeIndex + 1, coordinates);
      });
      await _addGeofenceLayer(); // Re-add the geofence layer
    }
  }

  void _onMapClick(Point<double> point, LatLng coordinates) async {
    if (widget.mapController == null) return;

    // Check if the tap is near any edge
    int? nearestEdgeIndex = await _findNearestEdge(point);
    if (nearestEdgeIndex != null) {
      // Insert new vertex into the polygon
      setState(() {
        geofencePolygon.insert(nearestEdgeIndex + 1, coordinates);
      });
      await _addGeofenceLayer(); // Re-add the geofence layer
    }
  }

  Future<int?> _findNearestEdge(Point<num> tapPoint) async {
    const double threshold = 20.0; // pixels
    for (int i = 0; i < geofencePolygon.length - 1; i++) {
      LatLng point1 = geofencePolygon[i];
      LatLng point2 = geofencePolygon[i + 1];

      // Convert LatLng to screen coordinates
      Point<num> screenPoint1 = await widget.mapController!.toScreenLocation(point1);
      Point<num> screenPoint2 = await widget.mapController!.toScreenLocation(point2);

      // Check if the tap point is near the edge
      if (_isPointNearLine(point: tapPoint, lineStart: screenPoint1, lineEnd: screenPoint2, threshold: threshold)) {
        return i; // Return the index of the edge
      }
    }
    return null;
  }

  bool _isPointNearLine({
    required Point<num> point,
    required Point<num> lineStart,
    required Point<num> lineEnd,
    required double threshold,
  }) {
    double x0 = point.x.toDouble();
    double y0 = point.y.toDouble();
    double x1 = lineStart.x.toDouble();
    double y1 = lineStart.y.toDouble();
    double x2 = lineEnd.x.toDouble();
    double y2 = lineEnd.y.toDouble();

    double numerator = ((x2 - x1) * (y1 - y0) - (x1 - x0) * (y2 - y1)).abs();
    double denominator = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));

    double distance = numerator / denominator;

    return distance <= threshold;
  }

  Future<void> _updateGeofenceLayer() async {
    if (widget.mapController == null) {
      return;
    }

    // Update the polygon fill
    if (geofenceFill != null) {
      await widget.mapController!.updateFill(
        geofenceFill!,
        FillOptions(
          geometry: [geofencePolygon],
        ),
      );
    }

    // Update the line (edges)
    if (edgeLine != null) {
      await widget.mapController!.updateLine(
        edgeLine!,
        LineOptions(
          geometry: geofencePolygon,
        ),
      );
    }

    // Update the positions of the markers
    for (int i = 0; i < vertexMarkers.length; i++) {
      Symbol marker = vertexMarkers[i];
      await widget.mapController!.updateSymbol(
        marker,
        SymbolOptions(
          geometry: geofencePolygon[i],
        ),
      );
    }
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
      print('$TAG, User is inside the geofence');
    } else {
      print('$TAG, User is outside the geofence');
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int i, j = polygon.length - 1;
    bool oddNodes = false;

    for (i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude < point.latitude && polygon[j].latitude >= point.latitude || polygon[j].latitude < point.latitude && polygon[i].latitude >= point.latitude) &&
          (polygon[i].longitude <= point.longitude || polygon[j].longitude <= point.longitude)) {
        if (polygon[i].longitude + (point.latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) * (polygon[j].longitude - polygon[i].longitude) < point.longitude) {
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
    // Remove markers
    if (vertexMarkers.isNotEmpty) {
      widget.mapController?.removeSymbols(vertexMarkers);
    }
    // Remove user marker
    if (userMarker != null && widget.mapController != null) {
      widget.mapController?.removeSymbol(userMarker!);
    }
    // Remove line
    if (edgeLine != null && widget.mapController != null) {
      widget.mapController?.removeLine(edgeLine!);
    }
    // Remove event listeners
    widget.mapController?.onSymbolTapped.remove(_onSymbolTapped);
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // No UI needed here
  }
}
