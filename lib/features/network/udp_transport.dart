import 'dart:io';
import 'dart:typed_data';
import 'package:hoky_plain/core/constants.dart';

class UdpTransport {
  RawDatagramSocket? _controlSocket;
  RawDatagramSocket? _audioSocket;

  Future<void> init() async {
    _controlSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      AppConstants.controlPort,
    );
    _controlSocket!.broadcastEnabled = true;

    _audioSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      AppConstants.audioPort,
    );
    _audioSocket!.broadcastEnabled = true;
  }

  void sendControlMessage(List<int> data) {
    _controlSocket?.send(
      data,
      InternetAddress(AppConstants.broadcastAddress),
      AppConstants.controlPort,
    );
  }

  void sendAudioData(Uint8List data) {
    _audioSocket?.send(
      data,
      InternetAddress(AppConstants.broadcastAddress),
      AppConstants.audioPort,
    );
  }

  Datagram? receiveAudio() {
    return _audioSocket?.receive();
  }

  Datagram? receiveControl() {
    return _controlSocket?.receive();
  }

  Stream<RawSocketEvent> get controlStream =>
      _controlSocket!.asBroadcastStream();
  Stream<RawSocketEvent> get audioStream => _audioSocket!.asBroadcastStream();

  void close() {
    _controlSocket?.close();
    _audioSocket?.close();
  }
}
