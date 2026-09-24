// === IN-HOUSE CODE PUSH: use the hook'd Flutter embedding jar ===
// Resolves io.flutter:flutter_embedding_release:1.0.0-<engine> from a local
// Maven repo (the patched FlutterLoader that loads downloaded patches) instead
// of the stock one. Set LOCAL_ENGINE_MAVEN to your hook'd jar's repo; it MUST be
// listed first so Gradle prefers it over download.flutter.io. Unset = a normal
// build with NO code-push hook (downloaded patches are silently ignored).
val localEngineMaven: String? = System.getenv("LOCAL_ENGINE_MAVEN")
allprojects {
    repositories {
        if (!localEngineMaven.isNullOrBlank()) {
            maven { url = java.io.File(localEngineMaven).toURI() }
        } else {
            logger.warn(
                "LOCAL_ENGINE_MAVEN not set -> building WITHOUT the code-push hook.",
            )
        }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
