import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LatLng _initialPosition = LatLng(13.7563, 121.0600); // Coordinates for Batangas, PH
  LatLng? _selectedPosition;
  double _zoom = 14.0; // Initial zoom level
  final double _minZoom = 5.0; // Minimum zoom level
  final double _maxZoom = 18.0; // Maximum zoom level

  final MapController _mapController = MapController(); // MapController to control the map

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: _zoom,
              onTap: (tapPosition, position) {
                setState(() {
                  _selectedPosition = position;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              if (_selectedPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPosition!,
                      width: 80.0,
                      height: 80.0,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    setState(() {
                      if (_zoom < _maxZoom) {
                        _zoom += 1.0;
                        _mapController.move(_mapController.camera.center, _zoom); // Update the map's zoom level
                      }
                    });
                  },
                  child: Icon(Icons.zoom_in),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    setState(() {
                      if (_zoom > _minZoom) {
                        _zoom -= 1.0;
                        _mapController.move(_mapController.camera.center, _zoom); // Update the map's zoom level
                      }
                    });
                  },
                  child: Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedPosition != null) {
            Navigator.pop(context, _selectedPosition);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please select a location on the map.'),
              ),
            );
          }
        },
        child: Icon(Icons.check),
      ),
    );
  }
}
