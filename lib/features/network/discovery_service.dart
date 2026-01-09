// Device discovery service using UDP broadcast
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hoky_plain/core/constants.dart';
import 'package:uuid/uuid.dart';

class DeviceInfo {
  final String id;
  final String name;
  final String ip;
  DeviceInfo({required this.id, required this.name, required this.ip});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'ip': ip};
  static DeviceInfo fromJson(Map<String, dynamic> json) =>
      DeviceInfo(id: json['id'], name: json['name'], ip: json['ip']);
}

class DiscoveryService {
  final String _deviceName;
  final String _deviceId = const Uuid().v4();
  final List<DeviceInfo> _peers = [];
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;

  DiscoveryService(this._deviceName);

  Future<void> start() async {
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      AppConstants.controlPort,
    );
    _socket!.broadcastEnabled = true;
    _socket!.listen(_handleIncoming);
    // Broadcast presence every 2 seconds
    _broadcastTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _broadcastPresence(),
    );
  }

  void _broadcastPresence() {
    final payload = jsonEncode({
      'type': 'presence',
      'id': _deviceId,
      'name': _deviceName,
      'ip': _socket?.address.address ?? '',
    });
    _socket?.send(
      utf8.encode(payload),
      InternetAddress(AppConstants.broadcastAddress),
      AppConstants.controlPort,
    );
  }

  void _handleIncoming(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket?.receive();
      if (datagram == null) return;
      final message = utf8.decode(datagram.data);
      final Map<String, dynamic> data = jsonDecode(message);
      if (data['type'] == 'presence' && data['id'] != _deviceId) {
        final info = DeviceInfo.fromJson(data);
        if (_peers.every((d) => d.id != info.id)) {
          _peers.add(info);
        }
      }
    }
  }

  List<DeviceInfo> get peers => List.unmodifiable(_peers);

  void stop() {
    _broadcastTimer?.cancel();
    _socket?.close();
  }
}
