import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../item_details/presentation/item_details_screen.dart';

/// Notification types that point at a found item and raise an iOS banner.
const foundItemNotificationTypes = {'POTENTIAL_MATCH', 'CLAIM_APPROVED', 'CLAIM_REJECTED'};

/// Banner payload for these notifications: `notificationId|foundItemId`.
String foundItemPayload(String notificationId, String foundItemId) => '$notificationId|$foundItemId';

/// Opens the found item from a banner's [payload].
Future<void> openFoundItemPayload(BuildContext context, WidgetRef ref, String payload) async {
  final parts = payload.split('|');
  if (parts.length != 2) return;
  await openMatchedFoundItem(context, ref, notificationId: parts[0], foundItemId: parts[1]);
}

/// Marks a notification read and opens the found item it points to.
Future<void> openMatchedFoundItem(
  BuildContext context,
  WidgetRef ref, {
  required String notificationId,
  required String foundItemId,
}) async {
  final repo = ref.read(repositoryProvider);
  repo.markNotificationAsRead(notificationId);
  final item = await repo.getFoundItemById(foundItemId);
  if (!context.mounted) return;
  if (item == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This found item is no longer available.')),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ItemDetailsScreen(foundItem: item)),
  );
}
