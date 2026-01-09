import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoky_plain/features/ptt/ptt_provider.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ptt = context.watch<PTTProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Walkie-Talkie LAN',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              ptt.role == UserRole.superAdmin
                  ? Icons.admin_panel_settings
                  : Icons.person,
              color: Colors.amber,
            ),
            onPressed: () {
              // Toggle role for demo/sim purposes
              if (ptt.role == UserRole.user) {
                ptt.setRole(UserRole.superAdmin);
              } else {
                ptt.setRole(UserRole.user);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Role Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            color: Colors.amber.withValues(alpha: 0.1),
            child: Text(
              'الدور الحالي: ${ptt.role == UserRole.superAdmin ? "أدمن رئيسي" : "مستخدم"}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(child: _buildStatusSection(ptt)),

          _buildDeviceList(ptt),

          _buildPTTButton(context, ptt),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusSection(PTTProvider ptt) {
    String message = "جاهز";
    IconData icon = Icons.mic_none;
    Color color = Colors.grey;

    if (ptt.state == TalkState.transmitting) {
      message = "جاري الإرسال...";
      icon = Icons.mic;
      color = Colors.red;
    } else if (ptt.state == TalkState.receiving) {
      message = "يتحدث الآن: ${ptt.activeTalkerName}";
      icon = Icons.volume_up;
      color = Colors.green;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(PTTProvider ptt) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الأجهزة المتصلة:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ptt.connectedDevices.isEmpty
                ? const Center(
                    child: Text(
                      'لا يوجد أجهزة مكتشفة',
                      style: TextStyle(color: Colors.white30),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ptt.connectedDevices.length,
                    itemBuilder: (context, index) {
                      final device = ptt.connectedDevices[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_android, color: Colors.blue),
                            Text(
                              device.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              device.ip,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPTTButton(BuildContext context, PTTProvider ptt) {
    bool isTransmitting = ptt.state == TalkState.transmitting;
    bool isReceiving = ptt.state == TalkState.receiving;

    return GestureDetector(
      onLongPressStart: (_) {
        if (!isReceiving) {
          ptt.startTransmitting();
        }
      },
      onLongPressEnd: (_) {
        ptt.stopTransmitting();
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isReceiving
              ? Colors.grey[800]
              : (isTransmitting ? Colors.red : Colors.amber),
          boxShadow: [
            BoxShadow(
              color: (isTransmitting ? Colors.red : Colors.amber).withValues(
                alpha: 0.4,
              ),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.push_pin, size: 40, color: Colors.black),
              SizedBox(height: 8),
              Text(
                'اضغط للتحدث',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
