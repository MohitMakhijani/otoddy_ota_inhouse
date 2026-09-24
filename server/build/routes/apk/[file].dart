import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/storage/patch_storage.dart';

/// Serves the full installable APK for a build (`GET /apk/<key>.apk`), as a
/// download. This is what you sideload onto a physical device — distinct from
/// the `.vmcode` patch (the Dart snapshot) used for over-the-air updates.
Future<Response> onRequest(RequestContext context, String file) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  if (!file.endsWith('.apk')) {
    return Response(statusCode: HttpStatus.notFound);
  }
  final storage = context.read<PatchStorage>();
  final target = await storage.fileFor(file);
  if (target == null) {
    return Response(
      statusCode: HttpStatus.notFound,
      body: 'no APK kept for this build',
    );
  }
  return Response.bytes(
    body: await target.readAsBytes(),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/vnd.android.package-archive',
      'content-disposition': 'attachment; filename="$file"',
    },
  );
}
