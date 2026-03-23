import 'package:flutter/material.dart';
import '../../core/services/update_service.dart';

/// Shows an update dialog when a new version is available.
/// Handles download progress and triggers APK install.
class UpdateDialog extends StatefulWidget {
  final AppVersionInfo versionInfo;

  const UpdateDialog({super.key, required this.versionInfo});

  /// Show the update dialog as a bottom sheet
  static void show(BuildContext context, AppVersionInfo versionInfo) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UpdateDialog(versionInfo: versionInfo),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

enum _UpdateState { idle, downloading, downloaded, error }

class _UpdateDialogState extends State<UpdateDialog> {
  _UpdateState _state = _UpdateState.idle;
  double _progress = 0;
  String _errorMessage = '';

  void _startDownload() {
    setState(() {
      _state = _UpdateState.downloading;
      _progress = 0;
    });

    downloadAndInstallUpdate(
      widget.versionInfo,
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _state = _UpdateState.error;
            _errorMessage = error;
          });
        }
      },
      onDownloadComplete: () {
        if (mounted) setState(() => _state = _UpdateState.downloaded);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Icon(Icons.system_update, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Update Available',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Version info
          Text(
            'Version ${widget.versionInfo.version} is available',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),

          // Release notes
          if (widget.versionInfo.releaseNotes.isNotEmpty) ...[
            Text(
              "What's new:",
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.versionInfo.releaseNotes,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],

          // Progress bar (during download)
          if (_state == _UpdateState.downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading... ${(_progress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // Error message
          if (_state == _UpdateState.error) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Downloaded success
          if (_state == _UpdateState.downloaded) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download complete! Installing...',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Buttons
          Row(
            children: [
              if (_state != _UpdateState.downloading)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Later'),
                  ),
                ),
              if (_state != _UpdateState.downloading) const SizedBox(width: 12),
              Expanded(
                flex: _state == _UpdateState.downloading ? 1 : 1,
                child: FilledButton(
                  onPressed: _state == _UpdateState.downloading ? null : _startDownload,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _state == _UpdateState.error
                        ? 'Retry'
                        : _state == _UpdateState.downloading
                            ? 'Downloading...'
                            : 'Update Now',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
