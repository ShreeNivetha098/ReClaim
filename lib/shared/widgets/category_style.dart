import 'package:flutter/material.dart';

/// Item categories offered in the report forms, with a friendly icon each.
const itemCategories = [
  'ID Card',
  'Wallet',
  'Keys',
  'Books',
  'Calculator',
  'Electronics',
  'Bag',
  'Bottle',
  'Documents',
  'Accessories',
  'Other',
];

IconData categoryIcon(String category) {
  switch (category.trim().toLowerCase()) {
    case 'id card':
      return Icons.badge_rounded;
    case 'wallet':
      return Icons.account_balance_wallet_rounded;
    case 'keys':
      return Icons.key_rounded;
    case 'books':
      return Icons.menu_book_rounded;
    case 'calculator':
      return Icons.calculate_rounded;
    case 'electronics':
      return Icons.devices_rounded;
    case 'bag':
      return Icons.backpack_rounded;
    case 'bottle':
      return Icons.water_drop_rounded;
    case 'documents':
      return Icons.description_rounded;
    case 'accessories':
      return Icons.watch_rounded;
    default:
      return Icons.category_rounded;
  }
}
