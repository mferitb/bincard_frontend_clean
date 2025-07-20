import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const MapLocationPickerScreen({Key? key, this.initialLat, this.initialLng}) : super(key: key);

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  LatLng? _selectedLatLng;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLatLng = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedLatLng ?? LatLng(39.925533, 32.866287); // Ankara default
    return Scaffold(
      appBar: AppBar(title: const Text('Haritadan Konum Seç')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: initialCenter,
              zoom: 10,
              onTap: (tapPosition, latlng) {
                setState(() {
                  _selectedLatLng = latlng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.city_card.city_card',
              ),
              if (_selectedLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: _selectedLatLng!,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: _selectedLatLng == null
                  ? null
                  : () {
                      Navigator.pop(context, _selectedLatLng);
                    },
              icon: const Icon(Icons.check),
              label: const Text('Konumu Seç'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 