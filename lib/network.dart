import 'package:network_discovery/network_discovery.dart';

const List<int> ports = [5000, 5001, 8000, 8001];

bool _serverFound = false;
String _serverAddress = "";

Future<bool> isDevicePresent() async {
  final String deviceIP = await NetworkDiscovery.discoverDeviceIpAddress();

  if (deviceIP.isNotEmpty) {
    print("Device IP:$deviceIP");
    String subnet = deviceIP.substring(0, deviceIP.lastIndexOf('.'));
    if (deviceIP.substring(0, deviceIP.indexOf('.')) == '100') {
      print("Hotspot turned on,changing subnet to 192.168.41");
      subnet = "192.168.41";
    } else {
      subnet = deviceIP.substring(0, deviceIP.lastIndexOf('.'));
    }

    final stream = NetworkDiscovery.discoverMultiplePorts(subnet, ports);

    stream.listen((NetworkAddress addr) {
      _serverFound = true;
      _serverAddress = "${addr.ip}:${addr.openPorts[0]}";
      print('Found server: $_serverAddress');
    });

    return true;
  }
  return false;
}

bool isServerFound() => _serverFound;

String getServerAdress() => _serverAddress;
