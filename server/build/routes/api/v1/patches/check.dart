import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/models/api_models.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';

/// The endpoint the on-device updater polls: `POST /api/v1/patches/check`.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final PatchCheckRequest request;
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    request = PatchCheckRequest.fromJson(body);
  } catch (_) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'invalid patch-check request',
    );
  }

  final repository = context.read<CodePushRepository>();
  final response = await repository.checkForPatch(request);
  return Response.json(body: response.toJson());
}
