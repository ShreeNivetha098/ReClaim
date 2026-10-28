import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/image_store_service.dart';

/// Lets the user photograph or choose their college ID card.
/// Returns null if they cancel.
Future<Uint8List?> pickIdPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Choose from library'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: ImageStoreService.pickerMaxDimension,
      maxHeight: ImageStoreService.pickerMaxDimension,
      imageQuality: ImageStoreService.pickerQuality,
    );
    return picked?.readAsBytes();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get the photo: $e'), backgroundColor: AppColors.error),
      );
    }
    return null;
  }
}

/// Short explanation shown wherever the user is asked for their ID photo.
const idPhotoPrivacyNote =
    'Upload a photo of your college ID card. An admin checks it once against '
    'your name and roll number, then the photo is deleted. Only you and admins can see it.';
