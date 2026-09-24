import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';

/// What bytes get fed to the RSA-PKCS1v15-SHA256 signature.
///
/// Shorebird signs "the patch hash" and the device verifies that the computed
/// hash carries a valid signature. The exact representation of the hash is the
/// one thing this scaffold cannot confirm from docs alone, so both candidates
/// are implemented. See the warning on [PatchSigner].
enum SignMode {
  /// Sign the lowercase hex SHA-256 string (the same value sent in `hash`).
  hashHexString,

  /// Sign the raw 32 SHA-256 digest bytes.
  hashRawBytes,
}

/// Signs a patch hash so the on-device updater accepts the patch.
///
/// Verified: RSA-2048, RSASSA-PKCS1-v1.5, SHA-256, base64 signature, verified
/// against the `patch_public_key` embedded via `shorebird release
/// --public-key-path`.
///
/// ⚠️ BEFORE ENABLING SIGNING IN PRODUCTION, confirm [SignMode]. If a signed
/// patch is rejected at boot ("invalid signature"), flip the mode — it is the
/// single most likely silent failure. Cross-check against the updater's
/// verification code, then lock the mode in. The MVP path is to leave signing
/// OFF (release without a public key) until this is confirmed.
class PatchSigner {
  PatchSigner._(this._privateKey, this.mode);

  /// Returns null (signing disabled) when [path] is null/empty.
  static PatchSigner? fromKeyPath(
    String? path, {
    SignMode mode = SignMode.hashHexString,
  }) {
    if (path == null) return null;
    final pem = File(path).readAsStringSync();
    final key = CryptoUtils.rsaPrivateKeyFromPem(pem);
    return PatchSigner._(key, mode);
  }

  final RSAPrivateKey _privateKey;
  final SignMode mode;

  /// [sha256Hex] is the lowercase hex SHA-256 of the inflated patch.
  String sign(String sha256Hex) {
    final message = switch (mode) {
      SignMode.hashHexString => Uint8List.fromList(utf8.encode(sha256Hex)),
      SignMode.hashRawBytes => _hexToBytes(sha256Hex),
    };
    // Default algorithm in basic_utils is 'SHA-256/RSA' == PKCS#1 v1.5 + SHA-256.
    final signature = CryptoUtils.rsaSign(_privateKey, message);
    return base64.encode(signature);
  }

  static Uint8List _hexToBytes(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
