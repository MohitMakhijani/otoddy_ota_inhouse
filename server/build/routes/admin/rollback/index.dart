import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';

/// Kill switch: `POST /admin/rollback`. The next check response advertises the
/// number in `rolled_back_patch_numbers`, and devices revert to their last
/// good patch on the following launch.
///
/// Body: either `release_key`, or the 5 parts (app_id, release_version,
/// platform, arch, channel); plus `number` and optional `rolled_back` (bool).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return Response(statusCode: HttpStatus.badRequest, body: 'invalid json');
  }

  final number = (body['number'] as num?)?.toInt();
  if (number == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'number required');
  }
  final value = (body['rolled_back'] as bool?) ?? true;

  var releaseKey = body['release_key'] as String?;
  if (releaseKey == null) {
    final appId = body['app_id'] as String?;
    final releaseVersion = body['release_version'] as String?;
    final platform = body['platform'] as String?;
    final arch = body['arch'] as String?;
    final channel = (body['channel'] as String?) ?? 'stable';
    if (appId != null &&
        releaseVersion != null &&
        platform != null &&
        arch != null) {
      releaseKey = '$appId|$releaseVersion|$platform|$arch|$channel';
    }
  }
  if (releaseKey == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'provide release_key or (app_id, release_version, platform, arch)',
    );
  }

  final repository = context.read<CodePushRepository>();
  final updated = await repository.setRolledBack(
    releaseKey: releaseKey,
    number: number,
    value: value,
  );

  return Response.json(
    body: {
      'updated': updated,
      'release_key': releaseKey,
      'number': number,
      'rolled_back': value,
    },
  );
}
