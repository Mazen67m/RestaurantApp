import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/locale_provider.dart';

class SelectLocationScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  
  const SelectLocationScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  // Default location (Dubai, UAE as example)
  late double _latitude;
  late double _longitude;
  String? _addressText;
  bool _isLoading = false;
  bool _isDragging = false;
  
  // Simulated map center offset
  Offset _markerOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude ?? 25.2048;
    _longitude = widget.initialLongitude ?? 55.2708;
  }

  void _onMapTap(Offset localPosition, Size size) {
    // Simulate moving the pin on the map
    setState(() {
      _markerOffset = Offset(
        localPosition.dx - size.width / 2,
        localPosition.dy - size.height / 2,
      );
      
      // Simulate coordinate changes based on tap position
      // This is a placeholder - in real implementation, use Google Maps
      _latitude += (_markerOffset.dy / 10000);
      _longitude += (_markerOffset.dx / 10000);
    });
    
    _getAddressFromCoordinates();
  }

  Future<void> _getAddressFromCoordinates() async {
    setState(() => _isLoading = true);
    
    // Simulate geocoding delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In real implementation, use Google Geocoding API or geolocator package
    setState(() {
      _addressText = 'Selected Location\n${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}';
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    // In real implementation, use geolocator package
    // For now, simulate getting current location
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      // Simulated current location (Dubai)
      _latitude = 25.2048 + (DateTime.now().millisecond / 100000);
      _longitude = 55.2708 + (DateTime.now().millisecond / 100000);
      _markerOffset = Offset.zero;
      _isLoading = false;
    });
    
    _getAddressFromCoordinates();
  }

  void _confirmLocation() {
    Navigator.of(context).pop({
      'latitude': _latitude,
      'longitude': _longitude,
      'address': _addressText?.split('\n').first,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('select_location')),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: Text(
              context.tr('confirm'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map placeholder
          _buildMapPlaceholder(),
          
          // Center pin
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(
                0,
                _isDragging ? -20 : 0,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      context.tr('drag_to_adjust'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Current location button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              heroTag: 'currentLocation',
              mini: true,
              onPressed: _isLoading ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          
          // Zoom buttons
          Positioned(
            right: 16,
            bottom: 260,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  onPressed: () {
                    // Zoom in - in real implementation, control map camera
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textPrimary,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  onPressed: () {
                    // Zoom out - in real implementation, control map camera
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textPrimary,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          
          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanEnd: (_) {
        setState(() => _isDragging = false);
        _getAddressFromCoordinates();
      },
      onPanUpdate: (details) {
        setState(() {
          // Simulate map panning by adjusting coordinates
          _latitude -= details.delta.dy / 5000;
          _longitude += details.delta.dx / 5000;
        });
      },
      onTapUp: (details) {
        _onMapTap(details.localPosition, MediaQuery.of(context).size);
      },
      child: Container(
        color: Colors.grey[200],
        child: Stack(
          children: [
            // Map placeholder image
            Positioned.fill(
              child: Image.asset(
                'assets/images/map_placeholder.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.6),
              ),
            ),
            // Center crosshair
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            // Coordinates display
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lat: ${_latitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Lng: ${_longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Map note
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('map_placeholder'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Address display
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('selected_address'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _addressText ?? context.tr('move_pin_to_select'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                child: Text(
                  context.tr('confirm_location'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
