import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/models/api_models.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';

/// Telemetry sink: `POST /api/v1/patches/events`. Accepting these drains the
/// updater's on-device event queue and feeds adoption/failure dashboards.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final repository = context.read<CodePushRepository>();
  try {
    final body = await context.request.json();
    if (body is Map<String, dynamic>) {
      repository.recordEvent(PatchEvent.fromJson(body));
    }
  } catch (_) {
    // Telemetry is best-effort; never fail the device on a bad event body.
  }

  return Response(statusCode: HttpStatus.created);
}
