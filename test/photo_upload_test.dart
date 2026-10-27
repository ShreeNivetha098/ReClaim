import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reclaim/shared/models/lost_item_model.dart';
import 'package:reclaim/shared/models/found_item_model.dart';
import 'package:reclaim/core/services/image_store_service.dart';
import 'package:reclaim/core/services/reclaim_repository.dart';
import 'package:reclaim/shared/widgets/item_card.dart';

void main() {
  group('Photo Upload and Image URL Model Tests', () {
    test('LostItemModel correctly serializes and deserializes imageUrl', () {
      final now = DateTime.now();
      final modelWithImage = LostItemModel(
        id: 'lost_123',
        ownerId: 'user_456',
        reporterName: 'John Doe',
        reporterEmail: 'john@psgtech.ac.in',
        itemName: 'Calculator',
        category: 'Calculator',
        description: 'Casio fx-991EX',
        brand: 'Casio',
        colour: 'Black',
        dateLost: now,
        locationLost: 'Library',
        approximateValue: '1500',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/reclaim-c4695/o/lost_items%2Ftest.jpg',
        createdAt: now,
        updatedAt: now,
      );

      final map = modelWithImage.toMap();
      expect(map['imageUrl'], 'https://firebasestorage.googleapis.com/v0/b/reclaim-c4695/o/lost_items%2Ftest.jpg');

      final deserialized = LostItemModel.fromMap(map, 'lost_123');
      expect(deserialized.imageUrl, 'https://firebasestorage.googleapis.com/v0/b/reclaim-c4695/o/lost_items%2Ftest.jpg');
      expect(deserialized.reporterName, 'John Doe');
      expect(deserialized.reporterEmail, 'john@psgtech.ac.in');
    });

    test('LostItemModel handles missing/null imageUrl gracefully (old records)', () {
      final now = DateTime.now();
      final mapWithoutImage = {
        'ownerId': 'user_456',
        'reporterName': 'Jane Doe',
        'reporterEmail': 'jane@psgtech.ac.in',
        'itemName': 'Water Bottle',
        'category': 'Bottle',
        'description': 'Steel bottle',
        'brand': 'Milton',
        'colour': 'Silver',
        'dateLost': Timestamp.fromDate(now),
        'locationLost': 'Canteen',
        'approximateValue': '500',
        'imageUrl': null,
        'status': 'ACTIVE',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final deserialized = LostItemModel.fromMap(mapWithoutImage, 'lost_999');
      expect(deserialized.imageUrl, isNull);
      expect(deserialized.itemName, 'Water Bottle');
    });

    test('FoundItemModel correctly serializes and deserializes imageUrl', () {
      final now = DateTime.now();
      final foundWithImage = FoundItemModel(
        id: 'found_123',
        finderId: 'user_789',
        reporterName: 'Officer Bob',
        reporterEmail: 'bob@psgtech.ac.in',
        itemName: 'Keys',
        category: 'Keys',
        description: 'Set of 3 keys with blue keychain',
        brand: 'N/A',
        colour: 'Silver',
        dateFound: now,
        locationFound: 'Gate 2',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/reclaim-c4695/o/found_items%2Ftest.jpg',
        createdAt: now,
        updatedAt: now,
      );

      final map = foundWithImage.toMap();
      expect(map['imageUrl'], 'https://firebasestorage.googleapis.com/v0/b/reclaim-c4695/o/found_items%2Ftest.jpg');

      final deserialized = FoundItemModel.fromMap(map, 'found_123');
      expect(deserialized.imageUrl, 'https://firebasestorage.googleapis.com/v0/b/reclaim-c4695/o/found_items%2Ftest.jpg');
      expect(deserialized.reporterName, 'Officer Bob');
    });

    test('FoundItemModel handles legacy records with null/empty imageUrl', () {
      final now = DateTime.now();
      final mapLegacy = {
        'finderId': 'user_789',
        'itemName': 'ID Card',
        'category': 'ID Card',
        'description': 'Found ID Card',
        'brand': '',
        'colour': 'White',
        'dateFound': Timestamp.fromDate(now),
        'locationFound': 'Library',
        'imageUrl': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final deserialized = FoundItemModel.fromMap(mapLegacy, 'found_legacy');
      expect(deserialized.imageUrl, '');
      expect(deserialized.itemName, 'ID Card');
    });

    test('ReClaimRepository.uploadImageBytes returns valid string', () async {
      final repo = ReClaimRepository();
      final dummyBytes = Uint8List.fromList([0, 1, 2, 3, 4]);

      final url = await repo.uploadImageBytes(dummyBytes);
      expect(url, isNotNull);
      expect(url!.isNotEmpty, isTrue);
    });
  });

  group('ImageStoreService (Firestore photo storage)', () {
    test('recognises Firestore photo references and ignores web URLs', () {
      expect(ImageStoreService.isStoredRef('firestore:itemImages/abc-123'), isTrue);
      expect(ImageStoreService.isStoredRef('https://example.com/photo.jpg'), isFalse);
      expect(ImageStoreService.isStoredRef(''), isFalse);
      expect(ImageStoreService.isStoredRef(null), isFalse);
    });

    test('rejects photos larger than the Firestore size limit before uploading', () {
      final tooBig = Uint8List(ImageStoreService.maxBytes + 1);
      expect(
        () => ImageStoreService.save(tooBig, uploaderId: 'user_1'),
        throwsArgumentError,
      );
    });
  });

  group('ItemCard Widget Image Rendering Tests', () {
    testWidgets('ItemCard renders placeholder icon when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemCard(
              title: 'Lost Keys',
              category: 'Keys',
              location: 'Block A',
              date: DateTime.now(),
              imageUrl: null,
              status: 'ACTIVE',
              isLost: true,
              reporterName: 'Alice',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Lost Keys'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('ItemCard renders placeholder icon when imageUrl is empty string', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemCard(
              title: 'Found Watch',
              category: 'Accessories',
              location: 'Sports Complex',
              date: DateTime.now(),
              imageUrl: '',
              status: 'ACTIVE',
              isLost: false,
              reporterName: 'Bob',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Found Watch'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });
}
