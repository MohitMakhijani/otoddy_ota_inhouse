val localEngineMaven: String? = System.getenv("LOCAL_ENGINE_MAVEN")
allprojects {
    repositories {
        if (!localEngineMaven.isNullOrBlank()) {
            maven { url = java.io.File(localEngineMaven).toURI() }
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
