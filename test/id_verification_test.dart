import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:reclaim/core/constants/app_constants.dart';
import 'package:reclaim/core/services/id_photo_service.dart';
import 'package:reclaim/core/services/reclaim_repository.dart';
import 'package:reclaim/shared/models/user_model.dart';

final idPhoto = Uint8List.fromList(List.filled(2048, 7));

Future<(ReClaimRepository, UserModel)> signedUpStudent() async {
  final repo = ReClaimRepository();
  final user = await repo.registerUser(
    name: 'Priya',
    email: 'priya@psgtech.ac.in',
    password: 'secret1',
    phone: '9000000000',
    department: 'Computer Science & Applications',
    rollNumber: '25MX101',
    role: 'Student',
  );
  return (repo, user);
}

Future<UserModel> reloadUser(ReClaimRepository repo, String uid) async {
  return (await repo.getAllUsers()).firstWhere((u) => u.uid == uid);
}

void main() {
  test('new accounts start unverified', () async {
    final (_, user) = await signedUpStudent();
    expect(user.verificationStatus, AppConstants.verificationNone);
    expect(user.isVerified, isFalse);
  });

  test('submitting an ID photo makes the account pending and stores the photo', () async {
    final (repo, user) = await signedUpStudent();
    final updated = await repo.submitIdPhoto(idPhoto);

    expect(updated.verificationStatus, AppConstants.verificationPending);
    expect(repo.currentUser!.verificationStatus, AppConstants.verificationPending);
    expect(IdPhotoService.hasMockPhoto(user.uid), isTrue);
  });

  test('withdrawing deletes the photo and resets the status', () async {
    final (repo, user) = await signedUpStudent();
    await repo.submitIdPhoto(idPhoto);
    final updated = await repo.withdrawIdPhoto();

    expect(updated.verificationStatus, AppConstants.verificationNone);
    expect(IdPhotoService.hasMockPhoto(user.uid), isFalse);
  });

  test('photos larger than the limit are refused', () async {
    final (repo, _) = await signedUpStudent();
    final tooBig = Uint8List(1024 * 1024);
    await expectLater(repo.submitIdPhoto(tooBig), throwsArgumentError);
    expect(repo.currentUser!.verificationStatus, AppConstants.verificationNone);
  });

  test('verifying records the admin and deletes the photo', () async {
    final (repo, user) = await signedUpStudent();
    final pending = await repo.submitIdPhoto(idPhoto);

    await repo.reviewIdVerification(user: pending, approve: true, adminName: 'Dr. Admin');

    final verified = await reloadUser(repo, user.uid);
    expect(verified.verificationStatus, AppConstants.verificationVerified);
    expect(verified.isVerified, isTrue);
    expect(verified.verifiedBy, 'Dr. Admin');
    expect(verified.verifiedAt, isNotNull);
    expect(IdPhotoService.hasMockPhoto(user.uid), isFalse);

    final notes = await repo.getNotifications(user.uid);
    expect(notes.where((n) => n.type == 'VERIFICATION_APPROVED'), hasLength(1));
  });

  test('rejecting keeps the reason, deletes the photo, and allows a new upload', () async {
    final (repo, user) = await signedUpStudent();
    final pending = await repo.submitIdPhoto(idPhoto);

    await repo.reviewIdVerification(
      user: pending,
      approve: false,
      adminName: 'Dr. Admin',
      note: 'Name does not match the ID card.',
    );

    final rejected = await reloadUser(repo, user.uid);
    expect(rejected.verificationStatus, AppConstants.verificationRejected);
    expect(rejected.verificationNote, 'Name does not match the ID card.');
    expect(rejected.verifiedBy, isNull);
    expect(IdPhotoService.hasMockPhoto(user.uid), isFalse);

    final notes = await repo.getNotifications(user.uid);
    expect(notes.where((n) => n.type == 'VERIFICATION_REJECTED'), hasLength(1));

    repo.currentUser = rejected;
    final again = await repo.submitIdPhoto(idPhoto);
    expect(again.verificationStatus, AppConstants.verificationPending);
    expect(again.verificationNote, isNull);
  });

  test('verification fields survive saving and loading a profile', () {
    final now = DateTime(2026, 10, 28, 10, 30);
    final user = UserModel(
      uid: 'u1',
      name: 'Priya',
      email: 'priya@psgtech.ac.in',
      phone: '9',
      department: 'CSA',
      rollNumber: '25MX101',
      role: 'Student',
      createdAt: now,
      updatedAt: now,
    ).withVerification(status: 'VERIFIED', verifiedBy: 'Dr. Admin', verifiedAt: now);

    final loaded = UserModel.fromMap(user.toMap(), 'u1');
    expect(loaded.verificationStatus, 'VERIFIED');
    expect(loaded.verifiedBy, 'Dr. Admin');
    expect(loaded.verifiedAt, now);
  });

  test('profiles saved before this feature load as unverified', () {
    final loaded = UserModel.fromMap({'name': 'Old user', 'role': 'Student'}, 'old');
    expect(loaded.verificationStatus, AppConstants.verificationNone);
    expect(loaded.isVerified, isFalse);
  });
}
