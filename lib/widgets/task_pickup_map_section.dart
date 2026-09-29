// ============================================================
// FILE: lib/widgets/task_pickup_map_section.dart (NEW)
//
// PURPOSE
// Additive UI section dropped into the EXISTING Volunteer Task
// Details screen (VolunteerTaskDetailScreen). Shows the pickup
// location on an embedded Google Map with a destination marker,
// an optional on-device "current location" marker (added only
// after the Volunteer explicitly grants permission — never
// stored or transmitted anywhere), and a button that opens
// Google Maps for turn-by-turn navigation using the resolved
// coordinates.
//
// This widget does NOT touch task status, donation status,
// volunteer rewards, or notifications. It reads the task data
// already available on VolunteerTaskDetailScreen and delegates
// all coordinate resolution to TaskLocationResolver.
//
// NOT implemented here (by design, per requirements):
//   - live/continuous volunteer location tracking
//   - background GPS tracking
//   - sending the volunteer's location to Firestore/Manager/Admin
//   - geofencing / ETA
// Location is fetched at most once per tap of "Show my current
// location", purely to draw a local marker on this device.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/task_location_resolver.dart';

enum _MapLoadState { loading, resolved, error }

enum _MyLocationState {
  idle,
  locating,
  shown,
  deniedOnce,
  deniedForever,
  serviceDisabled,
  failed,
}

class TaskPickupMapSection extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;
  final String pickupAddress;

  const TaskPickupMapSection({
    super.key,
    required this.taskId,
    required this.taskData,
    required this.pickupAddress,
  });

  @override
  State<TaskPickupMapSection> createState() => _TaskPickupMapSectionState();
}

class _TaskPickupMapSectionState extends State<TaskPickupMapSection> {
  static const Color _green = Color(0xFF1B6B3A);
  static const double _mapHeight = 200;

  _MapLoadState _state = _MapLoadState.loading;
  String? _errorMessage;
  LatLng? _pickupLatLng;

  _MyLocationState _myLocationState = _MyLocationState.idle;
  LatLng? _myLatLng;
  String? _myLocationMessage;

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _state = _MapLoadState.loading;
      _errorMessage = null;
    });

    final result = await TaskLocationResolver.resolve(widget.taskId, widget.taskData);
    if (!mounted) return;

    if (result.hasCoordinates) {
      setState(() {
        _pickupLatLng = result.coordinates;
        _state = _MapLoadState.resolved;
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'Could not determine the pickup location.';
        _state = _MapLoadState.error;
      });
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _myLocationState = _MyLocationState.locating;
      _myLocationMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _myLocationState = _MyLocationState.serviceDisabled;
          _myLocationMessage = 'Location services are turned off on this device.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _myLocationState = _MyLocationState.deniedOnce;
          _myLocationMessage = 'Location permission denied. You can still see the pickup point on the map.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _myLocationState = _MyLocationState.deniedForever;
          _myLocationMessage = 'Location permission is permanently denied. Enable it from app settings to see your position.';
        });
        return;
      }

      // permission is whileInUse or always — safe to read location once.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;

      final myLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _myLatLng = myLatLng;
        _myLocationState = _MyLocationState.shown;
        _myLocationMessage = null;
      });

      if (_pickupLatLng != null) {
        _fitBothPoints(_pickupLatLng!, myLatLng);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _myLocationState = _MyLocationState.failed;
        _myLocationMessage = 'Could not get your current location right now.';
      });
    }
  }

  void _fitBothPoints(LatLng a, LatLng b) {
    final controller = _mapController;
    if (controller == null) return;
    final southwest = LatLng(
      a.latitude < b.latitude ? a.latitude : b.latitude,
      a.longitude < b.longitude ? a.longitude : b.longitude,
    );
    final northeast = LatLng(
      a.latitude > b.latitude ? a.latitude : b.latitude,
      a.longitude > b.longitude ? a.longitude : b.longitude,
    );
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        60,
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    final latLng = _pickupLatLng;
    if (latLng == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&destination=${latLng.latitude},${latLng.longitude}'
          '&travelmode=driving',
    );

    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: _green),
              SizedBox(width: 6),
              Text('Pickup Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMapArea(),
          const SizedBox(height: 10),
          _buildMyLocationRow(),
          if (_state == _MapLoadState.resolved) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _openInGoogleMaps,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text(
                  'Open in Google Maps',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: _green),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    if (_state == _MapLoadState.loading) {
      return Container(
        height: _mapHeight,
        decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(14)),
        child: const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: _green),
          ),
        ),
      );
    }

    if (_state == _MapLoadState.error) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFCEBEA), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFC0392B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage ?? 'Could not load the map for this task.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFC0392B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: _resolveLocation,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC0392B),
                  side: const BorderSide(color: Color(0xFFC0392B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // resolved
    final destination = _pickupLatLng!;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup_destination'),
        position: destination,
        infoWindow: InfoWindow(title: 'Pickup Location', snippet: widget.pickupAddress),
      ),
      if (_myLatLng != null)
        Marker(
          markerId: const MarkerId('volunteer_current_location'),
          position: _myLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: _mapHeight,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: destination, zoom: 15),
          markers: markers,
          onMapCreated: (controller) => _mapController = controller,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          // Lets the map pan/zoom correctly while embedded inside the
          // screen's SingleChildScrollView instead of the two gesture
          // arenas fighting each other.
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
        ),
      ),
    );
  }

  Widget _buildMyLocationRow() {
    if (_state != _MapLoadState.resolved) return const SizedBox.shrink();

    if (_myLocationState == _MyLocationState.shown) {
      return const Row(
        children: [
          Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF2563EB)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Showing your current location on the map',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF2563EB)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _myLocationState == _MyLocationState.locating ? null : _useMyLocation,
          child: Row(
            children: [
              _myLocationState == _MyLocationState.locating
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _green),
              )
                  : const Icon(Icons.my_location_rounded, size: 14, color: _green),
              const SizedBox(width: 6),
              Text(
                _myLocationState == _MyLocationState.locating
                    ? 'Getting your location…'
                    : 'Show my current location',
                style: const TextStyle(fontSize: 11.5, color: _green, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (_myLocationMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _myLocationMessage!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              if (_myLocationState == _MyLocationState.deniedForever)
                TextButton(
                  onPressed: () => Geolocator.openAppSettings(),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: const Text('Settings', style: TextStyle(fontSize: 11)),
                ),
              if (_myLocationState == _MyLocationState.serviceDisabled)
                TextButton(
                  onPressed: () => Geolocator.openLocationSettings(),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: const Text('Enable', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}