import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../state/chat_provider.dart';
import '../theme/tgo_theme.dart';

/// File picker helper for selecting and uploading files
class FilePickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Show file picker bottom sheet
  static Future<void> showPicker(
    BuildContext context,
    ChatProvider provider,
  ) async {
    final theme = TgoThemeProvider.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FilePickerSheet(
        provider: provider,
        theme: theme,
      ),
    );
  }

  /// Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('[FilePickerHelper] Camera error: $e');
    }
    return null;
  }

  /// Pick image from gallery
  static Future<List<File>> pickImagesFromGallery({int limit = 9}) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        limit: limit,
      );
      return images.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      debugPrint('[FilePickerHelper] Gallery error: $e');
    }
    return [];
  }

  /// Pick files
  static Future<List<File>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'md',
          'zip',
          'rar',
          '7z',
        ],
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
    } catch (e) {
      debugPrint('[FilePickerHelper] File picker error: $e');
    }
    return [];
  }
}

class _FilePickerSheet extends StatelessWidget {
  final ChatProvider provider;
  final TgoTheme theme;

  const _FilePickerSheet({
    required this.provider,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PickerOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  theme: theme,
                  onTap: () async {
                    Navigator.pop(context);
                    final files =
                        await FilePickerHelper.pickImagesFromGallery();
                    if (files.isNotEmpty) {
                      if (_checkFileSize(context, files)) {
                        provider.uploadFiles(files);
                      }
                    }
                  },
                ),
                _PickerOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  theme: theme,
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await FilePickerHelper.pickImageFromCamera();
                    if (file != null) {
                      if (_checkFileSize(context, [file])) {
                        provider.uploadFiles([file]);
                      }
                    }
                  },
                ),
                _PickerOption(
                  icon: Icons.insert_drive_file,
                  label: 'Files',
                  theme: theme,
                  onTap: () async {
                    Navigator.pop(context);
                    final files = await FilePickerHelper.pickFiles();
                    if (files.isNotEmpty) {
                      if (_checkFileSize(context, files)) {
                        provider.uploadFiles(files);
                      }
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _checkFileSize(BuildContext context, List<File> files) {
    const maxFileSize = 25 * 1024 * 1024; // 25MB
    for (final file in files) {
      if (file.lengthSync() > maxFileSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'File "${file.path.split('/').last}" is too large (max 25MB)'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final TgoTheme theme;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

