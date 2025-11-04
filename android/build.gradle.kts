buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Place all build outputs in ../../build to keep android/ clean
val rootBuildDirProvider = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(rootBuildDirProvider)

subprojects {
    // Each subproject builds under the shared root build dir
    layout.buildDirectory.set(rootBuildDirProvider.dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
