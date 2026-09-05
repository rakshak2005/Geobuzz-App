import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../../core/services/location_service.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng initialPosition;
  final double radiusMeters;
  final Function(LatLng position, String address) onLocationChanged;

  const LocationPickerMap({
    super.key,
    required this.initialPosition,
    required this.radiusMeters,
    required this.onLocationChanged,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late MapController _mapController;
  late LatLng _selectedPosition;
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  bool _isSearching = false;
  String _currentAddress = 'Selected Location';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPosition = widget.initialPosition;
    _autoLocate();
  }

  Future<void> _autoLocate() async {
    // If LocationService has a recent position or can fetch current position, move to it immediately
    final cached = LocationService.instance.currentPosition.value;
    if (cached != null) {
      final pos = LatLng(cached.latitude, cached.longitude);
      if (mounted) {
        setState(() {
          _selectedPosition = pos;
        });
        _mapController.move(pos, 15.0);
        _reverseGeocode(pos);
      }
      return;
    }

    _reverseGeocode(_selectedPosition);

    try {
      final currentPos = await LocationService.instance.getCurrentLocation();
      if (currentPos != null && mounted) {
        final pos = LatLng(currentPos.latitude, currentPos.longitude);
        setState(() {
          _selectedPosition = pos;
        });
        _mapController.move(pos, 15.0);
        _reverseGeocode(pos);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // OpenStreetMap Nominatim Pure REST Reverse Geocoding (No native platform SDK compile errors)
  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': pos.latitude,
          'lon': pos.longitude,
          'format': 'json',
        },
        options: Options(
          headers: {'User-Agent': 'GeoBuzz-Location-OS/1.0'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (!mounted) return;
      if (res.statusCode == 200 && res.data != null && res.data['display_name'] != null) {
        final displayName = res.data['display_name'] as String;
        final parts = displayName.split(',');
        final shortAddress = parts.length > 2 ? '${parts[0]}, ${parts[1]}' : displayName;
        setState(() {
          _currentAddress = shortAddress;
        });
        widget.onLocationChanged(pos, _currentAddress);
      } else {
        _setFallbackAddress(pos);
      }
    } catch (_) {
      if (mounted) {
        _setFallbackAddress(pos);
      }
    }
  }

  void _setFallbackAddress(LatLng pos) {
    setState(() {
      _currentAddress = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    });
    widget.onLocationChanged(pos, _currentAddress);
  }

  // OpenStreetMap Nominatim Forward Geocoding Search
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
        options: Options(
          headers: {'User-Agent': 'GeoBuzz-Location-OS/1.0'},
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

      if (!mounted) return;

      if (res.statusCode == 200 && res.data is List && (res.data as List).isNotEmpty) {
        final item = (res.data as List).first;
        final lat = double.tryParse(item['lat'] ?? '');
        final lon = double.tryParse(item['lon'] ?? '');

        if (lat != null && lon != null) {
          final newPos = LatLng(lat, lon);
          setState(() {
            _selectedPosition = newPos;
            _currentAddress = item['display_name'] ?? query;
          });
          _mapController.move(newPos, 15.0);
          widget.onLocationChanged(newPos, _currentAddress);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching locations found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // OpenStreetMap Vector & Raster Tiles
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedPosition,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              setState(() {
                _selectedPosition = point;
              });
              _reverseGeocode(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.geobuzz.geobuzz',
            ),

            // Geofence Circle Preview
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _selectedPosition,
                  radius: widget.radiusMeters,
                  useRadiusInMeter: true,
                  color: const Color(0xFF00A2A5).withValues(alpha: 0.18),
                  borderColor: const Color(0xFF00A2A5),
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            // Anchor Target Location Marker
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedPosition,
                  width: 42,
                  height: 42,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A2A5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A2A5).withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.place_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Search Bar Overlay (Clean light rounded style)
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search_rounded, color: Color(0xFF00A2A5), size: 19),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: 'Search city, landmark, or address...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                      isDense: true,
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A2A5)),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF00A2A5)),
                    onPressed: () => _searchLocation(_searchController.text),
                  ),
              ],
            ),
          ),
        ),

        // Floating Address Indicator (Clean White Pill)
        Positioned(
          bottom: 12,
          left: 12,
          right: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F7F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFF00A2A5), size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick GPS Recenter Button
        Positioned(
          bottom: 12,
          right: 12,
          child: InkWell(
            onTap: () async {
              final pos = await LocationService.instance.getCurrentLocation();
              if (pos != null && mounted) {
                final newCenter = LatLng(pos.latitude, pos.longitude);
                setState(() {
                  _selectedPosition = newCenter;
                });
                _mapController.move(newCenter, 15.0);
                _reverseGeocode(newCenter);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF00A2A5), size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
