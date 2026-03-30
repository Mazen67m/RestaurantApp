import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

enum ConnectivityStatus { wifi, mobile, none }

class ConnectivityProvider with ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.wifi;
  ConnectivityStatus get status => _status;

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _subscription;

  ConnectivityProvider() {
    _init();
  }

  void _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateStatus(result);
    });
  }

  void _updateStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        _status = ConnectivityStatus.wifi;
        break;
      case ConnectivityResult.mobile:
        _status = ConnectivityStatus.mobile;
        break;
      case ConnectivityResult.none:
        _status = ConnectivityStatus.none;
        break;
      default:
        _status = ConnectivityStatus.none;
    }
    notifyListeners();
  }

  bool get isConnected => _status != ConnectivityStatus.none;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
