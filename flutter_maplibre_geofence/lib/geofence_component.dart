import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

import './common/service/logger.dart';

class GeofenceComponent extends StatefulWidget {
  final List<List<LatLng>> initialPolygons;
  const GeofenceComponent({
    super.key,
    required this.initialPolygons,
  });

  @override
  GeofenceComponentState createState() => GeofenceComponentState();
}

class GeofenceComponentState extends State<GeofenceComponent> {
  MapLibreMapController? mapController;

  List<List<LatLng>> geofencePolygons = [];
  List<List<Symbol>> markers = [];
  List<List<Line>> lines = [];
  List<Fill?> polygonFills = [];

  Symbol? selectedLineSymbol;
  int? selectedPolygonIndex;
  int? selectedLineIndex;

  @override
  void dispose() {
    mapController?.onFeatureDrag.remove(_onVertexSymbolDrag);
    mapController?.onFeatureDrag.remove(_onMidPointSymbolDrag);
    mapController?.onLineTapped.remove(_onLineTapped);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    setState(() {
      mapController = controller;
    });

    // mapController!.setSymbolIconAllowOverlap(true);

    mapController?.onFeatureDrag.add(_onVertexSymbolDrag);
    mapController?.onFeatureDrag.add(_onMidPointSymbolDrag);
    mapController?.onLineTapped.add(_onLineTapped);

    setGeofencePolygons(widget.initialPolygons);
  }

  void setGeofencePolygons(List<List<LatLng>> polygons) {
    setState(() {
      geofencePolygons = [];

      for (var coords in polygons) {
        // Ensure the polygon is closed
        List<LatLng> polygon = List.from(coords);
        if (polygon.isNotEmpty && polygon.first != polygon.last) {
          polygon.add(polygon.first);
        }
        geofencePolygons.add(polygon);
      }
    });

    // Update the polygons on the map
    updateMarkers();
    updatePolygonFills();
  }

  Future<void> updateMarkers() async {
    try {
      // Remove existing markers
      for (var markerList in markers) {
        for (Symbol marker in markerList) {
          await mapController?.removeSymbol(marker);
        }
      }
      markers.clear();

      // Add new markers for each polygon
      for (int polyIndex = 0; polyIndex < geofencePolygons.length; polyIndex++) {
        List<LatLng> polygon = geofencePolygons[polyIndex];
        List<Symbol> markerList = [];

        for (int i = 0; i < polygon.length - 1; i++) {
          Symbol marker = await mapController!.addSymbol(
            SymbolOptions(
              geometry: polygon[i],
              iconImage: 'custom-marker',
              iconSize: 2.0,
              textField: '$polyIndex-$i',
              textSize: 20,
              textColor: '#000000',
              draggable: true,
            ),
          );
          mapController?.setSymbolIconAllowOverlap(true);
          markerList.add(marker);
        }
        markers.add(markerList);
      }
      MapLogger.log('Markers updated successfully.');
    } catch (e) {
      MapLogger.error('Error updating markers: $e');
    }
  }

  Future<void> updatePolygonFills() async {
    try {
      // Remove existing fills
      for (Fill? fill in polygonFills) {
        if (fill != null) {
          await mapController?.removeFill(fill);
        }
      }
      polygonFills.clear();

      // Add new fills for each polygon
      for (List<LatLng> polygon in geofencePolygons) {
        Fill? fill = await mapController?.addFill(
          FillOptions(
            geometry: [polygon],
            fillColor: "#FF0000",
            fillOpacity: 0.5,
            fillOutlineColor: "#000000",
          ),
        );
        polygonFills.add(fill);
      }
      await updateLines();
    } catch (e) {
      MapLogger.error('Error updating polygon fills: $e');
    }
  }

