import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/storage/patch_storage.dart';

/// Serves patch bytes for local/dev (`GET /patches/<key>`), with HTTP Range
/// support because the updater downloads resumably. In production a CDN/R2
/// origin serves these and this route can be removed.
Future<Response> onRequest(RequestContext context, String file) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final storage = context.read<PatchStorage>();
  final target = await storage.fileFor(file);
  if (target == null) {
    return Response(statusCode: HttpStatus.notFound, body: 'patch not found');
  }

  final total = await target.length();
  final rangeHeader = context.request.headers[HttpHeaders.rangeHeader];

  if (rangeHeader == null) {
    return Response.bytes(
      body: await target.readAsBytes(),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/octet-stream',
        HttpHeaders.acceptRangesHeader: 'bytes',
      },
    );
  }

  final match = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(rangeHeader);
  if (match == null) {
    return Response(statusCode: HttpStatus.requestedRangeNotSatisfiable);
  }

  final startStr = match.group(1) ?? '';
  final endStr = match.group(2) ?? '';

  int start;
  int end;
  if (startStr.isEmpty) {
    // Suffix range: last N bytes.
    final n = endStr.isEmpty ? 0 : int.parse(endStr);
    start = (total - n).clamp(0, total);
    end = total - 1;
  } else {
    start = int.parse(startStr);
    end = endStr.isEmpty ? total - 1 : int.parse(endStr);
  }

  if (start >= total || start > end) {
    return Response(
      statusCode: HttpStatus.requestedRangeNotSatisfiable,
      headers: {HttpHeaders.contentRangeHeader: 'bytes */$total'},
    );
  }
  end = end.clamp(0, total - 1);
  final length = end - start + 1;

  final raf = await target.open();
  await raf.setPosition(start);
  final bytes = await raf.read(length);
  await raf.close();

  return Response.bytes(
    statusCode: HttpStatus.partialContent,
    body: bytes,
    headers: {
      HttpHeaders.contentTypeHeader: 'application/octet-stream',
      HttpHeaders.acceptRangesHeader: 'bytes',
      HttpHeaders.contentRangeHeader: 'bytes $start-$end/$total',
    },
  );
}
