import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:hoky_plain/features/audio/audio_manager.dart';
import 'package:hoky_plain/features/network/udp_transport.dart';
import 'package:hoky_plain/features/network/discovery_service.dart';
import 'package:hoky_plain/features/ptt/ptt_provider.dart';
import 'package:hoky_plain/features/ptt/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep device awake (not supported on web usually, but handled by package)
  if (!kIsWeb) {
    await WakelockPlus.enable();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PTTProvider()),
        Provider(create: (_) => AudioManager()),
        Provider(create: (_) => UdpTransport()),
      ],
      child: const WalkieTalkieApp(),
    ),
  );
}

class WalkieTalkieApp extends StatefulWidget {
  const WalkieTalkieApp({super.key});

  @override
  State<WalkieTalkieApp> createState() => _WalkieTalkieAppState();
}

class _WalkieTalkieAppState extends State<WalkieTalkieApp> {
  bool _initialized = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (kIsWeb) {
      setState(
        () => _error =
            'هذا التطبيق مخصص للعمل على أندرويد فقط (بسبب قيود المتصفح على UDP)',
      );
      return;
    }

    try {
      // 1. Request Permissions
      // On Android 13+, Permission.storage might not be needed for basic mic,
      // but let's keep it scoped to mobile.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();

      if (statuses[Permission.microphone] != PermissionStatus.granted) {
        setState(() => _error = 'صلاحية المايكروفون مطلوبة');
        return;
      }

      if (!mounted) return;

      // 2. Initialize Services
      final audio = context.read<AudioManager>();
      final transport = context.read<UdpTransport>();
      final ptt = context.read<PTTProvider>();

      await audio.init();
      await transport.init();

      // 3. Start Discovery
      final discovery = DiscoveryService('جهاز ${DateTime.now().millisecond}');
      await discovery.start();

      // Periodically update devices list
      Stream.periodic(const Duration(seconds: 3)).listen((_) {
        if (mounted) ptt.updateDevices(discovery.peers);
      });

      // 4. Connect Audio to Network
      audio.onAudioData = (data) {
        if (ptt.state == TalkState.transmitting) {
          transport.sendAudioData(data);
        }
      };

      transport.audioStream.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = transport.receiveAudio();
          if (datagram != null && ptt.state == TalkState.receiving) {
            audio.playAudioData(datagram.data);
          }
        }
      });

      // 5. Watch PTT State Changes
      ptt.addListener(() {
        if (ptt.state == TalkState.transmitting) {
          audio.startRecording();
        } else {
          audio.stopRecording();
        }

        if (ptt.state == TalkState.receiving) {
          audio.startPlayback();
        } else if (ptt.state == TalkState.idle) {
          audio.stopPlayback();
        }
      });

      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _error = 'خطأ في التهيئة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hoky Talkie',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        useMaterial3: true,
      ),
      home: _initialized
          ? const HomeView()
          : Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _error.isNotEmpty
                      ? Text(
                          _error,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
    );
  }
}
