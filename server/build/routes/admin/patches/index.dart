import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/models/records.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';
import 'package:inhouse_codepush_server/src/signing/patch_signer.dart';
import 'package:inhouse_codepush_server/src/storage/patch_storage.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _list(context);
    case HttpMethod.post:
      return _register(context);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Response _list(RequestContext context) {
  final repository = context.read<CodePushRepository>();
  return Response.json(
    body: {
      'patches': repository.allPatches().map((p) => p.toJson()).toList(),
    },
  );
}

/// Registers a patch: hashes the bytes, stores them, signs the hash (if a key
/// is configured), and records the metadata. This is the seam the forked CLI
/// will call in Phase 2 instead of you uploading by hand.
Future<Response> _register(RequestContext context) async {
  final repository = context.read<CodePushRepository>();
  final storage = context.read<PatchStorage>();
  final signer = context.read<PatchSigner?>();

  final form = await context.request.formData();
  final fields = form.fields;
  final file = form.files['patch'];

  final appId = fields['app_id'];
  final releaseVersion = fields['release_version'];
  final platform = fields['platform'];
  final arch = fields['arch'];
  final numberStr = fields['number'];

  if (file == null ||
      appId == null ||
      releaseVersion == null ||
      platform == null ||
      arch == null ||
      numberStr == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'required: file field "patch" + app_id, release_version, '
          'platform, arch, number',
    );
  }

  final number = int.tryParse(numberStr);
  if (number == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'number must be an integer',
    );
  }

  final channel = fields['channel'] ?? 'stable';
  final rollout = (int.tryParse(fields['rollout_percentage'] ?? '100') ?? 100)
      .clamp(0, 100);

  final bytes = await file.readAsBytes();
  final hash = sha256.convert(bytes).toString();

  final storageKey = '${_safe(appId)}_${_safe(releaseVersion)}_'
      '${_safe(platform)}_${_safe(arch)}_$number.vmcode';
  await storage.put(storageKey, bytes);

  final signature = signer?.sign(hash);

  final record = PatchRecord(
    appId: appId,
    releaseVersion: releaseVersion,
    platform: platform,
    arch: arch,
    channel: channel,
    number: number,
    hash: hash,
    storageKey: storageKey,
    hashSignature: signature,
    rolloutPercentage: rollout,
    sizeBytes: bytes.length,
  );
  await repository.registerPatch(record);

  return Response.json(
    statusCode: HttpStatus.created,
    body: {
      'registered': record.toJson(),
      'download_url': storage.urlFor(storageKey),
      'signed': signature != null,
    },
  );
}

String _safe(String value) => value.replaceAll(RegExp('[^A-Za-z0-9.-]'), '-');
