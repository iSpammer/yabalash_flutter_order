import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class GoogleMapsService {
  // Google Maps API Key - should be the same as configured in the app
  static const String _apiKey = 'AIzaSyCHehIUKqyXbRCXQ823_AJ0gZEAY0Bn2Os';
  
  /// Get directions between two points
  static Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          // Extract polyline points
          final polylinePoints = decodePolyline(route['overview_polyline']['points']);
          
          // Extract distance and duration
          final leg = route['legs'][0];
          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];
          
          return {
            'polylinePoints': polylinePoints,
            'distance': distance,
            'duration': duration,
            'bounds': {
              'northeast': LatLng(
                route['bounds']['northeast']['lat'],
                route['bounds']['northeast']['lng'],
              ),
              'southwest': LatLng(
                route['bounds']['southwest']['lat'],
                route['bounds']['southwest']['lng'],
              ),
            },
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting directions: $e');
    }
    
    return null;
  }
  
  /// Decode polyline string to list of LatLng
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      points.add(LatLng(latitude, longitude));
    }

    return points;
  }
  
  /// Calculate estimated time of arrival
  static DateTime calculateETA(String duration) {
    // Parse duration string (e.g., "15 mins" or "1 hour 30 mins")
    int totalMinutes = 0;
    
    final hourMatch = RegExp(r'(\d+)\s*hour').firstMatch(duration);
    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }
    
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(duration);
    if (minMatch != null) {
      totalMinutes += int.parse(minMatch.group(1)!);
    }
    
    return DateTime.now().add(Duration(minutes: totalMinutes));
  }
}