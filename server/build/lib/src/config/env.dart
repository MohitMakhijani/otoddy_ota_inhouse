import 'dart:io';

/// Process configuration read from environment variables.
///
/// Defaults are dev-friendly; override everything in production.
class Env {
  const Env._();

  static String get publicBaseUrl =>
      Platform.environment['PUBLIC_BASE_URL'] ?? 'http://localhost:8080';

  static String get adminToken =>
      Platform.environment['ADMIN_TOKEN'] ?? 'dev-admin-token-change-me';

  static String get patchStorageDir =>
      Platform.environment['PATCH_STORAGE_DIR'] ?? '_patches';

  /// Pre-filled in the dashboard's upload form. Set these to the package id and
  /// release version of the app you ship patches to.
  static String get defaultAppId =>
      Platform.environment['CODEPUSH_APP_ID'] ?? 'com.example.app';

  static String get defaultReleaseVersion =>
      Platform.environment['CODEPUSH_RELEASE_VERSION'] ?? '1.0.0';

  /// Build-from-branch tooling, used by the dashboard's branch picker. Point
  /// PUSH_BRANCH_SCRIPT at this repo's tooling/push-branch.sh and WORKTREE_DIR
  /// at the git worktree it builds in. Leave both empty to hide the branch
  /// picker (manual artifact upload still works).
  static String get pushBranchScript =>
      Platform.environment['PUSH_BRANCH_SCRIPT'] ?? '';

  static String get worktreeDir => Platform.environment['WORKTREE_DIR'] ?? '';

  /// Null disables signing — patches are served without `hash_signature`,
  /// which the updater accepts only for releases built without a public key.
  static String? get patchPrivateKeyPath {
    final value = Platform.environment['PATCH_PRIVATE_KEY_PATH'];
    return (value == null || value.isEmpty) ? null : value;
  }
}
