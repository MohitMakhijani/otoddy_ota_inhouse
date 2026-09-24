/// Stored entities (what the repository persists). Kept separate from the
/// wire DTOs so the storage schema can evolve independently of the contract.
library;

/// A single patch for one (app, release, platform, arch, channel) tuple.
class PatchRecord {
  PatchRecord({
    required this.appId,
    required this.releaseVersion,
    required this.platform,
    required this.arch,
    required this.channel,
    required this.number,
    required this.hash,
    required this.storageKey,
    this.hashSignature,
    this.rolledBack = false,
    this.rolloutPercentage = 100,
    this.sizeBytes = 0,
  });

  factory PatchRecord.fromJson(Map<String, dynamic> json) => PatchRecord(
        appId: json['app_id'] as String,
        releaseVersion: json['release_version'] as String,
        platform: json['platform'] as String,
        arch: json['arch'] as String,
        channel: json['channel'] as String,
        number: (json['number'] as num).toInt(),
        hash: json['hash'] as String,
        storageKey: json['storage_key'] as String,
        hashSignature: json['hash_signature'] as String?,
        rolledBack: (json['rolled_back'] as bool?) ?? false,
        rolloutPercentage: (json['rollout_percentage'] as num?)?.toInt() ?? 100,
        sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      );

  final String appId;
  final String releaseVersion;
  final String platform;
  final String arch;
  final String channel;
  final int number;

  /// Lowercase hex SHA-256 of the inflated patch.
  final String hash;

  /// Opaque key into [PatchStorage] (single path segment).
  final String storageKey;

  /// base64 RSA signature of [hash], computed at registration time.
  String? hashSignature;

  /// Rolled-back patches are advertised in `rolled_back_patch_numbers` and
  /// never served as the active patch.
  bool rolledBack;

  /// Staged rollout gate, 0..100. Deterministic per (clientId, number).
  int rolloutPercentage;

  /// Size of the stored patch artifact, in bytes (0 if unknown).
  final int sizeBytes;

  /// Identity of the release this patch targets.
  String get releaseKey =>
      '$appId|$releaseVersion|$platform|$arch|$channel';

  Map<String, dynamic> toJson() => {
        'app_id': appId,
        'release_version': releaseVersion,
        'platform': platform,
        'arch': arch,
        'channel': channel,
        'number': number,
        'hash': hash,
        'storage_key': storageKey,
        'hash_signature': hashSignature,
        'rolled_back': rolledBack,
        'rollout_percentage': rolloutPercentage,
        'size_bytes': sizeBytes,
      };
}

/// A device's most-recent check-in — live adoption telemetry, derived from the
/// check API (no app-side change needed). In-memory only; resets on restart.
class DeviceCheckin {
  DeviceCheckin({
    required this.clientId,
    required this.appId,
    required this.releaseVersion,
    required this.platform,
    required this.arch,
    required this.currentPatchNumber,
    required this.lastSeen,
  });

  final String clientId;
  final String appId;
  final String releaseVersion;
  final String platform;
  final String arch;
  final int? currentPatchNumber;
  final DateTime lastSeen;

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'app_id': appId,
        'release_version': releaseVersion,
        'platform': platform,
        'arch': arch,
        'current_patch_number': currentPatchNumber,
        'last_seen': lastSeen.toIso8601String(),
      };
}
