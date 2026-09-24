import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/build/branch_builder.dart';

/// `GET /admin/branches` — fresh list of remote branches for the dashboard's
/// branch picker.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final builder = context.read<BranchBuilder>();
  return Response.json(body: {'branches': await builder.branches()});
}
