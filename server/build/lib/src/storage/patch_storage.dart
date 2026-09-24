import 'dart:io';

import 'package:inhouse_codepush_server/src/config/env.dart';

/// Where patch bytes live and how devices fetch them.
///
/// Swap [LocalPatchStorage] for an R2/S3-backed implementation in production:
/// `put` uploads the object, `urlFor` returns the CDN URL, and you can drop
/// [fileFor] / the local `/patches/<key>` route entirely (the CDN serves it).
abstract class PatchStorage {
  /// Persists [bytes] under [key] (a single, URL-safe path segment).
  Future<void> put(String key, List<int> bytes);

  /// Public URL the device GETs to download the patch.
  String urlFor(String key);

  /// Backing file for [key], or null if absent. Used by the local file route.
  Future<File?> fileFor(String key);
}

/// Filesystem-backed storage for local development and the MVP.
class LocalPatchStorage implements PatchStorage {
  LocalPatchStorage({String? baseDir, String? publicBaseUrl})
      : _baseDir = baseDir ?? Env.patchStorageDir,
        _publicBaseUrl = publicBaseUrl ?? Env.publicBaseUrl;

  final String _baseDir;
  final String _publicBaseUrl;

  File _file(String key) => File('$_baseDir/$key');

  @override
  Future<void> put(String key, List<int> bytes) async {
    final file = _file(key);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  String urlFor(String key) => '$_publicBaseUrl/patches/$key';

  @override
  Future<File?> fileFor(String key) async {
    final file = _file(key);
    return file.existsSync() ? file : null;
  }
}
