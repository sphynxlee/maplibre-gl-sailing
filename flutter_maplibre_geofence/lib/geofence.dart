import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

class GeofenceHomePage extends StatefulWidget {
  const GeofenceHomePage({super.key});

  @override
  GeofenceHomePageState createState() => GeofenceHomePageState();
}

class GeofenceHomePageState extends State<GeofenceHomePage> {
  MapLibreMapController? mapController;

  List<LatLng> geofencePolygon = [];
  List<Symbol> markers = [];
  List<Line> lines = [];
  Fill? polygonFill;

  Symbol? selectedLineSymbol;
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

    // Initialize the geofence polygon
    List<LatLng> initialPolygon = [
      const LatLng(37.7749, -122.4194), // Point A
      const LatLng(37.7799, -122.4194), // Point B
      const LatLng(37.7799, -122.4144), // Point C
      const LatLng(37.7749, -122.4144), // Point D
    ];

    setGeofencePolygon(initialPolygon);
    mapController?.onFeatureDrag.add(_onVertexSymbolDrag);
  }

  void setGeofencePolygon(List<LatLng> coordinates) {
    setState(() {
      geofencePolygon = List.from(coordinates);
      // Ensure the polygon is closed by adding the first point at the end if needed
      if (geofencePolygon.isNotEmpty && geofencePolygon.first != geofencePolygon.last) {
        geofencePolygon.add(geofencePolygon.first);
      }
    });

    // Update the polygon on the map
    updateMarkers();
    updatePolygonFill();
  }

  Future<void> _onStyleLoadedCallback() async {
    try {
      await addImageFromAsset("custom-marker", "assets/symbols/custom-marker.png");
      await addImageFromAsset("user-marker", "assets/symbols/user-marker.png");
      print('Custom marker image loaded successfully.');
    } catch (e) {
      print('Error loading custom marker image: $e');
    }
    print('Map style has been loaded.');
  }

  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final list = bytes.buffer.asUint8List();
    return mapController!.addImage(name, list);
  }

  Future<void> updateMarkers() async {
    try {
      // Remove existing markers
      for (Symbol marker in markers) {
        await mapController?.removeSymbol(marker);
      }
      markers.clear();

      // Add new markers (excluding the last point if it's a duplicate of the first)
      for (int i = 0; i < geofencePolygon.length - 1; i++) {
        Symbol marker = await mapController!.addSymbol(
          SymbolOptions(
            geometry: geofencePolygon[i],
            iconImage: 'custom-marker',
            iconSize: 2.0,
            textField: i.toString(),
            textSize: 20,
            textColor: '#000000',
            draggable: true,
          ),
        );
        mapController!.setSymbolIconAllowOverlap(true);
        markers.add(marker);
      }
      print('Markers updated successfully.');
    } catch (e) {
      print('Error updating markers: $e');
    }
  }

  Future<void> updatePolygonFill() async {
    try {
      if (polygonFill != null) {
        await mapController?.updateFill(
            polygonFill!,
            FillOptions(
              geometry: [geofencePolygon],
              fillColor: "#FF0000",
              fillOpacity: 0.5,
              fillOutlineColor: "#000000",
            ));
      } else {
        polygonFill = await mapController?.addFill(
          FillOptions(
            geometry: [geofencePolygon],
            fillColor: "#FF0000",
            fillOpacity: 0.5,
            fillOutlineColor: "#000000",
          ),
        );
      }
      await updateLines();
    } catch (e) {
      print('Error updating polygon: $e');
    }
  }

  Future<void> updateLines() async {
    try {
      // Remove existing lines
      for (Line line in lines) {
        await mapController?.removeLine(line);
      }
      lines.clear();

      // Add new lines for each edge of the polygon
      for (int i = 0; i < geofencePolygon.length - 1; i++) {
        Line line = await mapController!.addLine(
          LineOptions(
            geometry: [geofencePolygon[i], geofencePolygon[i + 1]],
            lineColor: "#0000FF", // Blue color for the lines
            lineWidth: 3,
            lineOpacity: 0.7,
            draggable: false, // Lines are not draggable
          ),
        );
        lines.add(line);
      }

      // Add tap listener to lines
      mapController?.onLineTapped.add(_onLineTapped);
    } catch (e) {
      print('Error updating lines: $e');
    }
  }

  void _onLineTapped(Line line) {
    int index = lines.indexOf(line);
    if (index != -1) {
      _addMidpointSymbol(index);
    }
  }

  Future<void> _addMidpointSymbol(int lineIndex) async {
    // Remove previous selected line symbol if exists
    if (selectedLineSymbol != null) {
      await mapController?.removeSymbol(selectedLineSymbol!);
      selectedLineSymbol = null;
    }

    LatLng startPoint = geofencePolygon[lineIndex];
    LatLng endPoint = geofencePolygon[(lineIndex + 1) % geofencePolygon.length];
    LatLng midPoint = LatLng(
      (startPoint.latitude + endPoint.latitude) / 2,
      (startPoint.longitude + endPoint.longitude) / 2,
    );
    geofencePolygon.add(midPoint);
    // updateMarkers();

    selectedLineSymbol = await mapController!.addSymbol(
      SymbolOptions(
        geometry: midPoint,
        iconImage: 'user-marker',
        iconSize: 1.5,
        draggable: true,
      ),
    );
    selectedLineIndex = lineIndex;

    // Add drag listener to the new symbol
    mapController?.onFeatureDrag.add(_onMidPointSymbolDrag);
  }

  void _onMidPointSymbolDrag(dynamic id, {required Point<double> point, required LatLng origin, required LatLng current, required LatLng delta, required DragEventType eventType}) {
    if (id == selectedLineSymbol?.id && selectedLineIndex != null) {
      if (eventType == DragEventType.start) {
        setState(() {
          // While dragging, show the user the new potential vertex position
          geofencePolygon[selectedLineIndex! + 1] = current;
          updatePolygonFill();
          // updateMarkers();
        });
      } else if (eventType == DragEventType.end) {
        setState(() {
          // Insert the new point into the geofencePolygon
          geofencePolygon.insert(selectedLineIndex! + 1, current);

          // Remove the midPoint symbol and reset selection
          mapController?.removeSymbol(selectedLineSymbol!);
          selectedLineSymbol = null;
          selectedLineIndex = null;

          // Re-update everything to reflect the new polygon state
          updatePolygonFill();
          updateMarkers();

          // Remove drag listener for midPoint
          mapController?.onFeatureDrag.remove(_onMidPointSymbolDrag);
        });
      }
    }
  }

  void _onVertexSymbolDrag(dynamic id, {required Point<double> point, required LatLng origin, required LatLng current, required LatLng delta, required DragEventType eventType}) {
    int index = markers.indexWhere((marker) => marker.id == id);

    if (index != -1) {
      setState(() {
        // Update the geofencePolygon vertex position based on drag event.
        geofencePolygon[index] = current;
        // If this is the first point, also update the last point to keep the polygon closed
        if (index == 0) {
          geofencePolygon[geofencePolygon.length - 1] = current;
        }

        updatePolygonFill();
      });
    }
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
