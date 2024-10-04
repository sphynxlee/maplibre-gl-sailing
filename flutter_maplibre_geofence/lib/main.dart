import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

// import 'package:flutter/foundation.dart' show kIsWeb;
// import './common/service/web_specific_code.dart' if (dart.library.io) 'mobile_specific_code.dart';

void main() {
  // if (kIsWeb) {
  //   initializeForWeb();
  // }
  runApp(const MaterialApp(home: MyApp()));
}

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

  List<LatLng> geofencePolygon = [];
  List<Symbol> markers = [];
  Fill? polygonFill;

  List<LatLng> mockGeofencePolygon = [
    const LatLng(37.7749, -122.4194), // Point A
    const LatLng(37.7799, -122.4194), // Point B
    const LatLng(37.7799, -122.4144), // Point C
    const LatLng(37.7749, -122.4144), // Point D
    const LatLng(37.7749, -122.4194), // Closing the polygon back to Point A
  ];

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

    // Initialize the geofence polygon
    List<LatLng> initialPolygon = [
      const LatLng(37.7749, -122.4194),
      const LatLng(37.7799, -122.4194),
      const LatLng(37.7799, -122.4144),
      const LatLng(37.7749, -122.4144),
    ];

    setGeofencePolygon(initialPolygon);
    addDragListener();
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
    updatePolygon();
  }

  Future<void> _onStyleLoadedCallback() async {
    try {
      await addImageFromAsset("custom-marker", "assets/symbols/custom-marker.png");
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

  Future<void> updatePolygon() async {
    try {
      if (polygonFill != null) {
        await mapController?.updateFill(polygonFill!, FillOptions(geometry: [geofencePolygon]));
      } else {
        polygonFill = await mapController?.addFill(
          FillOptions(
            geometry: [geofencePolygon],
            fillColor: "#FF0000",
            fillOpacity: 0.5,
          ),
        );
      }
    } catch (e) {
      print('Error updating polygon: $e');
    }
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
            draggable: true,
            zIndex: 3,
          ),
        );
        markers.add(marker);
      }
    } catch (e) {
      print('Error updating markers: $e');
    }
  }

  void _onFeatureDrag(dynamic id, {required Point<double> point, required LatLng origin, required LatLng current, required LatLng delta, required DragEventType eventType}) {
    int index = markers.indexWhere((marker) => marker.id == id);

    if (index != -1) {
      setState(() {
        // Update the geofencePolygon vertex position based on drag event.
        geofencePolygon[index] = current;
        // If this is the first point, also update the last point to keep the polygon closed
        if (index == 0) {
          geofencePolygon[geofencePolygon.length - 1] = current;
        }

        updatePolygon();
      });
    }
  }

  void addDragListener() {
    mapController?.onFeatureDrag.add(_onFeatureDrag);
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
