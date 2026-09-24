import 'dart:convert';
import 'dart:io';

import 'package:inhouse_codepush_server/src/config/env.dart';
import 'package:inhouse_codepush_server/src/models/api_models.dart';
import 'package:inhouse_codepush_server/src/models/records.dart';
import 'package:inhouse_codepush_server/src/storage/patch_storage.dart';

/// Persistence + the patch-selection decision logic.
///
/// Swap [InMemoryCodePushRepository] for a Postgres-backed implementation in
/// production; the routes depend only on this interface.
abstract class CodePushRepository {
  /// Core decision: which patch (if any) should this device receive?
  Future<PatchCheckResponse> checkForPatch(PatchCheckRequest req);

  Future<PatchRecord> registerPatch(PatchRecord record);

  /// Flips the rolled-back flag for a specific patch.
  Future<bool> setRolledBack({
    required String releaseKey,
    required int number,
    required bool value,
  });

  List<PatchRecord> allPatches();

  void recordEvent(PatchEvent event);

  List<PatchEvent> events();

  /// Most-recent check-in per device (live adoption telemetry).
  List<DeviceCheckin> devices();
}

class InMemoryCodePushRepository implements CodePushRepository {
  InMemoryCodePushRepository({required PatchStorage storage})
      : _storage = storage {
    _load();
  }

  final PatchStorage _storage;
  final List<PatchRecord> _patches = [];
  final List<PatchEvent> _events = [];
  final Map<String, DeviceCheckin> _devices = {};

  /// Patch metadata is mirrored to disk so the dashboard survives restarts.
  /// (Swap for Postgres in production; this keeps the local routine durable.)
  File get _registryFile => File('${Env.patchStorageDir}/registry.json');

  void _load() {
    try {
      final f = _registryFile;
      if (!f.existsSync()) return;
      final list = jsonDecode(f.readAsStringSync()) as List<dynamic>;
      _patches
        ..clear()
        ..addAll(
          list.map((e) => PatchRecord.fromJson(e as Map<String, dynamic>)),
        );
    } catch (_) {
      // Corrupt/absent registry -> start empty.
    }
  }

  void _persist() {
    try {
      final f = _registryFile;
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(
        jsonEncode(_patches.map((p) => p.toJson()).toList()),
        flush: true,
      );
    } catch (_) {
      // Best-effort; persistence failures must not break requests.
    }
  }

  @override
  Future<PatchCheckResponse> checkForPatch(PatchCheckRequest req) async {
    _recordCheckin(req);
    final releaseKey =
        '${req.appId}|${req.releaseVersion}|${req.platform}|${req.arch}|${req.channel}';

    final forRelease =
        _patches.where((p) => p.releaseKey == releaseKey).toList();

    final rolledBack = forRelease
        .where((p) => p.rolledBack)
        .map((p) => p.number)
        .toList()
      ..sort();

    final active = forRelease.where((p) => !p.rolledBack).toList()
      ..sort((a, b) => b.number.compareTo(a.number));

    final current = req.currentPatchNumber ?? 0;

    // Highest active patch newer than the device's, that this device is in the
    // rollout bucket for. Older fully-rolled-out patches still win if a newer
    // one is gated off for this client.
    PatchRecord? chosen;
    for (final p in active) {
      if (p.number <= current) break; // desc order => nothing newer remains
      if (_inRollout(req.clientId, p)) {
        chosen = p;
        break;
      }
    }

    final rolled = rolledBack.isEmpty ? null : rolledBack;

    if (chosen == null) {
      return PatchCheckResponse(
        patchAvailable: false,
        rolledBackPatchNumbers: rolled,
      );
    }

    return PatchCheckResponse(
      patchAvailable: true,
      patch: Patch(
        number: chosen.number,
        hash: chosen.hash,
        downloadUrl: _storage.urlFor(chosen.storageKey),
        hashSignature: chosen.hashSignature,
      ),
      rolledBackPatchNumbers: rolled,
    );
  }

  bool _inRollout(String clientId, PatchRecord p) {
    if (p.rolloutPercentage >= 100) return true;
    if (p.rolloutPercentage <= 0) return false;
    final bucket = ('$clientId:${p.number}'.hashCode & 0x7fffffff) % 100;
    return bucket < p.rolloutPercentage;
  }

  @override
  Future<PatchRecord> registerPatch(PatchRecord record) async {
    _patches.removeWhere(
      (p) => p.releaseKey == record.releaseKey && p.number == record.number,
    );
    _patches.add(record);
    _persist();
    return record;
  }

  @override
  Future<bool> setRolledBack({
    required String releaseKey,
    required int number,
    required bool value,
  }) async {
    var found = false;
    for (final p in _patches) {
      if (p.releaseKey == releaseKey && p.number == number) {
        p.rolledBack = value;
        found = true;
      }
    }
    if (found) _persist();
    return found;
  }

  @override
  List<PatchRecord> allPatches() => List.unmodifiable(_patches);

  @override
  void recordEvent(PatchEvent event) => _events.add(event);

  @override
  List<PatchEvent> events() => List.unmodifiable(_events);

  @override
  List<DeviceCheckin> devices() {
    final list = _devices.values.toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    return List.unmodifiable(list);
  }

  void _recordCheckin(PatchCheckRequest req) {
    _devices[req.clientId] = DeviceCheckin(
      clientId: req.clientId,
      appId: req.appId,
      releaseVersion: req.releaseVersion,
      platform: req.platform,
      arch: req.arch,
      currentPatchNumber: req.currentPatchNumber,
      lastSeen: DateTime.now(),
    );
  }
}
