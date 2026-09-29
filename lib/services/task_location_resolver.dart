// ============================================================
// FILE: lib/services/task_location_resolver.dart (NEW)
//
// PURPOSE
// Resolves an embeddable-map LatLng for a Volunteer pickup task,
// WITHOUT inventing coordinates and WITHOUT changing any existing
// task/donation field names or types. Used only to power the
// embedded Google Map + "Open in Google Maps" button on the
// Volunteer Task Details screen.
//
// PRIORITY ORDER (per task requirements):
//   PRIORITY 1 — task doc already has valid 'latitude' + 'longitude'
//   PRIORITY 2 — task doc's 'location' field already holds coordinates
//                (a Firestore GeoPoint, or a Map with lat/lng keys).
//                NOTE: in the current DonateHub codebase,
//                ManagerTasksController.assignVolunteer() stores
//                'location' as a plain address STRING (a copy of
//                'pickupAddress'), so this branch is future-proofing
//                for any task/document that stores it differently —
//                it is intentionally skipped for a String value.
//   PRIORITY 3 — geocode the free-text 'pickupAddress' (or the
//                'location' string) using the device geocoder
//                (package:geocoding). Retries once with ", Pakistan"
//                appended for short city/area-only addresses
//                (Islamabad, Rawalpindi, Lahore, Peshawar, Attock,
//                Taxila, etc.) without guessing an unrelated location
//                if geocoding is ambiguous or fails outright.
//
// After a successful Priority-3 geocode, the resolved latitude/
// longitude are opportunistically cached back onto the SAME
// 'tasks/{taskId}' document (two new fields only — no existing
// field is replaced, no new collection is created) so the same
// task does not need to be re-geocoded every time it is reopened.
// This cache write is best-effort: if it fails for any reason
// (offline, security rules, etc.) the map still works normally —
// caching is a performance optimization only, never a requirement.
//
// This file does NOT read, store, or transmit the Volunteer's own
// device location. That is handled entirely on-device by the
// TaskPickupMapSection widget, on demand, and only after the
// Volunteer explicitly grants permission.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TaskLocationSource { storedCoordinates, geocodedAddress }

class TaskLocationResult {
  final LatLng? coordinates;
  final TaskLocationSource? source;
  final String? errorMessage;

  const TaskLocationResult.success(LatLng coords, TaskLocationSource src)
      : coordinates = coords,
        source = src,
        errorMessage = null;

  const TaskLocationResult.failure(String message)
      : coordinates = null,
        source = null,
        errorMessage = message;

  bool get hasCoordinates => coordinates != null;
}

class TaskLocationResolver {
  /// Resolves the pickup coordinates for [taskData] (the same
  /// Map<String,dynamic> already passed into VolunteerTaskDetailScreen).
  /// [taskId] is used only for the optional best-effort coordinate
  /// cache write described above — pass an empty string to disable
  /// caching entirely (resolution still works without it).
  static Future<TaskLocationResult> resolve(
      String taskId,
      Map<String, dynamic> taskData,
      ) async {
    // ── PRIORITY 1 — explicit latitude/longitude fields ──────────────
    final direct = _fromDirectFields(taskData);
    if (direct != null) {
      return TaskLocationResult.success(direct, TaskLocationSource.storedCoordinates);
    }

    // ── PRIORITY 2 — 'location' field already holding coordinates ────
    final fromLocationField = _fromLocationField(taskData['location']);
    if (fromLocationField != null) {
      return TaskLocationResult.success(fromLocationField, TaskLocationSource.storedCoordinates);
    }

    // ── PRIORITY 3 — geocode the text address ─────────────────────────
    final String address = _resolveAddressText(taskData);
    if (address.isEmpty) {
      return const TaskLocationResult.failure(
        'No pickup address was provided for this task.',
      );
    }

    if (kIsWeb) {
      // package:geocoding has no web implementation. Rather than
      // crashing or silently guessing, we surface this clearly — the
      // pickup address text and "Open in Google Maps" (which works
      // fine with a text address) remain fully usable on web.
      return const TaskLocationResult.failure(
        'The embedded map for a text address is available in the DonateHub mobile app. '
            'You can still use "Open in Google Maps" below.',
      );
    }

    final result = await _geocodeAddress(address);
    if (result.hasCoordinates) {
      // Fire-and-forget — never blocks or fails the map for the user.
      _cacheCoordinatesQuietly(
        taskId,
        result.coordinates!.latitude,
        result.coordinates!.longitude,
      );
    }
    return result;
  }

