import 'package:inhouse_codepush_server/src/build/branch_builder.dart';
import 'package:inhouse_codepush_server/src/config/env.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';
import 'package:inhouse_codepush_server/src/signing/patch_signer.dart';
import 'package:inhouse_codepush_server/src/storage/patch_storage.dart';

/// Process-wide singletons, wired once and provided to every request.
///
/// Production swap points:
///   * [patchStorage]   -> R2/S3-backed PatchStorage
///   * [codePushRepository] -> Postgres-backed CodePushRepository
///   * [patchSigner]    -> KMS/HSM-backed signer (or keep file-based)
final PatchStorage patchStorage = LocalPatchStorage();

final PatchSigner? patchSigner =
    PatchSigner.fromKeyPath(Env.patchPrivateKeyPath);

final CodePushRepository codePushRepository =
    InMemoryCodePushRepository(storage: patchStorage);

/// Dashboard "pick a branch -> build -> push a patch" runner.
final BranchBuilder branchBuilder = BranchBuilder(
  scriptPath: Env.pushBranchScript,
  worktreeDir: Env.worktreeDir,
);
