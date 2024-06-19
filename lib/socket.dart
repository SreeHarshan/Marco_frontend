import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketManager {
  late IO.Socket socket;
  String url = "";

  void init() {
    socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .setExtraHeaders({'foo': 'bar'}) // optional
            .build());
  }

  bool connect(String url) {
    this.url = "http://$url";
    init();
    try {
      socket.connect();
      return socket.connected;
    } catch (e) {
      return false;
    }
  }

  void disconnect() {
    socket.disconnect();
  }

  bool isConnected() => url != "" && socket.connected;

  void sendMsg(String eventName, var msg) {
    socket.emit(eventName, msg);
  }

  void addEvent(String eventName, dynamic Function(dynamic) f) {
    socket.on(eventName, f);
  }
}
