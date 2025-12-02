import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    project.plugins.withId("org.jetbrains.kotlin.jvm") {
        project.the<KotlinJvmProjectExtension>().jvmToolchain(21)
    }}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
