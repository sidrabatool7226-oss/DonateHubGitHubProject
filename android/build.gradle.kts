//plugins {
//    id("com.android.application") apply false
//    id("com.android.library") apply false
//    id("org.jetbrains.kotlin.android") apply false
//    id("com.google.gms.google-services") apply false
//}
//
//allprojects {
//    repositories {
//        google()
//        mavenCentral()
//    }
//}
//
//// Baaki aapka task clean aur buildDir wala code niche rehne dein
//
//allprojects {
//    repositories {
//        google()
//        mavenCentral()
//    }
//}
//
//// Baki niche wala buildDir wala code waisa hi rehne dein

// 2. Aapka repository wala part (Bilkul thik hai)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 3. Build directory logic (Isay waise hi rehne dein jaisa aapne likha hai)
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

// 4. Clean task (Bilkul thik hai)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}