import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_place/google_place.dart';

class loadJson {
  late String name;
  late String latitude;
  late String longitude;
  late String address;

  loadJson(this.name, this.latitude, this.longitude, this.address);

  loadJson.fromJson(Map<String, dynamic> json)
      : name = json['酒蔵名'],
        latitude = json['緯度'],
        longitude = json['経度'],
        address = json['住所'];

  static Future<Map<String, dynamic>> loadJsonAsset() async {
    String loadData = await rootBundle.loadString('JSON/placeList.json');
    final jsonResponse = json.decode(loadData);
    return jsonResponse;
  }

}
