import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Office locations supported for attendance check-in / check-out.
/// Attendance can be marked only from these office locations.
class OfficeLocation {
  final String name;
  final double latitude;
  final double longitude;

  const OfficeLocation(this.name, this.latitude, this.longitude);
}

const List<OfficeLocation> officeLocations = [
  OfficeLocation('TIRUNELVELI', 8.718412865303698, 77.73201179302228),
  OfficeLocation('THISAYANVILAI', 8.337947315572267, 77.86680851969136),
];

/// Maximum allowed distance (in meters) from an office to mark attendance.
const double maxOfficeDistanceMeters = 100;

class AttendanceLocationService {
  AttendanceLocationService._();

  /// Returns the distance in meters between two lat/lng points.
  static double distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final p1 = lat1 * pi / 180;
    final p2 = lat2 * pi / 180;
    final dp = (lat2 - lat1) * pi / 180;
    final dl = (lng2 - lng1) * pi / 180;
    final a = sin(dp / 2) * sin(dp / 2) +
        cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Checks which office location the given position is inside.
  /// Returns null when outside all supported offices.
  static OfficeLocation? nearestOffice(double lat, double lng) {
    OfficeLocation? best;
    var bestDistance = double.infinity;
    for (final office in officeLocations) {
      final d = distanceMeters(lat, lng, office.latitude, office.longitude);
      if (d < bestDistance) {
        bestDistance = d;
        best = office;
      }
    }
    return best != null && bestDistance <= maxOfficeDistanceMeters
        ? best
        : null;
  }

  /// Check-in closes 3 minutes after the staff's shift start time
  /// (defaults to 9:03 AM when no custom shift time is provided), matching the
  /// backend which uses `shiftStartTime + 3 minutes`.
  /// When an approved permission exists for the day, the check-in window is
  /// extended by the permission's duration hours (matching backend logic).
  static bool isCheckInTimeAllowed(
    DateTime now, {
    int extraHours = 0,
    int hour = 9,
    int minute = 3,
  }) {
    final cutoff = DateTime(now.year, now.month, now.day, hour, minute, 0, 0, 0)
        .add(Duration(hours: extraHours));
    return !now.isAfter(cutoff);
  }

  /// Gets the current position with permission handling.
  /// Throws a descriptive [String] error when unavailable.
  static Future<Position> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Enable GPS/Wi-Fi to mark attendance from the office location.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission is required to mark attendance from the office location.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is permanently denied. Allow access in App Settings to mark attendance.';
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Returns the office location the user is currently inside.
  /// Throws a descriptive [String] error when outside / unavailable.
  static Future<OfficeLocation> verifyOfficeLocation() async {
    final pos = await _getPosition();
    final office = nearestOffice(pos.latitude, pos.longitude);
    if (office == null) {
      throw 'You are not inside a supported office location (TIRUNELVELI / THISAYANVILAI). Attendance can be marked only from the office location.';
    }
    return office;
  }

  /// Verifies office location and returns (latitude, longitude, officeName).
  /// Throws a descriptive [String] error when outside / unavailable.
  static Future<(double, double, String)> verifiedPosition() async {
    final pos = await _getPosition();
    final office = nearestOffice(pos.latitude, pos.longitude);
    if (office == null) {
      throw 'You are not inside a supported office location (TIRUNELVELI / THISAYANVILAI). Attendance can be marked only from the office location.';
    }
    return (pos.latitude, pos.longitude, office.name);
  }
}