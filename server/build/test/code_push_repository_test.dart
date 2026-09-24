import 'dart:io';

import 'package:inhouse_codepush_server/src/models/api_models.dart';
import 'package:inhouse_codepush_server/src/models/records.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';
import 'package:inhouse_codepush_server/src/storage/patch_storage.dart';
import 'package:test/test.dart';

class _FakeStorage implements PatchStorage {
  @override
  Future<File?> fileFor(String key) async => null;
  @override
  Future<void> put(String key, List<int> bytes) async {}
  @override
  String urlFor(String key) => 'https://cdn.test/$key';
}

PatchCheckRequest _req({
  int? current,
  String arch = 'arm64',
  String client = 'c1',
}) =>
    PatchCheckRequest(
      appId: 'app',
      channel: 'stable',
      releaseVersion: '1.0.0+1',
      platform: 'android',
      arch: arch,
      clientId: client,
      currentPatchNumber: current,
    );

PatchRecord _patch(
  int number, {
  bool rolledBack = false,
  int rollout = 100,
  String arch = 'arm64',
}) =>
    PatchRecord(
      appId: 'app',
      releaseVersion: '1.0.0+1',
      platform: 'android',
      arch: arch,
      channel: 'stable',
      number: number,
      hash: 'hash$number',
      storageKey: 'key$number',
      rolledBack: rolledBack,
      rolloutPercentage: rollout,
    );

void main() {
  late InMemoryCodePushRepository repo;
  setUp(() => repo = InMemoryCodePushRepository(storage: _FakeStorage()));

  test('no patch when none registered', () async {
    final res = await repo.checkForPatch(_req());
    expect(res.patchAvailable, isFalse);
    expect(res.patch, isNull);
  });

  test('serves highest active patch newer than current', () async {
    await repo.registerPatch(_patch(1));
    await repo.registerPatch(_patch(2));
    final res = await repo.checkForPatch(_req(current: 1));
    expect(res.patchAvailable, isTrue);
    expect(res.patch!.number, 2);
    expect(res.patch!.downloadUrl, 'https://cdn.test/key2');
  });

  test('no patch when client already on latest', () async {
    await repo.registerPatch(_patch(2));
    final res = await repo.checkForPatch(_req(current: 2));
    expect(res.patchAvailable, isFalse);
  });

  test('rolled-back patch is excluded and advertised', () async {
    await repo.registerPatch(_patch(1));
    await repo.registerPatch(_patch(2, rolledBack: true));
    final res = await repo.checkForPatch(_req(current: 0));
    expect(res.patch!.number, 1, reason: 'falls back to last good patch');
    expect(res.rolledBackPatchNumbers, contains(2));
  });

  test('rollout 0% withholds and falls back to older fully-rolled patch',
      () async {
    await repo.registerPatch(_patch(1));
    await repo.registerPatch(_patch(2, rollout: 0));
    final res = await repo.checkForPatch(_req(current: 0));
    expect(res.patch!.number, 1);
  });

  test('arch is part of release identity', () async {
    await repo.registerPatch(_patch(1));
    final res = await repo.checkForPatch(_req(current: 0, arch: 'x86_64'));
    expect(res.patchAvailable, isFalse);
  });

  test('setRolledBack flips the flag and withholds the patch', () async {
    await repo.registerPatch(_patch(1));
    final ok = await repo.setRolledBack(
      releaseKey: 'app|1.0.0+1|android|arm64|stable',
      number: 1,
      value: true,
    );
    expect(ok, isTrue);
    final res = await repo.checkForPatch(_req(current: 0));
    expect(res.patchAvailable, isFalse);
    expect(res.rolledBackPatchNumbers, contains(1));
  });
}
