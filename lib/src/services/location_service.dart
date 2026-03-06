import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static Future<String?> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Construct a human-readable address
        List<String> addressParts = [];
        
        // Add specific details while avoiding duplicates
        String? name = place.name;
        String? street = place.street;
        String? subLocality = place.subLocality;
        String? locality = place.locality;
        String? city = place.subAdministrativeArea ?? place.administrativeArea;

        if (name != null && name.isNotEmpty) {
          addressParts.add(name);
        }
        
        if (street != null && street.isNotEmpty && street != name) {
          addressParts.add(street);
        }
        
        if (subLocality != null && subLocality.isNotEmpty && subLocality != street) {
          addressParts.add(subLocality);
        }
        
        if (locality != null && locality.isNotEmpty) {
          addressParts.add(locality);
        }

        if (city != null && city.isNotEmpty && city != locality) {
          addressParts.add(city);
        }
        
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        return addressParts.join(', ');
      }
    } catch (e) {
      debugPrint("Error in reverse geocoding: $e");
    }
    return null;
  }
}
