import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobile_app/components/snackbar.dart';
import 'package:flutter_mobile_app/socket.dart';
import 'package:battery_plus/battery_plus.dart';

import 'package:flutter_mobile_app/network.dart' as Network;

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
    WidgetsFlutterBinding.ensureInitialized();
    _controller = TextEditingController();

    socketManager = SocketManager();
    autoConnect();

    _battery.batteryState.then(_updateBatteryState);
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen(_updateBatteryState);
  }

  void autoConnect() async {
    print("Checking wifi status");
    if (await Network.isDevicePresent()) {
      print("Wifi is turned on");

      await Future.delayed(const Duration(seconds: 3));

      if (Network.isServerFound()) {
        String serverAddress = Network.getServerAdress();
        _controller.text = serverAddress;
        showSnackBar(context, "Detected server at $serverAddress");
      }
    } else {
      print("Wifi is not turned on");
    }
  }

  Future<void> checkPercent() async {
    _batteryPercent = await _battery.batteryLevel;
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_batteryState == BatteryState.charging) {
        var level = await _battery.batteryLevel;
        if (level != _batteryPercent) {
          setState(() {
            _batteryPercent = level;
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

  void disconnect() {
    if (socketManager.isConnected()) {
      socketManager.disconnect();
    }
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
          SizedBox(
            width: 300,
            child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                    focusColor: Colors.blue,
                    hintText: "Enter address",
                    border: OutlineInputBorder())),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => connected ? disconnect() : connect(),
            child: Container(
              width: 200,
              height: 60,
              decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
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
