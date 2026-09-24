## 1.0.1

* Updated official package metadata and homepage to https://otoddy.com.
* Added comprehensive OTODDY documentation, branding, and enterprise examples.
* Streamlined client initialization API with `OtoddyOTA`.

## 1.0.0

* Initial release of `otoddyota`.
* Drop-in Over-The-Air (OTA) Flutter client.
* Dynamic architecture detection (`arm64-v8a`, `x86_64`) via `Abi.current()`.
* Atomic downloads with checksum and snapshot hash validation.
* Multi-endpoint server fallback and retry support.
* Emergency remote rollback / killswitch support.
