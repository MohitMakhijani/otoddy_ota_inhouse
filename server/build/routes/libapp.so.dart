import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';
import 'package:inhouse_codepush_server/src/storage/patch_storage.dart';

/// Convenience download endpoint for the bundled demo updater, which GETs a
/// bare `libapp.so`. Serves the *active* patch = the highest-numbered,
/// non-rolled-back patch currently registered.
///
/// Production apps should instead use POST /api/v1/patches/check (per-release,
/// rollout-aware, signed) + GET /patches/<key>. This endpoint exists so the
/// already-installed demo build keeps working unchanged against the dashboard.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final repository = context.read<CodePushRepository>();
  final storage = context.read<PatchStorage>();

  final active = repository.allPatches().where((p) => !p.rolledBack).toList()
    ..sort((a, b) => b.number.compareTo(a.number));
  if (active.isEmpty) {
    return Response(statusCode: HttpStatus.notFound, body: 'no active patch');
  }

  final chosen = active.first;
  final file = await storage.fileFor(chosen.storageKey);
  if (file == null) {
    return Response(
      statusCode: HttpStatus.notFound,
      body: 'patch bytes missing for ${chosen.storageKey}',
    );
  }

  return Response.bytes(
    body: await file.readAsBytes(),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/octet-stream',
      'X-Patch-Number': '${chosen.number}',
      'X-Patch-Hash': chosen.hash,
    },
  );
}
