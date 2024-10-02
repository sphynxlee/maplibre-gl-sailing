import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

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
  GeofenceHomePageState createState() => GeofenceHomePageState();
}

class GeofenceHomePageState extends State<GeofenceHomePage> {
  MapLibreMapController? mapController;

  List<LatLng> geofencePolygon = [
    const LatLng(37.7749, -122.4194), // Point A
    const LatLng(37.7799, -122.4194), // Point B
    const LatLng(37.7799, -122.4144), // Point C
    const LatLng(37.7749, -122.4144), // Point D
    const LatLng(37.7749, -122.4194), // Closing the polygon back to Point A
  ];

  List<Symbol> markers = [];
  Fill? polygonFill;

  @override
  void dispose() {
    mapController?.onFeatureDrag.remove(_onFeatureDrag);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    setState(() {
      mapController = controller;
    });
    // addPolygon();
    // addMarkers();
    // addDragListener();
  }

  Future<void> _onStyleLoaded() async {
    await addImageFromAsset("custom-marker", "assets/symbols/custom-marker.png");
    print('Map style has been loaded.');
  }

  Future<void> addImageFromAsset(String name, String assetName) async {
    final bytes = await rootBundle.load(assetName);
    final list = bytes.buffer.asUint8List();
    return mapController!.addImage(name, list);
  }

  void addPolygon() async {
    polygonFill = await mapController?.addFill(
      FillOptions(
        geometry: [geofencePolygon],
        fillColor: "#FF0000",
        fillOpacity: 0.5,
      ),
    );
  }

  void addMarkers() async {
    for (LatLng point in geofencePolygon) {
      Symbol marker = await mapController!.addSymbol(
        SymbolOptions(
          geometry: point,
          iconImage: 'custom-marker',
          iconSize: 2.0,
          draggable: true,
          zIndex: 2,
        ),
      );
      markers.add(marker);
    }
  }

  void _onFeatureDrag(dynamic id,
      {required Point<double> point,
      required LatLng origin,
      required LatLng current,
      required LatLng delta,
      required DragEventType eventType}) {
    int index = markers.indexWhere((marker) => marker.id == id);

    if (index != -1) {
      setState(() {
        // Update the geofencePolygon vertex position based on drag event.
        geofencePolygon[index] = current;

        // Update the polygon fill geometry dynamically.
        updatePolygon();
      });
    }
  }

  void addDragListener() {
    mapController?.onFeatureDrag.add(_onFeatureDrag);
  }

  void updatePolygon() async {
    // Efficient polygon update without full removal
    if (polygonFill != null) {
      await mapController!.updateFill(
        polygonFill!,
        FillOptions(
          geometry: [geofencePolygon],
          fillColor: "#FF0000",
          fillOpacity: 0.5,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapLibreMap(
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.7749, -122.4194), // San Francisco
          zoom: 14.0,
        ),
        styleString: 'https://api.maptiler.com/maps/streets/style.json?key=QBMCVBrM2oLPkQgiPdQV',
      ),
    );
  }
}
