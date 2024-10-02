import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Pass your access token to MapboxOptions so you can load a map
  String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  // Define options for your camera
  CameraOptions camera = CameraOptions(
    center: Point(coordinates: Position(-98.0, 39.5)),
    zoom: 2,
    bearing: 0,
    pitch: 0);

  // Run your application, passing your CameraOptions to the MapWidget
  runApp(MaterialApp(home: MapWidget(
    cameraOptions: camera,
    // styleUri: 'https://api.maptiler.com/maps/streets/style.json?key=QBMCVBrM2oLPkQgiPdQV',
    styleUri: 'https://api.maptiler.com/maps/ocean/style.json?key=QBMCVBrM2oLPkQgiPdQV',
  )));
}