import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding package

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LatLng _initialPosition = LatLng(13.7563, 121.0600); // Default location
  LatLng? _selectedPosition;
  double _zoom = 14.0;
  final double _minZoom = 5.0;
  final double _maxZoom = 18.0;

  final MapController _mapController = MapController();
  TextEditingController _searchController = TextEditingController(); // Controller for search

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
          'Select Location',
          style: GoogleFonts.indieFlower(
              fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              await _searchLocation();
            },
          ),
        ],
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
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
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
            top: 20,
            left: 20,
            right: 20,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Place',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
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
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        foregroundColor: Colors.black,
        onPressed: () {
          if (_selectedPosition != null) {
            Navigator.pop(context, _selectedPosition);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/aralink-main-logo.png',
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Please select a location on the map.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Iconsax.warning_25,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                backgroundColor: Colors.teal,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: Icon(Icons.check),
      ),
    );
  }

  // Function to search location
  Future<void> _searchLocation() async {
    String searchQuery = _searchController.text;
    if (searchQuery.isEmpty) return;

    try {
      // Get list of locations
      List<Location> locations = await locationFromAddress(searchQuery);
      if (locations.isNotEmpty) {
        // Use the first location from the result
        Location location = locations.first;
        setState(() {
          _selectedPosition = LatLng(location.latitude, location.longitude);
        });
        _mapController.move(_selectedPosition!, _zoom);
      } else {
        _showSnackBar("No location found.");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  // Show a Snackbar for error or info
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }
}
