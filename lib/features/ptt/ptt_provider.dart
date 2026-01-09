import 'package:flutter/foundation.dart';
import 'package:hoky_plain/features/network/discovery_service.dart';

enum TalkState { idle, transmitting, receiving }

enum UserRole { user, admin, superAdmin }

class PTTProvider with ChangeNotifier {
  TalkState _state = TalkState.idle;
  UserRole _role = UserRole.user;
  String? _activeTalkerId;
  String? _activeTalkerName;

  // List of connected devices from DiscoveryService
  List<DeviceInfo> _connectedDevices = [];

  TalkState get state => _state;
  UserRole get role => _role;
  String? get activeTalkerId => _activeTalkerId;
  String? get activeTalkerName => _activeTalkerName;
  List<DeviceInfo> get connectedDevices => _connectedDevices;

  void updateDevices(List<DeviceInfo> devices) {
    _connectedDevices = devices;
    notifyListeners();
  }

  void setRole(UserRole newRole) {
    _role = newRole;
    notifyListeners();
  }

  void startTransmitting() {
    if (_state != TalkState.idle) return;
    _state = TalkState.transmitting;
    notifyListeners();
  }

  void stopTransmitting() {
    if (_state != TalkState.transmitting) return;
    _state = TalkState.idle;
    notifyListeners();
  }

  void startReceiving(String id, String name) {
    _state = TalkState.receiving;
    _activeTalkerId = id;
    _activeTalkerName = name;
    notifyListeners();
  }

  void stopReceiving() {
    _state = TalkState.idle;
    _activeTalkerId = null;
    _activeTalkerName = null;
    notifyListeners();
  }

  // Super Admin Controls
  void muteUser(String deviceId) {
    if (_role != UserRole.superAdmin) return;
    // Logic to send 'mute' control packet via UDP
  }

  void blockUser(String deviceId) {
    if (_role != UserRole.superAdmin) return;
    // Logic to send 'block' control packet via UDP
  }
}
