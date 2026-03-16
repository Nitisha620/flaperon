import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GeoCodingService {
  static Future<LatLng?> getLatLng(String address) async {
    final String apiKey = "AIzaSyDPTspFcq0ZZ_Nbjg7HkSQ1toulXqW2XdQ";

    final url = "https://maps.googleapis.com/maps/api/geocode/json"
        "?address=${Uri.encodeComponent(address)}"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);

    if (data['status'] != 'OK') return null;

    final location = data['results'][0]['geometry']['location'];
    return LatLng(location['lat'], location['lng']);
  }
}
