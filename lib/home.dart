import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobile_app/socket.dart';
import 'package:battery_plus/battery_plus.dart';

class Home extends StatefulWidget {
  @override
  _home createState() => _home();
}

class _home extends State<Home> {
  final Battery _battery = Battery();
  late TextEditingController _controller;

  late SocketManager socketManager;

  String status = "not connected";
  bool connected = false;

  BatteryState? _batteryState;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  int _batteryPercent = 0;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    socketManager = SocketManager();

    _battery.batteryState.then(_updateBatteryState);
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen(_updateBatteryState);
  }

  Future<void> checkPercent() async {
    _batteryPercent = await _battery.batteryLevel;
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_batteryState == BatteryState.charging) {
        var _level = await _battery.batteryLevel;
        if (_level != _batteryPercent) {
          setState(() {
            _batteryPercent = _level;
          });
          sendData();
        }
      }
    });
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state) return;
    setState(() {
      _batteryState = state;
    });
    checkPercent();
    sendData();
  }

  void sendData() {
    if (socketManager.isConnected()) {
      setState(() {
        status == "Sending battery status";
        connected = true;
      });
      socketManager.sendMsg("battery",
          {"status": _batteryState.toString(), "percent": _batteryPercent});
    } else {
      setState(() {
        connected = false;
      });
    }
  }

  void connect() {
    if (socketManager.connect(_controller.text)) {
      setState(() {
        status = "connected";
        connected = true;
      });
    }
    sendData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marco"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: <Widget>[
          const Spacer(flex: 1),
          Center(
            child: Text("Server status: $status"),
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  hintText: "Enter address", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => connect(),
            child: Container(
              width: 200,
              height: 60,
              color: Colors.blue,
              child: Center(
                child: Text(
                  (connected) ? "Disconnect" : "Connect",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
