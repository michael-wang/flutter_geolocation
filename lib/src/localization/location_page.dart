import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_geolocation/main.dart';
import 'package:flutter_geolocation/src/settings/settings_view.dart';
import 'package:geolocator/geolocator.dart';

class LocationPage extends StatefulWidget {
  static const routeName = '/';

  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

enum _State {
  unknown,
  locationDisabled,
  permissionDenied,
  gettingPosition,
  failedUnknownWhy,
  positionUpdated,
}

extension _StatePrinter on _State {
  String readableString() {
    switch (this) {
      case _State.unknown:
        return '請稍候，正在與定位服務溝通中';
      case _State.locationDisabled:
        return '這台機器的定位服務未開啟，請打開定位服務';
      case _State.permissionDenied:
        return '使用者不同意使用定位服務，因此無法取得位置資訊';
      case _State.gettingPosition:
        return '正在更新位置資訊...';
      case _State.failedUnknownWhy:
        return '無法取得位置資訊（原因未知）';
      case _State.positionUpdated:
        return '';
    }
  }
}

class _LocationPageState extends State<LocationPage> {
  var _state = _State.unknown;
  Position? _position;
  late Timer _updator;

  @override
  void initState() {
    super.initState();

    _updator = Timer.periodic(
      const Duration(seconds: 5),
      _updatePosition,
    );
  }

  @override
  void deactivate() {
    if (_updator.isActive) {
      _updator.cancel();
    }

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  size: 48,
                  color: Colors.redAccent,
                ),
                title: Text(
                    key: ValueKey(_position),
                    _position != null
                        ? '經度：${_position?.latitude}，緯度：${_position?.longitude}'
                        : '未知的位置'),
                subtitle: Text(key: ValueKey(_state), _state.readableString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ref: https://github.com/baseflow/flutter-geolocator/tree/main/geolocator
  _updatePosition(Timer updator) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _state = _State.locationDisabled;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (updator.isActive) {
              updator.cancel();
            }
            setState(() {
              _state = _State.permissionDenied;
            });
            return;
          }
        }
        break;
      case LocationPermission.deniedForever:
        if (updator.isActive) {
          updator.cancel();
        }
        setState(() {
          _state = _State.permissionDenied;
        });
        return;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        setState(() {
          _state = _State.gettingPosition;
        });
        break;
      case LocationPermission.unableToDetermine:
        setState(() {
          _state = _State.failedUnknownWhy;
        });
        // Proceed to get location.
        break;
    }

    final newPosition = await Geolocator.getCurrentPosition();
    log.d('newPosision: $newPosition');
    setState(() {
      _state = _State.positionUpdated;
      _position = newPosition;
    });
  }
}