  // ==========================================================================
  // PRIORITY 1
  // ==========================================================================
  static LatLng? _fromDirectFields(Map<String, dynamic> taskData) {
    final lat = _asDouble(taskData['latitude']);
    final lng = _asDouble(taskData['longitude']);
    return _validLatLngOrNull(lat, lng);
  }

  // ==========================================================================
  // PRIORITY 2
  // ==========================================================================
  static LatLng? _fromLocationField(dynamic locationValue) {
    if (locationValue is GeoPoint) {
      return _validLatLngOrNull(locationValue.latitude, locationValue.longitude);
    }
    if (locationValue is Map) {
      final lat = _asDouble(locationValue['latitude'] ?? locationValue['lat']);
      final lng = _asDouble(locationValue['longitude'] ?? locationValue['lng']);
      return _validLatLngOrNull(lat, lng);
    }
    // A plain String 'location' (today's DonateHub convention — see
    // ManagerTasksController.assignVolunteer) is an address, not
    // coordinates, so it intentionally falls through to Priority 3.
    return null;
  }

  static String _resolveAddressText(Map<String, dynamic> taskData) {
    final pickupAddress = (taskData['pickupAddress'] ?? '').toString().trim();
    if (pickupAddress.isNotEmpty) return pickupAddress;
    final location = taskData['location'];
    if (location is String && location.trim().isNotEmpty) return location.trim();
    return '';
  }

  // ==========================================================================
  // PRIORITY 3 — GEOCODING
  // ==========================================================================
  static Future<TaskLocationResult> _geocodeAddress(String address) async {
    try {
      List<geocoding.Location> results = await geocoding.locationFromAddress(address);

      if (results.isEmpty && !address.toLowerCase().contains('pakistan')) {
        // Many pickup addresses are just a city/area/street name
        // (e.g. "G-11 Islamabad", "Attock", "Taxila Cantt") without a
        // country — retry once with the country appended rather than
        // guessing an unrelated location.
        try {
          results = await geocoding.locationFromAddress('$address, Pakistan');
        } catch (_) {
          // Handled by the empty-results check right below.
        }
      }

      if (results.isEmpty) {
        return TaskLocationResult.failure(
          'Couldn\'t find "$address" on the map. The pickup address is still shown above.',
        );
      }

      final match = results.first;
      final latLng = _validLatLngOrNull(match.latitude, match.longitude);
      if (latLng == null) {
        return const TaskLocationResult.failure(
          'The location service returned an invalid position for this address.',
        );
      }
      return TaskLocationResult.success(latLng, TaskLocationSource.geocodedAddress);
    } catch (e) {
      // Covers: no internet, platform geocoder unavailable, malformed
      // address, or any other geocoding failure. Never thrown further.
      return const TaskLocationResult.failure(
        'Could not resolve this address right now. Check your internet connection and try again.',
      );
    }
  }

  // ==========================================================================
  // OPTIONAL BEST-EFFORT CACHE WRITE (Priority-3 results only)
  // ==========================================================================
  static Future<void> _cacheCoordinatesQuietly(
      String taskId,
      double lat,
      double lng,
      ) async {
    if (taskId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'latitude': lat,
        'longitude': lng,
      });
    } catch (_) {
      // Best-effort only. Caching is a performance optimization for the
      // next time this task is opened — never required for the map or
      // navigation feature to work correctly right now.
    }
  }

  // ==========================================================================
  // SHARED VALIDATION HELPERS
  // ==========================================================================
  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static LatLng? _validLatLngOrNull(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    // (0, 0) — "Null Island" — is the classic sign of an unset or
    // placeholder value rather than a genuine pickup point.
    if (lat == 0 && lng == 0) return null;
    return LatLng(lat, lng);
  }
}