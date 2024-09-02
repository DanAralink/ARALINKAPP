import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';

class LocationDetailsScreen extends StatefulWidget {
  final String latitude;
  final String longitude;

  LocationDetailsScreen({required this.latitude, required this.longitude});

  @override
  _LocationDetailsScreenState createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  late LatLng _position;
  double _zoom = 14.0;
  final double _minZoom = 5.0;
  final double _maxZoom = 18.0;

  final MapController _mapController = MapController();
  @override
  void initState() {
    super.initState();
    final double lat = double.tryParse(widget.latitude) ?? 0.0;
    final double lng = double.tryParse(widget.longitude) ?? 0.0;
    _position = LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Iconsax.arrow_left_2,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 240, 183),
          title: Text(
            'Location Details',
            style: GoogleFonts.indieFlower(
                fontSize: 22, fontWeight: FontWeight.bold),
          )),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _position,
              initialZoom: _zoom,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _position,
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
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  backgroundColor: const Color.fromARGB(255, 255, 240, 183),
                  foregroundColor: Colors.black,
                  heroTag: 'zoom_in',
                  onPressed: () {
                    setState(() {
                      if (_zoom < _maxZoom) {
                        _zoom += 1.0;
                        _mapController.move(
                            _mapController.camera.center, _zoom);
                      }
                    });
                  },
                  child: Icon(Iconsax.search_zoom_in),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  backgroundColor: const Color.fromARGB(255, 255, 240, 183),
                  foregroundColor: Colors.black,
                  heroTag: 'zoom_out',
                  onPressed: () {
                    setState(() {
                      if (_zoom > _minZoom) {
                        _zoom -= 1.0;
                        _mapController.move(
                            _mapController.camera.center, _zoom);
                      }
                    });
                  },
                  child: Icon(Iconsax.search_zoom_out),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
