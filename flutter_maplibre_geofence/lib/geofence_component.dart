import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

import './common/service/logger.dart';

class GeofenceComponent extends StatefulWidget {
  final Map<String, dynamic> initialGeofence;
  const GeofenceComponent({
    super.key,
    required this.initialGeofence,
  });

  @override
  GeofenceComponentState createState() => GeofenceComponentState();
}

class GeofenceComponentState extends State<GeofenceComponent> {
  MapLibreMapController? mapController;

  List<List<LatLng>> geofenceArrays = [];
  List<List<Symbol>> markers = [];
  List<List<Line>> lines = [];
  List<Fill?> polygonFills = [];
  List<LatLng> currentGeofence = [];

  String geofenceName = "";
  String orgId = "";

  Symbol? selectedLineSymbol;
  int? selectedPolygonIndex;
  int? selectedLineIndex;

  bool isDrawingPolygon = false;

  Rect? _buttonRect;

  @override
  void initState() {
    super.initState();
    _initializeGeofence();
  }

  void _initializeGeofence() {
    geofenceName = widget.initialGeofence['name'] as String;
    orgId = widget.initialGeofence['orgId'] as String;
    List<dynamic> polygons = widget.initialGeofence['polygon'] as List<dynamic>;

    geofenceArrays = polygons.map((polygon) {
      return (polygon as List<dynamic>).map((point) {
        return LatLng(point['latitude'] as double, point['longitude'] as double);
      }).toList();
    }).toList();
  }

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

    mapController!.setSymbolIconAllowOverlap(true);

