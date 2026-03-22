import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/qr_provider.dart';
import '../../shared/utils/date_helpers.dart';

class QrDisplayScreen extends ConsumerStatefulWidget {
  const QrDisplayScreen({super.key});

  @override
  ConsumerState<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends ConsumerState<QrDisplayScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(todayQrProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrAsync = ref.watch(todayQrProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('QR Code'),
        centerTitle: true,
      ),
      body: Center(
        child: qrAsync.when(
          data: (qr) {
            // Decode base64 image
            Widget qrImage;
            if (qr.qrImage != null) {
              try {
                String b64 = qr.qrImage!;
                // Strip data URL prefix if present
                if (b64.contains(',')) {
                  b64 = b64.split(',').last;
                }
                final bytes = base64Decode(b64);
                qrImage = Image.memory(bytes, width: 280, height: 280, fit: BoxFit.contain);
              } catch (_) {
                qrImage = const Icon(Icons.error, size: 100, color: Colors.red);
              }
            } else {
              qrImage = const Icon(Icons.qr_code, size: 200, color: Colors.grey);
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ideal Home Store',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  DateHelpers.formatDate(DateTime.now()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: qrImage,
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan to mark attendance',
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Auto-refreshes every 30s',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Failed to load QR code'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(todayQrProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
