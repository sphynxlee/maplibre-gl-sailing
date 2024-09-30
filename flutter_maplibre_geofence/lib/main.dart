import 'package:flutter/material.dart';
import 'circle_geofence_page.dart';
import 'polygon_geofence_page.dart';

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
      home: const MainMenuPage(),
      routes: {
        '/circleGeofence': (context) => const CircleGeofencePage(),
        '/polygonGeofence': (context) => const PolygonGeofencePage(),
      },
    );
  }
}

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geofence Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Circle Geofence'),
              onPressed: () {
                Navigator.pushNamed(context, '/circleGeofence');
              },
            ),
            ElevatedButton(
              child: const Text('Polygon Geofence'),
              onPressed: () {
                Navigator.pushNamed(context, '/polygonGeofence');
              },
            ),
          ],
        ),
      ),
    );
  }
}
