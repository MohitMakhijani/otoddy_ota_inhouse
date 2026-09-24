// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/libapp.so.dart' as libapp_so;
import '../routes/index.dart' as index;
import '../routes/patches/[file].dart' as patches_$file;
import '../routes/latest/index.dart' as latest_index;
import '../routes/apk/[file].dart' as apk_$file;
import '../routes/api/v1/patches/events.dart' as api_v1_patches_events;
import '../routes/api/v1/patches/check.dart' as api_v1_patches_check;
import '../routes/admin/rollback/index.dart' as admin_rollback_index;
import '../routes/admin/patches/index.dart' as admin_patches_index;
import '../routes/admin/events/index.dart' as admin_events_index;
import '../routes/admin/devices/index.dart' as admin_devices_index;
import '../routes/admin/build/index.dart' as admin_build_index;
import '../routes/admin/branches/index.dart' as admin_branches_index;

import '../routes/_middleware.dart' as middleware;
import '../routes/admin/_middleware.dart' as admin_middleware;

void main() async {
  final address = InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  createServer(address, port);
}

Future<HttpServer> createServer(InternetAddress address, int port) async {
  final handler = Cascade().add(buildRootHandler()).handler;
  final server = await serve(handler, address, port);
  print('\x1B[92m✓\x1B[0m Running on http://${server.address.host}:${server.port}');
  return server;
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/patches', (context) => buildPatchesHandler()(context))
    ..mount('/latest', (context) => buildLatestHandler()(context))
    ..mount('/apk', (context) => buildApkHandler()(context))
    ..mount('/api/v1/patches', (context) => buildApiV1PatchesHandler()(context))
    ..mount('/admin/rollback', (context) => buildAdminRollbackHandler()(context))
    ..mount('/admin/patches', (context) => buildAdminPatchesHandler()(context))
    ..mount('/admin/events', (context) => buildAdminEventsHandler()(context))
    ..mount('/admin/devices', (context) => buildAdminDevicesHandler()(context))
    ..mount('/admin/build', (context) => buildAdminBuildHandler()(context))
    ..mount('/admin/branches', (context) => buildAdminBranchesHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/libapp.so', (context) => libapp_so.onRequest(context,))..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildPatchesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<file>', (context,file,) => patches_$file.onRequest(context,file,));
  return pipeline.addHandler(router);
}

Handler buildLatestHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => latest_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApkHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<file>', (context,file,) => apk_$file.onRequest(context,file,));
  return pipeline.addHandler(router);
}

Handler buildApiV1PatchesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/check', (context) => api_v1_patches_check.onRequest(context,))..all('/events', (context) => api_v1_patches_events.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminRollbackHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_rollback_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminPatchesHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_patches_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminEventsHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_events_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminDevicesHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_devices_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminBuildHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_build_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAdminBranchesHandler() {
  final pipeline = const Pipeline().addMiddleware(admin_middleware.middleware);
  final router = Router()
    ..all('/', (context) => admin_branches_index.onRequest(context,));
  return pipeline.addHandler(router);
}

