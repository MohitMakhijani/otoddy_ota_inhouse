import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/build/branch_builder.dart';

Future<Response> onRequest(RequestContext context) async {
  final builder = context.read<BranchBuilder>();

  if (context.request.method == HttpMethod.get) {
    return Response.json(body: {
      'running': builder.isRunning,
      'branch': builder.currentBranch,
      'log': builder.log,
      'exit_code': builder.exitCode,
    });
  }

  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json() as Map<String, dynamic>;
    final branch = body['branch'] as String?;
    if (branch == null || branch.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'branch is required'},
      );
    }
    final started = await builder.startBuild(branch);
    if (!started) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'error': 'Build already in progress or script not configured'},
      );
    }
    return Response.json(
      statusCode: HttpStatus.accepted,
      body: {'status': 'started', 'branch': branch},
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
