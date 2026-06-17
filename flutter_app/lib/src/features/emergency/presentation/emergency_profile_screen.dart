import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EmergencyProfileScreen extends StatelessWidget {
  const EmergencyProfileScreen({super.key, required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notfallprofil')),
      body: Center(child: QrImageView(data: payload, size: 240)),
    );
  }
}
