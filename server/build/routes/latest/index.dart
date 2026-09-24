import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/config/env.dart';

/// `GET /latest` — APK self-update manifest.
///
/// The in-app APK updater polls this, compares `version_code` against the
/// installed build, and if newer downloads `<its base url><apk_path>` and fires
/// the Android install prompt. `apk_path` is relative so the app uses whatever
/// base it was built with (e.g. a cloudflared URL).
///
/// Backed by `<storage>/latest.json`:
///   {"version_code": 582, "version_name": "5.5.1", "apk_path": "/apk/<key>.apk", "notes": "..."}
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final f = File('${Env.patchStorageDir}/latest.json');
  if (!f.existsSync()) {
    return Response.json(body: {'available': false});
  }
  try {
    final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    return Response.json(body: {'available': true, ...m});
  } catch (_) {
    return Response.json(body: {'available': false});
  }
}
