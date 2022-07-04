import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:geocoding/geocoding.dart';

import 'getlocateAPI.dart';
import 'json.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sake Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyMap(),
      // コピぺのUIを日本語に変更するための設定値
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate
      ],
    );
  }
}

class MyMap extends StatefulWidget {
  const MyMap({Key? key}) : super(key: key);

  @override
  State createState() => _MyMap();
}

class _MyMap extends State {
  Completer _controller = Completer();
  GetLocateAPI getLocateAPI = GetLocateAPI();

  // 検索フォームの表示bool　true: 非表示
  bool _searchBoolean = true;
  // 入力値と合致するデータを入れるMapオブジェクト
  Map<String, dynamic>? predictions = <String, dynamic>{};
  // 引数用の経度・緯度を格納する
  var latLng = [];

  GooglePlace googlePlace =
      GooglePlace("AIzaSyD6xjoimFPby09A5aG1f4g-lsAoMG50-04");

  dynamic sakaguraList = [];

  void initState() {
    super.initState();
    setState(() {
      // 不慮の読み込みに対応できるように初回のみJSONからデータの取得を行う
      if (sakaguraList.isEmpty) {
        var list = loadJson.loadJsonAsset();
        list.then((item) => sakaguraList = item);
      }
    });
  }

  Widget _searchTextField() {
    return TextField(
      autofocus: true, //TextFieldが表示されるときにフォーカスする（キーボードを表示する）
      cursorColor: Colors.white,
      style: const TextStyle(
        //テキストのスタイル
        color: Colors.white,
        fontSize: 20,
      ),
      textInputAction: TextInputAction.search, //キーボードのアクションボタンを指定
      decoration: const InputDecoration(
        //TextFiledのスタイル
        enabledBorder: UnderlineInputBorder(
            //デフォルトのTextFieldの枠線
            borderSide: BorderSide(color: Colors.white)),
        focusedBorder: UnderlineInputBorder(
            //TextFieldにフォーカス時の枠線
            borderSide: BorderSide(color: Colors.white)),
        hintText: 'Search', //何も入力してないときに表示されるテキスト
        hintStyle: TextStyle(
          color: Colors.white60,
          fontSize: 20,
        ),
      ),
      onChanged: (value) {
        if (value.isNotEmpty) {
          autoCompleteSearch(value);
        } else {
          if (predictions!.isNotEmpty && mounted) {
            setState(() {
              predictions!.clear();
            });
          }
        }
      },
    );
  }

  // 検索値と候補をリンクするオートコンプリート検索機能
  // 検索方法は完全一致検索のみ(現状)
  void autoCompleteSearch(String value) async {
    var result = sakaguraList[value];
    if (result != null) {
      setState(() {
        predictions!.addAll(result);
      });
    } else {
      setState(() {
        predictions!.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var cameraPosition = null;
    Future<CameraPosition> location = getLocateAPI.getLocation();
    location.then((result) => cameraPosition = result);
    // 初期値がnullの場合は名古屋駅を開始地点とする
    cameraPosition ??=
        getLocateAPI.convert(35.17176088096857, 136.88817886263607, 14.4746);

    late Set<Marker> markers = {};
    markers.add(_createMarker('marker1', cameraPosition.target.latitude,
        cameraPosition.target.longitude));

    return Scaffold(
      appBar: AppBar(
          title: _searchBoolean ? const Text('日本酒マップ') : _searchTextField(),
          actions: !_searchBoolean
              ? [
                  IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchBoolean = true;
                          predictions!.clear();
                        });
                      })
                ]
              : [
                  IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _searchBoolean = false;
                        });
                      })
                ]),
      body: Stack(
        // サジェストはグーグルマップ上に表示する
        children: <Widget>[
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: cameraPosition,
            markers: markers,
            // predictions!.isEmpty ?
            //     _createMarker('marker1', cameraPosition.target.latitude, cameraPosition.target.longitude)
            //     : _createMarker(predictions?["酒蔵名"], double.parse(predictions?["経度"]), double.parse(predictions?["緯度"])),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          // 白いサジェスト枠が表示されるため、検索結果が０件(空)の場合はリストを非表示にする
          Visibility(
            visible: predictions!.isNotEmpty,
            //   child:
            //   IgnorePointer(
            child: ListView(
              children: [
                Card(
                  elevation: 8,
                  // child: GestureDetector(
                  child: ListTile(
                    title: Text(predictions?["酒蔵名"] ?? ''),
                    onTap: () async {
                      setState(() {
                        // 引数の関係上、必ず経度から格納すること
                        latLng.add(predictions?["経度"]);
                        latLng.add(predictions?["緯度"]);

                        markers.clear();
                      });
                      await _searchLocation(latLng);
                      setState(() {
                        markers.clear();
                        markers.add(_createMarker(
                            predictions?["酒蔵名"],
                            double.parse(predictions?["経度"]),
                            double.parse(predictions?["緯度"])));
                        // 検索結果を初期化する
                        latLng = [];
                        predictions!.clear();
                      });
                    },
                  ),
                ),
                // ),
              ],
            ),
            // ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        child: const Icon(Icons.location_on),
      ),
    );
  }

  // 現在地ボタンのクリックイベント
  Future _goToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
        CameraUpdate.newCameraPosition(await getLocateAPI.getLocation()));
  }

  // 検索した値のクリックイベント
  Future<void> _searchLocation(List result) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(getLocateAPI
        .convert(double.parse(result[1]), double.parse(result[0]), 17)));
  }

  // マーカークラスの定義
  Marker _createMarker(String name, double lat, double lon) {
    return Marker(
      markerId: MarkerId(name),
      position: LatLng(lat, lon),
      infoWindow: InfoWindow(title: name),
    );
  }
}