    mapController?.onFeatureDrag.add(_onVertexSymbolDrag);
    mapController?.onFeatureDrag.add(_onMidPointSymbolDrag);
    mapController?.onLineTapped.add(_onLineTapped);
  }

  void _handleMapClick(Point<double> point, LatLng coordinates) {
    MapLogger.log('Map clicked at point: $point, coordinates: $coordinates');
    if (isDrawingPolygon) {
      if (_buttonRect == null || !_isClickNearButton(point)) {
        setState(() {
          currentGeofence.add(coordinates);
        });
        _updateCurrentPolygon();
      }
    }
  }

  bool _isClickNearButton(Point<double> point) {
    if (_buttonRect == null) return false;
    const threshold = 50.0;
    return point.x >= _buttonRect!.left - threshold &&
           point.x <= _buttonRect!.right + threshold &&
           point.y >= _buttonRect!.top - threshold &&
           point.y <= _buttonRect!.bottom + threshold;
  }

  void _startDrawingPolygon() {
    MapLogger.log('Starting to draw polygon');
    setState(() {
      isDrawingPolygon = true;
      currentGeofence = [];
    });
  }

  void _finishDrawingPolygon() {
    MapLogger.log('Finishing to draw polygon');
    if (currentGeofence.length >= 3) {
      setState(() {
        List<LatLng> newPolygon = List.from(currentGeofence)..add(currentGeofence.first);
        geofenceArrays.add(newPolygon);
        isDrawingPolygon = false;
        currentGeofence = [];
      });
      updateMarkers();
      updatePolygonFills();
      MapLogger.log('New polygon added. Total polygons: ${geofenceArrays.length}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A polygon must have at least 3 vertices.')),
      );
    }
  }

  Future<void> _updateCurrentPolygon() async {
    if (currentGeofence.isEmpty) return;

    if (markers.length <= currentGeofence.length) {
      markers.add([]);
    }
    for (var point in currentGeofence) {
      Symbol marker = await mapController!.addSymbol(
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
      markers.last.add(marker);
    }

    Fill? fill = await mapController?.addFill(
      FillOptions(
        geometry: [currentGeofence],
        fillColor: "#FF0000",
        fillOpacity: 0.5,
        fillOutlineColor: "#000000",
      ),
    );
    polygonFills.add(fill);
  }

  void setGeofencePolygons(List<List<LatLng>> polygons) {
    setState(() {
      geofenceArrays = [];

      for (var coords in polygons) {
        List<LatLng> polygon = List.from(coords);
        if (polygon.isNotEmpty && polygon.first != polygon.last) {
          polygon.add(polygon.first);
        }
        geofenceArrays.add(polygon);
      }
    });

    updateMarkers();
    updatePolygonFills();
  }

  Future<void> updateMarkers() async {
    try {
      for (int polyIndex = 0; polyIndex < geofenceArrays.length; polyIndex++) {
        List<LatLng> polygon = geofenceArrays[polyIndex];

        if (markers.length <= polyIndex) {
          markers.add([]);
        }

        for (int i = 0; i < polygon.length - 1; i++) {
          if (i < markers[polyIndex].length) {
            await mapController?.updateSymbol(
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
            Symbol marker = await mapController!.addSymbol(
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

        while (markers[polyIndex].length > polygon.length - 1) {
          await mapController?.removeSymbol(markers[polyIndex].last);
          markers[polyIndex].removeLast();
        }
      }

      while (markers.length > geofenceArrays.length) {
        for (Symbol marker in markers.last) {
          await mapController?.removeSymbol(marker);
        }
        markers.removeLast();
      }

      MapLogger.log('Markers updated successfully. Total polygons: ${geofenceArrays.length}');
    } catch (e) {
      MapLogger.error('Error updating markers: $e');
    }
  }

  Future<void> updatePolygonFills() async {
    try {
      for (int i = 0; i < geofenceArrays.length; i++) {
        if (i < polygonFills.length) {
          await mapController?.updateFill(
            polygonFills[i]!,
            FillOptions(
              geometry: [geofenceArrays[i]],
              fillColor: "#FF0000",
              fillOpacity: 0.5,
              fillOutlineColor: "#000000",
            ),
          );
        } else {
          Fill? fill = await mapController?.addFill(
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

      while (polygonFills.length > geofenceArrays.length) {
        await mapController?.removeFill(polygonFills.last!);
        polygonFills.removeLast();
      }

      await updateLines();
    } catch (e) {
      MapLogger.error('Error updating polygon fills: $e');
    }
  }

  Future<void> updateLines() async {
    try {
      for (int polyIndex = 0; polyIndex < geofenceArrays.length; polyIndex++) {
        List<LatLng> polygon = geofenceArrays[polyIndex];

        if (lines.length <= polyIndex) {
          lines.add([]);
        }

        for (int i = 0; i < polygon.length - 1; i++) {
          if (i < lines[polyIndex].length) {
            await mapController?.updateLine(
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
            Line line = await mapController!.addLine(
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

        while (lines[polyIndex].length > polygon.length - 1) {
          await mapController?.removeLine(lines[polyIndex].last);
          lines[polyIndex].removeLast();
        }
      }

      while (lines.length > geofenceArrays.length) {
        for (Line line in lines.last) {
          await mapController?.removeLine(line);
        }
        lines.removeLast();
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
    if (selectedLineSymbol != null) {
      await mapController?.removeSymbol(selectedLineSymbol!);
      selectedLineSymbol = null;
    }

    List<LatLng> polygon = geofenceArrays[polyIndex];

    LatLng startPoint = polygon[lineIndex];
    LatLng endPoint = polygon[(lineIndex + 1) % polygon.length];
    LatLng midPoint = LatLng(
      (startPoint.latitude + endPoint.latitude) / 2,
      (startPoint.longitude + endPoint.longitude) / 2,
    );

    selectedLineSymbol = await mapController!.addSymbol(
      SymbolOptions(
        geometry: midPoint,
        iconImage: 'custom-marker',
        iconSize: 1.0,
        draggable: true,
      ),
    );
    MapLogger.log('Midpoint symbol added successfully. ID: ${selectedLineSymbol?.id}');
    mapController?.setSymbolIconAllowOverlap(true);
    selectedLineIndex = lineIndex;
  }

  void _onMidPointSymbolDrag(dynamic id, {required Point<double> point, required LatLng origin, required LatLng current, required LatLng delta, required DragEventType eventType}) {
    if (id == selectedLineSymbol?.id && selectedPolygonIndex != null && selectedLineIndex != null) {
      if (eventType == DragEventType.end) {
        setState(() {
          geofenceArrays[selectedPolygonIndex!].insert(selectedLineIndex! + 1, current);
          mapController?.removeSymbol(selectedLineSymbol!);
          selectedLineSymbol = null;
          selectedLineIndex = null;
          selectedPolygonIndex = null;
          updateMarkers();
          updatePolygonFills();
        });
      }
    }
  }

  void _onVertexSymbolDrag(dynamic id, {required Point<double> point, required LatLng origin, required LatLng current, required LatLng delta, required DragEventType eventType}) {
    for (final polyIndexEntry in markers.asMap().entries) {
      final polyIndex = polyIndexEntry.key;
      final markerList = polyIndexEntry.value;
      final index = markerList.indexWhere((marker) => marker.id == id);
      if (index != -1) {
        setState(() {
          geofenceArrays[polyIndex][index] = current;
          if (index == 0) {
            geofenceArrays[polyIndex][geofenceArrays[polyIndex].length - 1] = current;
          }
        });

        _updateConnectedLines(polyIndex, index);

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

    int prevLineIndex = (vertexIndex - 1 + lineCount) % lineCount;
    await updateTempLine(polyIndex, prevLineIndex);

    int nextLineIndex = vertexIndex % lineCount;
    await updateTempLine(polyIndex, nextLineIndex);
  }

  Future<void> updateTempLine(int polyIndex, int lineIndex) async {
    final polygon = geofenceArrays[polyIndex];
    final startPoint = polygon[lineIndex];
    final endPoint = polygon[(lineIndex + 1) % polygon.length];

    await mapController?.updateLine(
      lines[polyIndex][lineIndex],
      LineOptions(
        geometry: [startPoint, endPoint],
        lineColor: "#0000FF",
        lineWidth: 5,
        lineOpacity: 0.7,
      ),
    );
  }

  Future<void> _onStyleLoadedCallback() async {
    try {
      await addImageFromAsset("custom-marker", "assets/symbols/custom-marker.png");
      MapLogger.log('Custom marker image loaded successfully.');

      setGeofencePolygons(geofenceArrays);
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
      appBar: AppBar(
        title: Text(geofenceName),
      ),
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
          onMapClick: _handleMapClick,
          initialCameraPosition: const CameraPosition(
            target: LatLng(37.7749, -122.4194), // San Francisco
            zoom: 14.0,
          ),
          compassViewPosition: CompassViewPosition.topRight,
          compassEnabled: true,
        ),
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