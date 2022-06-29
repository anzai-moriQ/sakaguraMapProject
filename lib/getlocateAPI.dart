import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/**
 * geolocatorで位置情報を扱うためのクラス
 */
class GetLocateAPI {
  // GeoLocateで現在の位置情報を取得する
  Future<CameraPosition> getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return Future.value(
        convert(position.latitude, position.longitude, 14.4746));
  }

  // CameraPositionクラスに位置情報を成形する
  CameraPosition convert(double latitude, double longitude, double zoom) {
    return CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom,
    );
  }
}
