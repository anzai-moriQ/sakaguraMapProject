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
      home: MyMap(),
      supportedLocales: [Locale('ja', 'JP')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate
      ],
    );
  }
}

class MyMap extends StatefulWidget {
  @override
  State createState() => _MyMap();
}

class _MyMap extends State {
  Completer _controller = Completer();
  GetLocateAPI getLocateAPI = GetLocateAPI();

  bool _searchBoolean = true;
  Map<String, dynamic>? predictions = <String, dynamic>{};
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
      cursorColor: Colors.white, //カーソルの色
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
          //hintTextのスタイル
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
  void autoCompleteSearch(String value) async {
    var result = sakaguraList[value];
    if (result != null) {
      setState(() {
        // predictions.add(result["酒蔵名"]);
        // predictions.add(result["経度"]);
        // predictions.add(result["緯度"]);
        // predictions.add(result["住所"]);
        predictions!.addAll(result);
        // loadJson.fromJson(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var cameraPosition = null;
    Future<CameraPosition> location = getLocateAPI.getLocation();
    location.then((result) => cameraPosition = result);
    if (cameraPosition == null) {
      cameraPosition =
          getLocateAPI.convert(35.17176088096857, 136.88817886263607, 14.4746);
    }
    return Scaffold(
      appBar: AppBar(
          title: _searchBoolean ? Text('日本酒マップ') : _searchTextField(),
          actions: !_searchBoolean
              ? [
                  IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchBoolean = true;
                          predictions!.clear();
                        });
                      })
                ]
              : [
                  IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _searchBoolean = false;
                        });
                      })
                ]),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: cameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Visibility(
            visible: predictions!.isNotEmpty,
            child: IgnorePointer(
              child: ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 8,
                    child: ListTile(
                      title: Text(predictions?["酒蔵名"] ?? ''),
                      onTap: () async {
                        setState(() {
                          // 取得した経度と緯度を配列に格納
                          latLng.add(predictions?['経度'] ?? '');
                          latLng.add(predictions?['緯度'] ?? '');
                        });
                        await _searchLocation(latLng);
                        setState(() {
                          latLng = [];
                          predictions!.clear();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        child: Icon(Icons.location_on),
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
    controller.animateCamera(CameraUpdate.newCameraPosition(
        getLocateAPI.convert(result[0], result[1], 15)));
  }
}
