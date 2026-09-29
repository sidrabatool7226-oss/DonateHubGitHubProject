pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false // 8.7.0 se 8.9.1 kar diya
    id("com.google.gms.google-services") version "4.4.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false // 2.1.0 se 2.3.20 kar diya — google_maps_flutter ki dependencies ko Kotlin 2.3.0 metadata chahiye tha
}

include(":app")
include(":app")