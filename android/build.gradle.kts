allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

extra.set("FlutterFire", mapOf(
    "FirebaseSDKVersion" to "34.14.0"
))

println("DEBUG: extra.has('FlutterFire') = ${project.extensions.extraProperties.has("FlutterFire")}")

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
