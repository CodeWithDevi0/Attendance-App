import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialRadius;

  const LocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.initialRadius,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late double _lat;
  late double _lng;
  late double _radius;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lng = widget.initialLng;
    _radius = widget.initialRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Event Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, {
                'lat': _lat,
                'lng': _lng,
                'radius': _radius,
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: latlng.LatLng(_lat, _lng),
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _lat = point.latitude;
                    _lng = point.longitude;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.attendanceapp',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: latlng.LatLng(_lat, _lng),
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: latlng.LatLng(_lat, _lng),
                      radius: _radius,
                      color: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Latitude: ${_lat.toStringAsFixed(6)}'),
                Text('Longitude: ${_lng.toStringAsFixed(6)}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Radius (m): '),
                    Expanded(
                      child: Slider(
                        value: _radius,
                        min: 10,
                        max: 1000,
                        divisions: 99,
                        label: _radius.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _radius = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Text('Radius: ${_radius.round()} meters'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}