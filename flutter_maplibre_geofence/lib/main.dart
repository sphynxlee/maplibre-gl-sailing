import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'geofence_component.dart';
import 'geofence_interfaces.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MaterialApp(home: GeofenceHomePage()));
}

class GeofenceHomePage extends StatefulWidget {
  const GeofenceHomePage({super.key});

  @override
  State createState() => GeofenceHomePageState();
}

class GeofenceHomePageState extends State<GeofenceHomePage> {
  MapLibreMapController? mapController;
  GeofenceComponent? geofenceComponent;
  bool isDrawingPolygon = false;

  Rect? _buttonRect;
  static const double BUTTON_THRESHOLD = 50.0;

  // Initial polygons with the new Geofence class
  final List<Geofence> initialPolygons = [
    Geofence(
      name: "San Francisco Geofence 1",
      orgId: "SF111",
      polygon: [
        const LatLng(37.7749, -122.4194), // Polygon 1 - Point A
        const LatLng(37.7799, -122.4194), // Point B
        const LatLng(37.7799, -122.4144), // Point C
        const LatLng(37.7749, -122.4144), // Point D
      ],
    ),
    Geofence(
      name: "San Francisco Geofence 2",
      orgId: "SF222",
      polygon: [
        const LatLng(37.7849, -122.4294), // Polygon 2 - Point A
        const LatLng(37.7899, -122.4294), // Point B
        const LatLng(37.7899, -122.4244), // Point C
        const LatLng(37.7849, -122.4244), // Point D
      ],
    ),
  ];

  final List<LatLng> vehicleRoute = [
    const LatLng(37.7749, -122.4194),
    const LatLng(37.7750, -122.4184),
    const LatLng(37.7751, -122.4174),
    const LatLng(37.7752, -122.4164),
    const LatLng(37.7753, -122.4154),
  ];

  int currentRouteIndex = 0;
  Timer? routeTimer;
  Symbol? vehicleSymbol;

  @override
  void initState() {
    super.initState();
    // Start the simulation after the map is created
  }

  void _startVehicleSimulation() {
    routeTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      LatLng currentLocation = vehicleRoute[currentRouteIndex];
      geofenceComponent?.onLocationUpdate(currentLocation);
      _updateVehicleMarker(currentLocation);

      // Update the index, looping back to 0 when reaching the end
      currentRouteIndex = (currentRouteIndex + 1) % vehicleRoute.length;
    });
  }

  void _updateVehicleMarker(LatLng location) {
    if (vehicleSymbol != null) {
      mapController?.updateSymbol(
        vehicleSymbol!,
        SymbolOptions(geometry: location),
      );
    } else {
      mapController?.addSymbol(
        SymbolOptions(
          geometry: location,
          iconImage: "user-marker", // Ensure you have an icon named "car-icon"
          iconSize: 1.0,
        ),
      ).then((symbol) {
        vehicleSymbol = symbol;
      });
    }
  }

  @override
  void dispose() {
    routeTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    setState(() {
      mapController = controller;

      geofenceComponent = GeofenceComponent(
        initialPolygons: initialPolygons,
        mapController: mapController!,
      );

      // LatLng initialLocation = vehicleRoute.first;
      // geofenceComponent!.onLocationUpdate(initialLocation);
    });
    _startVehicleSimulation();
  }

  Future<void> _onStyleLoadedCallback() async {
    geofenceComponent?.onStyleLoadedCallback();
  }

  bool _isClickNearButton(Point<double> point) {
    if (_buttonRect == null) return false;
    return point.x >= _buttonRect!.left - BUTTON_THRESHOLD &&
        point.x <= _buttonRect!.right + BUTTON_THRESHOLD &&
        point.y >= _buttonRect!.top - BUTTON_THRESHOLD &&
        point.y <= _buttonRect!.bottom + BUTTON_THRESHOLD;
  }

  void _handleMapClick(Point<double> point, LatLng coordinates) {
    if (_isClickNearButton(point)) {
      // Ignore clicks near the button
      return;
    }
    geofenceComponent?.handleMapClick(point, coordinates);
  }

  void _startDrawingPolygon() {
    setState(() {
      isDrawingPolygon = true;
    });
    geofenceComponent?.startDrawingPolygon();
  }

  void _finishDrawingPolygon() {
    setState(() {
      isDrawingPolygon = false;
    });
    geofenceComponent?.finishDrawingPolygon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Demo'),
      ),
      body: MapLibreMap(
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoadedCallback,
        onMapClick: _handleMapClick,
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.7749, -122.4194), // San Francisco
          zoom: 14.0,
        ),
        annotationOrder: const [
          AnnotationType.fill,
          AnnotationType.line,
          AnnotationType.circle,
          AnnotationType.symbol,
        ],
        compassViewPosition: CompassViewPosition.topRight,
        compassEnabled: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ZoomControls(mapController: mapController),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final position = renderBox.localToGlobal(Offset.zero);
                  _buttonRect = Rect.fromLTWH(
                    position.dx,
                    position.dy,
                    renderBox.size.width,
                    renderBox.size.height,
                  );
                }
              });
              return FloatingActionButton(
                onPressed: isDrawingPolygon ? _finishDrawingPolygon : _startDrawingPolygon,
                child: Icon(isDrawingPolygon ? Icons.check : Icons.fence),
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class ZoomControls extends StatelessWidget {
  final MapLibreMapController? mapController;

  const ZoomControls({
    super.key,
    required this.mapController,
  });

  void _zoomIn() {
    mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'zoom-in',
          onPressed: _zoomIn,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'zoom-out',
          onPressed: _zoomOut,
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }
}
