import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/config/env.dart';

/// Guards every `/admin/*` route with a static bearer token.
/// Replace with real auth (OIDC, mTLS, signed CI tokens) before exposing.
Handler middleware(Handler handler) {
  return (context) {
    final auth = context.request.headers[HttpHeaders.authorizationHeader];
    if (auth != 'Bearer ${Env.adminToken}') {
      return Response(statusCode: HttpStatus.unauthorized, body: 'unauthorized');
    }
    return handler(context);
  };
}
