# Server — dashboard + code-push API

A [Dart Frog](https://dartfrog.vgv.dev) app: the web dashboard, the updater wire
API, patch hosting, and the admin endpoints (upload, rollback, branch build).

## Run

```bash
dart pub global activate dart_frog_cli   # once
dart pub get
dart_frog dev --port 8080
```

Configure via environment — see [`../.env.example`](../.env.example):
`ADMIN_TOKEN`, `PUBLIC_BASE_URL`, `PATCH_STORAGE_DIR`, `CODEPUSH_APP_ID`,
`CODEPUSH_RELEASE_VERSION`, `PATCH_PRIVATE_KEY_PATH`. For local dev,
[`../tooling/dashboard-serve.sh`](../tooling/dashboard-serve.sh) exports them
from `config.env` and starts the server for you.

## Endpoints

| Route | Purpose |
| --- | --- |
| `GET /` | Web dashboard (HTML). |
| `POST /api/v1/patches/check` | Updater check — returns the newest applicable patch. |
| `POST /api/v1/patches/events` | Updater telemetry (download / install / failure). |
| `GET /libapp.so` | The active patch artifact (Range-capable). |
| `GET /patches/<file>` | A specific patch artifact by key. |
| `GET /apk/<file>` | Full APK kept alongside a patch (for sideloading). |
| `GET /latest` | Manifest for the full-APK self-updater. |
| `POST /admin/patches` · `GET /admin/patches` | Register / list patches (Bearer `ADMIN_TOKEN`). |
| `POST /admin/rollback` | Roll a patch back. |
| `GET /admin/branches` · `POST /admin/build` | Branch picker (build-from-branch). |

Patches + a `registry.json` index are stored under `PATCH_STORAGE_DIR`
(default `_patches/`, gitignored). The registry is reloaded on startup, so the
server is stateless across restarts apart from that directory.
