import 'dart:async';
import 'dart:convert';
import 'dart:io';

class BranchBuilder {
  BranchBuilder({
    required this.scriptPath,
    required this.worktreeDir,
  });

  final String scriptPath;
  final String worktreeDir;

  bool _running = false;
  String _currentBranch = '';
  final StringBuffer _logBuffer = StringBuffer();
  int? _exitCode;

  bool get isRunning => _running;
  String get currentBranch => _currentBranch;
  String get log => _logBuffer.toString();
  int? get exitCode => _exitCode;

  Future<List<String>> branches() async {
    final dir = worktreeDir.isNotEmpty ? Directory(worktreeDir) : Directory.current;
    if (!dir.existsSync()) {
      return ['main'];
    }
    try {
      final res = await Process.run(
        'git',
        ['branch', '-a'],
        workingDirectory: dir.path,
        runInShell: true,
      );
      if (res.exitCode != 0) return ['main'];
      final lines = (res.stdout as String).split('\n');
      final list = <String>{};
      for (var l in lines) {
        l = l.trim().replaceAll('*', '').trim();
        if (l.isEmpty || l.contains('->')) continue;
        if (l.startsWith('remotes/origin/')) {
          l = l.substring('remotes/origin/'.length);
        } else if (l.startsWith('origin/')) {
          l = l.substring('origin/'.length);
        }
        if (l.isNotEmpty) list.add(l);
      }
      if (list.isEmpty) list.add('main');
      return list.toList()..sort();
    } catch (_) {
      return ['main'];
    }
  }

  Future<bool> startBuild(String branch) async {
    if (_running) return false;
    if (scriptPath.isEmpty) return false;

    _running = true;
    _currentBranch = branch;
    _logBuffer.clear();
    _exitCode = null;

    unawaited(() async {
      try {
        final process = await Process.start(
          scriptPath,
          [branch],
          workingDirectory: worktreeDir.isNotEmpty ? worktreeDir : null,
          runInShell: true,
        );

        process.stdout
            .transform(utf8.decoder)
            .listen((data) => _logBuffer.write(data));
        process.stderr
            .transform(utf8.decoder)
            .listen((data) => _logBuffer.write(data));

        _exitCode = await process.exitCode;
      } catch (e) {
        _logBuffer.writeln('Build failed to launch: $e');
        _exitCode = 1;
      } finally {
        _running = false;
      }
    }());

    return true;
  }
}
