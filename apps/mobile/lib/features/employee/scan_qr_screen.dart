import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/providers/attendance_provider.dart';

class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key});

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> {
  String _type = 'CHECK_IN';
  bool _processing = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _processing = true);
    _controller.stop();

    try {
      final qrData = jsonDecode(barcode!.rawValue!);
      final token = qrData['token'] as String;

      await ref.read(attendanceRepoProvider).markAttendance(
            qrToken: token,
            type: _type,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_type == 'CHECK_IN' ? 'Checked in successfully!' : 'Checked out successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      String errorMsg = 'Failed to mark attendance';
      if (e.toString().contains('ALREADY_CHECKED_IN')) {
        errorMsg = 'Already checked in. Please check out first.';
      } else if (e.toString().contains('NOT_CHECKED_IN')) {
        errorMsg = 'Not checked in yet. Please check in first.';
      } else if (e.toString().contains('QR_INVALID')) {
        errorMsg = 'Invalid or expired QR code.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        setState(() => _processing = false);
        _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Toggle CHECK_IN / CHECK_OUT
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'CHECK_IN'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'CHECK_IN'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Check In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _type == 'CHECK_IN' ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'CHECK_OUT'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'CHECK_OUT'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Check Out',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _type == 'CHECK_OUT' ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Camera
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _processing
                  ? const Center(child: CircularProgressIndicator())
                  : MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Point your camera at the QR code on the counter',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
