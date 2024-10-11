# flutter_maplibre_geofence

A Flutter project that demonstrates geofencing functionality using MapLibre.

## Features

- Draw polygons on a map to create geofences
- Edit existing geofences by dragging vertices
- Delete geofences
- Visual representation of geofences with numbered vertices
- Zoom and pan map controls

## Getting Started

### Prerequisites

- Flutter SDK (version X.X.X or higher)
- Dart SDK (version X.X.X or higher)
- MapLibre GL Native (version X.X.X)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/flutter_maplibre_geofence.git
   ```

2. Navigate to the project directory:
   ```
   cd flutter_maplibre_geofence
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Usage

1. Open the app to see the map interface.
2. Use the '+' button to start drawing a new geofence.
3. Tap on the map to add vertices to your geofence.
4. Tap the finish button to complete the geofence.
5. Drag vertices to edit existing geofences.
6. Use the '-' button to delete geofences.

## Configuration

To use your own MapLibre style or API key, modify the `maplibre_options` in `lib/main.dart`:

```dart
MaplibreMapOptions(
  styleString: 'YOUR_MAPLIBRE_STYLE_URL',
  // other options...
)
```
## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- MapLibre for providing the mapping functionality
- Flutter community for continuous support and resources
