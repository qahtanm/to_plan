// Core constants for the Walkie-Talkie app

class AppConstants {
  // UDP ports
  static const int controlPort = 4000;
  static const int audioPort = 4001;

  // Broadcast address (last octet .255 for typical LAN)
  static const String broadcastAddress = '255.255.255.255';

  // Audio settings
  static const int sampleRate = 16000; // 16 kHz
  static const int channelCount = 1; // mono
  static const int bitsPerSample = 16;
}
