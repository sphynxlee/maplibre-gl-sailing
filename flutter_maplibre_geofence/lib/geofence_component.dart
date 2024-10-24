import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

import './common/service/logger.dart';
import 'geofence_interfaces.dart';

class GeofenceComponent {
  static const String TAG = 'Geofence-Component';

  final MapLibreMapController mapController;
  final List<Geofence> initialPolygons;

  List<List<LatLng>> geofenceArrays = [];
  List<List<Symbol>> markers = [];
  List<List<Line>> lines = [];
  List<Fill?> polygonFills = [];
  List<LatLng> currentGeofence = [];

  Symbol? selectedLineSymbol;
  int? selectedPolygonIndex;
  int? selectedLineIndex;

  bool isDrawingPolygon = false;

  GeofenceComponent({
    required this.mapController,
    required this.initialPolygons,
  }) {
    _initialize();
  }

  void onLocationUpdate(LatLng currentLocation) {
    MapLogger.log('$TAG: Current location: $currentLocation');
    MapLogger.log('$TAG: Number of geofences: ${geofenceArrays.length}');

    for (int i = 0; i < geofenceArrays.length; i++) {
      MapLogger.log('$TAG: Geofence $i coordinates: ${geofenceArrays[i]}');
      bool isInside = _isPointInPolygon(currentLocation, geofenceArrays[i]);
      MapLogger.log('$TAG: Is inside geofence $i: $isInside');

      if (isInside) {
        // Vehicle is inside the geofence
        MapLogger.log('$TAG: Vehicle is inside geofence $i');
        _onGeofenceEnter(i);
      } else {
        // Vehicle is outside the geofence
        MapLogger.log('$TAG: Vehicle is outside geofence $i');
        _onGeofenceExit(i);
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      LatLng vertex1 = polygon[j];
      LatLng vertex2 = polygon[j + 1];
      if (_rayCastIntersect(point, vertex1, vertex2)) {
        intersectCount++;
      }
    }
    bool result = (intersectCount % 2) == 1;
    MapLogger.log('$TAG: Point $point, Intersect count: $intersectCount, Is inside: $result');
    return result;
  }

  bool _rayCastIntersect(LatLng point, LatLng vertex1, LatLng vertex2) {
    double px = point.longitude;
    double py = point.latitude;
    double v1x = vertex1.longitude;
    double v1y = vertex1.latitude;
    double v2x = vertex2.longitude;
    double v2y = vertex2.latitude;

    if ((v1y > py && v2y > py) || (v1y < py && v2y < py) || (v1x < px && v2x < px)) {
      return false;
    }

    double m = (v2y - v1y) / (v2x - v1x);
    double bee = v1y - m * v1x;
    double x = (py - bee) / m;

    return x > px;
  }

  void _onGeofenceEnter(int index) {
    // Handle geofence enter event
    MapLogger.log('$TAG: Handling geofence enter for polygon $index');
    // Add your custom logic here
  }

  void _onGeofenceExit(int index) {
    // Handle geofence exit event
    MapLogger.log('$TAG: Handling geofence exit for polygon $index');
    // Add your custom logic here
  }

  void _initialize() {
    mapController.setSymbolIconAllowOverlap(true);

    mapController.onFeatureDrag.add(_onVertexSymbolDrag);
    mapController.onFeatureDrag.add(_onMidPointSymbolDrag);
    mapController.onLineTapped.add(_onLineTapped);

    setGeofencePolygons(initialPolygons);
  }

  void startDrawingPolygon() {
    MapLogger.log('$TAG: Starting to draw polygon');
    isDrawingPolygon = true;
    currentGeofence = [];
  }

  void finishDrawingPolygon() {
    MapLogger.log('$TAG: Finishing to draw polygon');
    if (currentGeofence.length >= 3) {
      List<LatLng> newPolygon = List.from(currentGeofence)..add(currentGeofence.first);
      geofenceArrays.add(newPolygon);
      isDrawingPolygon = false;
      currentGeofence = [];
      // Update only the newly added polygon
      int newPolygonIndex = geofenceArrays.length - 1;
      updateMarkers(index: newPolygonIndex);
      updatePolygonFills(index: newPolygonIndex);
      MapLogger.log('$TAG: New polygon added. Total polygons: ${geofenceArrays.length}');
    } else {
      MapLogger.error('$TAG: A polygon must have at least 3 vertices.');
    }
  }

  void handleMapClick(Point<double> point, LatLng coordinates) {
    if (isDrawingPolygon) {
      currentGeofence.add(coordinates);
      _updateCurrentPolygon();
    }
  }

  void setGeofencePolygons(List<Geofence> polygons) {
    MapLogger.log('$TAG: Setting geofence polygons: $polygons');
    geofenceArrays = [];

    for (var geofenceModel in polygons) {
      List<LatLng> polygon = geofenceModel.polygon.map((latLng) {
        return LatLng(latLng.latitude, latLng.longitude);
      }).toList();

      // Ensure the polygon is closed
      if (polygon.isNotEmpty && polygon.first != polygon.last) {
        polygon.add(polygon.first);
      }
      geofenceArrays.add(polygon);
    }

    // Update the polygons on the map
    updateMarkers();
    updatePolygonFills();
  }

  Future<void> _updateCurrentPolygon() async {
    if (currentGeofence.isEmpty) return;

    // Add marker for each point
    for (var point in currentGeofence) {
      Symbol marker = await mapController.addSymbol(
        SymbolOptions(
          geometry: point,
          iconImage: 'custom-marker',
          iconSize: 1.0,
          textField: '${currentGeofence.indexOf(point)}',
          textSize: 20,
          textColor: '#000000',
          draggable: true,
        ),
      );
      markers.add([marker]);
    }

    // Add new temporary polygon
    Fill? fill = await mapController.addFill(
      FillOptions(
        geometry: [currentGeofence],
        fillColor: "#FF0000",
        fillOpacity: 0.5,
        fillOutlineColor: "#000000",
      ),
    );
    polygonFills.add(fill);
  }

  Future<void> updateMarkers({int? index}) async {
    try {
      List<int> indicesToUpdate = index != null ? [index] : List.generate(geofenceArrays.length, (i) => i);

      for (int polyIndex in indicesToUpdate) {
        List<LatLng> polygon = geofenceArrays[polyIndex];

        // Ensure markers list is initialized for this polygon
        if (markers.length <= polyIndex) {
          markers.add([]);
        }

        // Update or add markers for each vertex
        for (int i = 0; i < polygon.length - 1; i++) {
          if (i < markers[polyIndex].length) {
            // Update existing marker
            await mapController.updateSymbol(
              markers[polyIndex][i],
              SymbolOptions(
                geometry: polygon[i],
                iconImage: 'custom-marker',
                iconSize: 1.0,
                textField: '$polyIndex-$i',
                textSize: 20,
                textColor: '#000000',
                draggable: true,
              ),
            );
          } else {
            // Add new marker
            Symbol marker = await mapController.addSymbol(
              SymbolOptions(
                geometry: polygon[i],
                iconImage: 'custom-marker',
                iconSize: 1.0,
                textField: '$polyIndex-$i',
                textSize: 20,
                textColor: '#000000',
                draggable: true,
              ),
            );
            markers[polyIndex].add(marker);
          }
        }

        // Remove excess markers if polygon has fewer points now
        while (markers[polyIndex].length > polygon.length - 1) {
          await mapController.removeSymbol(markers[polyIndex].last);
          markers[polyIndex].removeLast();
        }
      }

      // Remove markers for deleted polygons
      while (markers.length > geofenceArrays.length) {
        for (Symbol marker in markers.last) {
          await mapController.removeSymbol(marker);
        }
        markers.removeLast();
      }

      MapLogger.log('$TAG: Markers updated successfully. Total polygons: ${geofenceArrays.length}');
    } catch (e) {
      MapLogger.error('$TAG: Error updating markers: $e');
    }
  }

  Future<void> updatePolygonFills({int? index}) async {
    try {
      List<int> indicesToUpdate = index != null ? [index] : List.generate(geofenceArrays.length, (i) => i);

      for (int i in indicesToUpdate) {
        if (i < polygonFills.length && polygonFills[i] != null) {
          // Update existing fill
          await mapController.updateFill(
            polygonFills[i]!,
            FillOptions(
              geometry: [geofenceArrays[i]],
              fillColor: "#FF0000",
              fillOpacity: 0.5,
              fillOutlineColor: "#000000",
            ),
          );
        } else {
          // Add new fill
          Fill? fill = await mapController.addFill(
            FillOptions(
              geometry: [geofenceArrays[i]],
              fillColor: "#FF0000",
              fillOpacity: 0.5,
              fillOutlineColor: "#000000",
            ),
          );
          polygonFills.add(fill);
        }
      }

      // Remove excess fills
      while (polygonFills.length > geofenceArrays.length) {
        await mapController.removeFill(polygonFills.last!);
        polygonFills.removeLast();
      }

      await updateLines(index: index);
    } catch (e) {
      MapLogger.error('$TAG: Error updating polygon fills: $e');
    }
  }

  Future<void> updateLines({int? index}) async {
    try {
      List<int> indicesToUpdate = index != null ? [index] : List.generate(geofenceArrays.length, (i) => i);

      for (int polyIndex in indicesToUpdate) {
        List<LatLng> polygon = geofenceArrays[polyIndex];

        // Ensure lines list is initialized for this polygon
        if (lines.length <= polyIndex) {
          lines.add([]);
        }

        for (int i = 0; i < polygon.length - 1; i++) {
          if (i < lines[polyIndex].length) {
            // Update existing line
            await mapController.updateLine(
              lines[polyIndex][i],
              LineOptions(
                geometry: [polygon[i], polygon[i + 1]],
                lineColor: "#0000FF",
                lineWidth: 5,
                lineOpacity: 0.7,
                draggable: false,
              ),
            );
          } else {
            // Add new line
            Line line = await mapController.addLine(
              LineOptions(
                geometry: [polygon[i], polygon[i + 1]],
                lineColor: "#0000FF",
                lineWidth: 5,
                lineOpacity: 0.7,
                draggable: false,
              ),
            );
            lines[polyIndex].add(line);
          }
        }

        // Remove excess lines if polygon has fewer points now
        while (lines[polyIndex].length > polygon.length - 1) {
          await mapController.removeLine(lines[polyIndex].last);
          lines[polyIndex].removeLast();
        }
      }

      // Remove lines for deleted polygons
      while (lines.length > geofenceArrays.length) {
        for (Line line in lines.last) {
          await mapController.removeLine(line);
        }
        lines.removeLast();
      }
    } catch (e) {
      MapLogger.error('$TAG: Error updating lines: $e');
    }
  }

  void _onLineTapped(Line line) {
    for (int polyIndex = 0; polyIndex < lines.length; polyIndex++) {
      int index = lines[polyIndex].indexOf(line);
      if (index != -1) {
        selectedPolygonIndex = polyIndex;
        _addMidpointSymbol(polyIndex, index);
        break;
      }
    }
  }

  Future<void> _addMidpointSymbol(int polyIndex, int lineIndex) async {
    // Remove previous selected line symbol if exists
    if (selectedLineSymbol != null) {
      await mapController.removeSymbol(selectedLineSymbol!);
      selectedLineSymbol = null;
    }

    List<LatLng> polygon = geofenceArrays[polyIndex];

    LatLng startPoint = polygon[lineIndex];
    LatLng endPoint = polygon[(lineIndex + 1) % polygon.length];
    LatLng midPoint = LatLng(
      (startPoint.latitude + endPoint.latitude) / 2,
      (startPoint.longitude + endPoint.longitude) / 2,
    );

    selectedLineSymbol = await mapController.addSymbol(
      SymbolOptions(
        geometry: midPoint,
        iconImage: 'custom-marker',
        iconSize: 1.0,
        draggable: true,
      ),
    );
    MapLogger.log('$TAG: Midpoint symbol added successfully. ID: ${selectedLineSymbol?.id}');
    mapController.setSymbolIconAllowOverlap(true);
    selectedLineIndex = lineIndex;
  }

  void _onMidPointSymbolDrag(
    dynamic id, {
    required Point<double> point,
    required LatLng origin,
    required LatLng current,
    required LatLng delta,
    required DragEventType eventType,
  }) {
    if (id == selectedLineSymbol?.id && selectedPolygonIndex != null && selectedLineIndex != null) {
      if (eventType == DragEventType.end) {
        // Insert the new point into the geofencePolygon
        geofenceArrays[selectedPolygonIndex!].insert(selectedLineIndex! + 1, current);
        // Remove the midPoint symbol and reset selection
        mapController.removeSymbol(selectedLineSymbol!);
        selectedLineSymbol = null;
        selectedLineIndex = null;
        selectedPolygonIndex = null;
        // Update only the current polygon
        updateMarkers(index: selectedPolygonIndex);
        updatePolygonFills(index: selectedPolygonIndex);
      }
    }
  }

  void _onVertexSymbolDrag(
    dynamic id, {
    required Point<double> point,
    required LatLng origin,
    required LatLng current,
    required LatLng delta,
    required DragEventType eventType,
  }) {
    for (final polyIndexEntry in markers.asMap().entries) {
      final polyIndex = polyIndexEntry.key;
      final markerList = polyIndexEntry.value;
      final index = markerList.indexWhere((marker) => marker.id == id);
      if (index != -1) {
        // Update the geofencePolygon vertex position based on drag event.
        geofenceArrays[polyIndex][index] = current;
        // If this is the first point, also update the last point to keep the polygon closed
        if (index == 0) {
          geofenceArrays[polyIndex][geofenceArrays[polyIndex].length - 1] = current;
        }

        // Update the connected lines
        _updateConnectedLines(polyIndex, index);

        // If it's the end of the drag, update the entire polygon
        if (eventType == DragEventType.end) {
          updatePolygonFills();
        }
        break;
      }
    }
  }

  Future<void> _updateConnectedLines(int polyIndex, int vertexIndex) async {
    final polygon = geofenceArrays[polyIndex];
    final lineCount = polygon.length - 1;

    // Update the line before the vertex
    int prevLineIndex = (vertexIndex - 1 + lineCount) % lineCount;
    await updateTempLine(polyIndex, prevLineIndex);

    // Update the line after the vertex
    int nextLineIndex = vertexIndex % lineCount;
    await updateTempLine(polyIndex, nextLineIndex);
  }

  Future<void> updateTempLine(int polyIndex, int lineIndex) async {
    final polygon = geofenceArrays[polyIndex];
    final startPoint = polygon[lineIndex];
    final endPoint = polygon[(lineIndex + 1) % polygon.length];

    await mapController.updateLine(
      lines[polyIndex][lineIndex],
      LineOptions(
        geometry: [startPoint, endPoint],
        lineColor: "#0000FF",
        lineWidth: 5,
        lineOpacity: 0.7,
      ),
    );
  }

  Future<void> onStyleLoadedCallback() async {
    try {
      await _addImageFromAsset("custom-marker", "assets/symbols/custom-marker.png");
      await _addImageFromAsset("user-marker", "assets/symbols/user-marker.png");
      MapLogger.log('$TAG: Custom marker image loaded successfully.');
    } catch (e) {
      MapLogger.error('$TAG: Error loading custom marker image: $e');
    }
    MapLogger.log('$TAG: Map style has been loaded.');
  }

  Future<void> _addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final list = bytes.buffer.asUint8List();
    await mapController.addImage(name, list);
  }
}
