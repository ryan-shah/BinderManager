import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Picks a ManaBox CSV via the platform file dialog and hands its bytes to
/// [onFilePicked]. Shows the loaded file name once one is chosen.
class ImportFileButton extends StatelessWidget {
  const ImportFileButton({
    super.key,
    required this.onFilePicked,
    this.fileName,
    this.enabled = true,
  });

  /// Called with the picked file's name and raw bytes.
  final Future<void> Function(String fileName, Uint8List bytes) onFilePicked;

  /// Name of the currently loaded file, if any.
  final String? fileName;

  final bool enabled;

  Future<void> _pick() async {
    const typeGroup = XTypeGroup(
      label: 'CSV',
      extensions: ['csv'],
      mimeTypes: ['text/csv'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await onFilePicked(file.name, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? _pick : null,
      icon: const Icon(Icons.upload_file, size: 16),
      label: Text(
        fileName ?? 'Choose ManaBox CSV…',
        overflow: TextOverflow.ellipsis,
        style: fileName == null
            ? null
            : AppTypography.meta.copyWith(color: AppColors.neutral700),
      ),
    );
  }
}
