import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';

/// `GET /admin/events` — inspect the telemetry the updater has reported.
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final repository = context.read<CodePushRepository>();
  return Response.json(
    body: {'events': repository.events().map((e) => e.raw).toList()},
  );
}
