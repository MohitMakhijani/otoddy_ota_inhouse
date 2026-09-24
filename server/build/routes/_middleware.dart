import 'package:dart_frog/dart_frog.dart';
import 'package:inhouse_codepush_server/src/build/branch_builder.dart';
import 'package:inhouse_codepush_server/src/dependencies.dart';
import 'package:inhouse_codepush_server/src/repository/code_push_repository.dart';
import 'package:inhouse_codepush_server/src/signing/patch_signer.dart';
import 'package:inhouse_codepush_server/src/storage/patch_storage.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(provider<CodePushRepository>((_) => codePushRepository))
      .use(provider<PatchStorage>((_) => patchStorage))
      .use(provider<PatchSigner?>((_) => patchSigner))
      .use(provider<BranchBuilder>((_) => branchBuilder));
}
