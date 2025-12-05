import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Place> _nearbyPlaces = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentAddress; // Store the current address
  static const String _apiKey = 'AIzaSyBcGcEBlvFUKYEhWlquKAJgwZ6Ps0xGwGQ';

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure the screen is fully built
    Future.delayed(const Duration(milliseconds: 100), () {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if location services are enabled (with timeout)
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Error checking location service: $e');
        // Continue anyway - some platforms might not support this check
        serviceEnabled = true;
      }

      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled. Please enable them in settings.';
        });
        _showLocationSettingsDialog();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 5));
      
      debugPrint('Current permission status: $permission');
      
      // If permission is denied, request it
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        debugPrint('Requesting location permission...');
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10));
        debugPrint('Permission request result: $permission');
      }
      
      // Check the result after requesting
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are denied. Please enable them in settings.';
        });
        _showPermissionDeniedDialog();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are permanently denied. Please enable them in settings.';
        });
        _showPermissionDeniedDialog();
        return;
      }
      
      // If we have permission (whileInUse or always), proceed
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission not granted. Current status: $permission';
        });
        return;
      }

      // Double-check permission before getting position
      LocationPermission finalPermission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 5));
      debugPrint('Final permission check before getting position: $finalPermission');
      
      if (finalPermission == LocationPermission.denied || 
          finalPermission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission was not properly granted. Please enable it in System Preferences > Security & Privacy > Privacy > Location Services.';
        });
        _showPermissionDeniedDialog();
        return;
      }

      // Get current position (with timeout)
      debugPrint('Getting current position...');
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ).timeout(const Duration(seconds: 20));
        
        debugPrint('Got position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        
        // Get address from coordinates using geocoding (no API key needed!)
        await _getCurrentAddress();
        
        // Fetch nearby grocery stores
        await _fetchNearbyGroceryStores();
        
        setState(() {
          _isLoading = false;
        });
      } catch (positionError) {
        debugPrint('Error getting position: $positionError');
        // On macOS, even if permission is granted, the app needs to be enabled in System Preferences
        if (Platform.isMacOS) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Permission granted but unable to get location.\n\nPlease make sure this app is enabled in:\nSystem Preferences > Security & Privacy > Privacy > Location Services\n\nThen try again.';
          });
          _showPermissionDeniedDialog();
        } else {
          throw positionError; // Re-throw for general error handling
        }
      }
    } catch (e) {
      debugPrint('Error in _requestLocationPermission: $e');
      String errorMsg = e.toString();
      
      // Provide more helpful error messages
      if (errorMsg.contains('denied') || errorMsg.contains('permission')) {
        if (Platform.isMacOS) {
          errorMsg = 'Location permission issue.\n\nPlease check:\n1. System Preferences > Security & Privacy > Privacy > Location Services\n2. Make sure this app is listed and enabled\n3. Restart the app and try again';
        } else {
          errorMsg = 'Location permission denied. Please enable it in settings.';
        }
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error getting location: $errorMsg';
      });
    }
  }

  Future<void> _getCurrentAddress() async {
    if (_currentPosition == null) return;
    
    // Try device geocoding first (works on iOS/Android)
    try {
      if (!Platform.isMacOS) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ).timeout(const Duration(seconds: 10));
        
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          final addressParts = <String>[];
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          
          if (addressParts.isNotEmpty) {
            setState(() {
              _currentAddress = addressParts.join(', ');
            });
            return; // Success!
          }
        }
      }
    } catch (e) {
      debugPrint('Device geocoding failed: $e');
    }
    
    // Fallback: Use OpenStreetMap Nominatim for reverse geocoding (free, works on all platforms!)
    try {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(queryParameters: {
        'format': 'json',
        'lat': lat.toString(),
        'lon': lng.toString(),
        'addressdetails': '1',
      });
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FoodRecipesApp/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          setState(() {
            _currentAddress = data['display_name'].toString();
          });
          debugPrint('Address from Nominatim: $_currentAddress');
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding failed: $e');
      // Will just show coordinates as fallback
    }
  }

  Future<void> _fetchNearbyGroceryStores() async {
    if (_currentPosition == null) return;

    try {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      
      // Search for grocery stores using Google Places API
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=$lat,$lng&'
        'radius=5000&'
        'type=grocery_or_supermarket&'
        'key=$_apiKey',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _nearbyPlaces = (data['results'] as List)
                .map((place) => Place.fromJson(place))
                .toList();
            _errorMessage = ''; // Clear any previous error
          });
        } else {
          String errorDetail = data['error_message'] ?? '';
          String status = data['status'] ?? 'UNKNOWN';
          
          String userMessage = 'No grocery stores found nearby.\n\n'
              'Try searching in a different area.';
          
          // Only show detailed errors for debugging, otherwise keep it simple
          if (status == 'ZERO_RESULTS') {
            userMessage = 'No grocery stores found nearby.\n\n'
                'Try searching in a different area.';
          }
          
          setState(() {
            _errorMessage = userMessage;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error fetching places: HTTP ${response.statusCode}\n\n'
              'Unable to connect to Google Places API. Please check your internet connection.';
        });
      }
    } catch (e) {
      debugPrint('Error fetching from Google Places API: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}\n\nPlease check your internet connection and try again.';
      });
    }
  }

  Future<void> _openSettings() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await openAppSettings();
      } else if (Platform.isMacOS) {
        // Open macOS System Preferences to Location Services
        final uri = Uri.parse('x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Fallback: try opening System Preferences directly
          await Process.run('open', ['-b', 'com.apple.systempreferences']);
        }
      } else {
        // For other platforms, show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please enable location permissions in your system settings manually.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // If opening settings fails, try alternative method for macOS
      if (Platform.isMacOS) {
        try {
          await Process.run('open', ['-b', 'com.apple.systempreferences']);
        } catch (e2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Unable to open settings. Please go to System Preferences > Security & Privacy > Privacy > Location Services.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        // For other platforms, show a helpful message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to open settings. Please enable location permissions manually in your device settings.',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: Text(
          Platform.isMacOS
              ? 'On macOS, you need to enable location access in TWO places:\n\n1. Grant permission when the app asks (you did this ✓)\n2. Enable the app in System Preferences:\n   • Open System Preferences\n   • Go to Security & Privacy > Privacy > Location Services\n   • Make sure Location Services is ON\n   • Find "food_recipes_app" in the list\n   • Check the box next to it\n   • If you don\'t see it, unlock settings (click lock icon) and restart the app\n\nThen click "Open Settings" below.'
              : 'To find nearby grocery stores, please enable location permissions in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: Text(
          Platform.isMacOS
              ? 'Please enable location services in System Preferences to find nearby grocery stores.\n\nGo to: System Preferences > Security & Privacy > Privacy > Location Services\n\nNote: If you don\'t see this app in the list, unlock the settings (click the lock icon) and restart the app.'
              : 'Please enable location services in your device settings to find nearby grocery stores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
        ),
      );
    }

    // Add grocery store markers
    for (var place in _nearbyPlaces) {
      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: place.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.vicinity,
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Grocery Stores'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Requesting location permission...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = false;
                        _errorMessage = 'Location request cancelled. Please try again.';
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            )
          : _currentPosition == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage.isNotEmpty 
                              ? _errorMessage 
                              : 'Unable to get your location',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _requestLocationPermission,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Platform.isMacOS
                  ? _buildMacOSView()
                  : Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 14,
                          ),
                          markers: _buildMarkers(),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          mapType: MapType.normal,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                        ),
                    // Show error message as overlay if API failed but location is available
                    if (_errorMessage.isNotEmpty && _nearbyPlaces.isEmpty)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Show success message if stores found
                    if (_nearbyPlaces.isNotEmpty)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Found Grocery Stores',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_nearbyPlaces.length} stores nearby',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildMacOSView() {
    return Column(
      children: [
        // Location info card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[700], size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_currentAddress != null && _currentAddress!.isNotEmpty)
                      Text(
                        _currentAddress!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[800],
                        ),
                      )
                    else
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                        'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Stores list or message
        Expanded(
          child: _nearbyPlaces.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage.isNotEmpty
                              ? _errorMessage
                              : 'No grocery stores found nearby.\n\n'
                                  'Note: Interactive maps are not supported on macOS.\n'
                                  'Stores will be listed here when found.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchNearbyGroceryStores,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _nearbyPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _nearbyPlaces[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.store, color: Colors.white),
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: place.vicinity != null
                            ? Text(place.vicinity!)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.directions),
                          onPressed: () {
                            // Open in Google Maps
                            final url = 'https://www.google.com/maps/search/?api=1&query='
                                '${place.location.latitude},${place.location.longitude}';
                            launchUrl(Uri.parse(url));
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class Place {
  final String id;
  final String name;
  final LatLng location;
  final String? vicinity;
  final double? rating;

  Place({
    required this.id,
    required this.name,
    required this.location,
    this.vicinity,
    this.rating,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      location: LatLng(
        json['geometry']['location']['lat'],
        json['geometry']['location']['lng'],
      ),
      vicinity: json['vicinity'],
      rating: json['rating']?.toDouble(),
    );
  }
}

