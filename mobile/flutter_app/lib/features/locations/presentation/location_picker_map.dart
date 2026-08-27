import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
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
  bool _isSearching = false;
  String _currentAddress = 'Selected Location';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPosition = widget.initialPosition;
    _reverseGeocode(_selectedPosition);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final name = p.name ?? p.street ?? '';
        final locality = p.locality ?? p.subAdministrativeArea ?? '';
        final fullAddress = name.isNotEmpty ? '$name, $locality' : locality;
        setState(() {
          _currentAddress = fullAddress.isNotEmpty
              ? fullAddress
              : 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
        });
        widget.onLocationChanged(pos, _currentAddress);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentAddress =
            'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
      });
      widget.onLocationChanged(pos, _currentAddress);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final locations = await locationFromAddress(query);
      if (!mounted) return;

      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newPos = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _selectedPosition = newPos;
        });
        _mapController.move(newPos, 15.0);
        await _reverseGeocode(newPos);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching locations found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    final pos = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;

    if (pos != null) {
      final newPos = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selectedPosition = newPos;
      });
      _mapController.move(newPos, 16.0);
      await _reverseGeocode(newPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. OpenStreetMap Tile Renderer
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedPosition,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              if (!mounted) return;
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
            // Geofence Radius Circle Layer
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _selectedPosition,
                  radius: widget.radiusMeters,
                  useRadiusInMeter: true,
                  color: AppColors.primary.withAlpha(60),
                  borderColor: AppColors.primary,
                  borderStrokeWidth: 2.0,
                ),
              ],
            ),
            // Center Pin Marker
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedPosition,
                  width: 50,
                  height: 50,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(128),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Search Box Floating Top Header
        Positioned(
          top: AppDimensions.md,
          left: AppDimensions.md,
          right: AppDimensions.md,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withAlpha(240),
              borderRadius: AppDimensions.roundedLg,
              border: Border.all(color: AppColors.borderDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.search_rounded, color: AppColors.primaryLight),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search city, landmark, or street...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryLight),
                    onPressed: () => _searchLocation(_searchController.text),
                  ),
              ],
            ),
          ),
        ),

        // 3. Current Location Center Button
        Positioned(
          bottom: AppDimensions.md,
          right: AppDimensions.md,
          child: FloatingActionButton.small(
            onPressed: _goToCurrentLocation,
            backgroundColor: AppColors.surfaceDark,
            foregroundColor: AppColors.primaryLight,
            elevation: 4,
            shape: const RoundedRectangleBorder(
              borderRadius: AppDimensions.roundedMd,
              side: BorderSide(color: AppColors.borderDark),
            ),
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }
}
