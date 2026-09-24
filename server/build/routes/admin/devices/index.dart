import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';

/// `GET /admin/devices` — the most-recent check-in per device, newest first.
/// Live adoption telemetry derived from the check API.
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final repository = context.read<CodePushRepository>();
  return Response.json(
    body: {'devices': repository.devices().map((d) => d.toJson()).toList()},
  );
}