  Future<void> updateLines() async {
    try {
      // Remove existing lines
      for (var lineList in lines) {
        for (Line line in lineList) {
          await mapController?.removeLine(line);
        }
      }
      lines.clear();

      // Add new lines for each polygon
      for (int polyIndex = 0; polyIndex < geofencePolygons.length; polyIndex++) {
        List<LatLng> polygon = geofencePolygons[polyIndex];
        List<Line> lineList = [];

        for (int i = 0; i < polygon.length - 1; i++) {
          Line line = await mapController!.addLine(
            LineOptions(
              geometry: [polygon[i], polygon[i + 1]],
              lineColor: "#0000FF", // Blue color for the lines
              lineWidth: 3,
              lineOpacity: 0.7,
              draggable: false,
            ),
          );
          lineList.add(line);
        }
        lines.add(lineList);
      }
    } catch (e) {
      MapLogger.error('Error updating lines: $e');
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
      await mapController?.removeSymbol(selectedLineSymbol!);
      selectedLineSymbol = null;
    }

    List<LatLng> polygon = geofencePolygons[polyIndex];

    LatLng startPoint = polygon[lineIndex];
    LatLng endPoint = polygon[(lineIndex + 1) % polygon.length];
    LatLng midPoint = LatLng(
      (startPoint.latitude + endPoint.latitude) / 2,
      (startPoint.longitude + endPoint.longitude) / 2,
    );

    selectedLineSymbol = await mapController!.addSymbol(
      SymbolOptions(
        geometry: midPoint,
        iconImage: 'user-marker',
        iconSize: 1.5,
        draggable: true,
      ),
    );
    MapLogger.log('Midpoint symbol added successfully. ID: ${selectedLineSymbol?.id}');
    mapController?.setSymbolIconAllowOverlap(true);
    selectedLineIndex = lineIndex;
  }

  void _onMidPointSymbolDrag(dynamic id, {required Point<double> point, required LatLng origin, required LatLng current, required LatLng delta, required DragEventType eventType}) {
    if (id == selectedLineSymbol?.id && selectedPolygonIndex != null && selectedLineIndex != null) {
      setState(() {
        // Insert the new point into the geofencePolygon
        geofencePolygons[selectedPolygonIndex!].insert(selectedLineIndex! + 1, current);
        // Remove the midPoint symbol and reset selection
        mapController?.removeSymbol(selectedLineSymbol!);
        selectedLineSymbol = null;
        selectedLineIndex = null;
        selectedPolygonIndex = null;
        // Re-update everything to reflect the new polygon state
        updateMarkers();
        updatePolygonFills();
      });
      // }
    }
  }

  void _onVertexSymbolDrag(dynamic id, {required Point<double> point, required LatLng origin, required LatLng current, required LatLng delta, required DragEventType eventType}) {
    for (int polyIndex = 0; polyIndex < markers.length; polyIndex++) {
      int index = markers[polyIndex].indexWhere((marker) => marker.id == id);
      if (index != -1) {
        setState(() {
          // Update the geofencePolygon vertex position based on drag event.
          geofencePolygons[polyIndex][index] = current;
          // If this is the first point, also update the last point to keep the polygon closed
          if (index == 0) {
            geofencePolygons[polyIndex][geofencePolygons[polyIndex].length - 1] = current;
          }
          updatePolygonFills();
        });
        break;
      }
    }
  }

  Future<void> _onStyleLoadedCallback() async {
    try {
      await addImageFromAsset("custom-marker", "assets/symbols/custom-marker.png");
      await addImageFromAsset("user-marker", "assets/symbols/user-marker.png");
      MapLogger.log('Custom marker image loaded successfully.');
    } catch (e) {
      MapLogger.error('Error loading custom marker image: $e');
    }
    MapLogger.log('Map style has been loaded.');
  }

  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final list = bytes.buffer.asUint8List();
    return mapController!.addImage(name, list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: MapLibreMap(
          annotationOrder: const [
            AnnotationType.fill,
            AnnotationType.line,
            AnnotationType.circle,
            AnnotationType.symbol,
          ],
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoadedCallback,
          initialCameraPosition: const CameraPosition(
            target: LatLng(37.7749, -122.4194), // San Francisco
            zoom: 14.0,
          ),
          // styleString: 'https://api.maptiler.com/maps/streets/style.json?key=QBMCVBrM2oLPkQgiPdQV',
        ),
      ),
    );
  }
}
