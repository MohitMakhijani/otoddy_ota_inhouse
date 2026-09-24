/// Wire DTOs that mirror the Shorebird updater contract **exactly**.
///
/// The JSON keys below are baked into the engine binary — do not rename them.
/// Source of truth: shorebirdtech/updater `library/src/network.rs`.
library;

/// Body the on-device updater POSTs to `/api/v1/patches/check`.
class PatchCheckRequest {
  const PatchCheckRequest({
    required this.appId,
    required this.channel,
    required this.releaseVersion,
    required this.platform,
    required this.arch,
    required this.clientId,
    this.currentPatchNumber,
  });

  factory PatchCheckRequest.fromJson(Map<String, dynamic> json) {
    return PatchCheckRequest(
      appId: json['app_id'] as String,
      channel: (json['channel'] as String?) ?? 'stable',
      releaseVersion: json['release_version'] as String,
      platform: json['platform'] as String,
      arch: json['arch'] as String,
      clientId: (json['client_id'] as String?) ?? '',
      currentPatchNumber: (json['current_patch_number'] as num?)?.toInt(),
    );
  }

  final String appId;
  final String channel;
  final String releaseVersion;
  final String platform;
  final String arch;
  final String clientId;

  /// Highest patch the device already has. Absent when none is installed.
  final int? currentPatchNumber;
}

/// The `patch` object inside a positive check response.
class Patch {
  const Patch({
    required this.number,
    required this.hash,
    required this.downloadUrl,
    this.hashSignature,
  });

  final int number;

  /// Lowercase hex SHA-256 of the inflated patch. Corruption check, not auth.
  final String hash;
  final String downloadUrl;

  /// base64 RSA signature of [hash]. Required if the release embeds a pubkey.
  final String? hashSignature;

  Map<String, dynamic> toJson() => {
        'number': number,
        'hash': hash,
        'download_url': downloadUrl,
        if (hashSignature != null) 'hash_signature': hashSignature,
      };
}

/// Body returned from `/api/v1/patches/check`.
class PatchCheckResponse {
  const PatchCheckResponse({
    required this.patchAvailable,
    this.patch,
    this.rolledBackPatchNumbers,
  });

  final bool patchAvailable;
  final Patch? patch;

  /// Patch numbers the device must revert. This is the kill-switch channel.
  final List<int>? rolledBackPatchNumbers;

  Map<String, dynamic> toJson() => {
        'patch_available': patchAvailable,
        if (patch != null) 'patch': patch!.toJson(),
        if (rolledBackPatchNumbers != null &&
            rolledBackPatchNumbers!.isNotEmpty)
          'rolled_back_patch_numbers': rolledBackPatchNumbers,
      };
}

/// Telemetry event POSTed to `/api/v1/patches/events`. Shape is intentionally
/// opaque — we store it verbatim for adoption/failure dashboards.
class PatchEvent {
  const PatchEvent(this.raw);

  factory PatchEvent.fromJson(Map<String, dynamic> json) => PatchEvent(json);

  final Map<String, dynamic> raw;
}
