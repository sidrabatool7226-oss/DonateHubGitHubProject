import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    android {
        namespace = "com.example.donatehub_android_studio"
        compileSdk = 36 // Isay 34 se 36 kar dein

        ndkVersion = "28.2.13676358"

        defaultConfig {
            applicationId = "com.example.donatehub_android_studio"
            minSdk = flutter.minSdkVersion
            targetSdk = 34 // targetSdk ko 34 hi rehne dein, sirf compileSdk ko 36 karein
            versionCode = 1
            versionName = "1.0"
            multiDexEnabled = true
        }
        // ... baaki code waisa hi rehne dein
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // FIXED — Kotlin 2.3.20 mein purana kotlinOptions{jvmTarget=...} syntax
    // error de raha tha ("Using 'jvmTarget: String' is an error"). Naya
    // compilerOptions block neeche, android{} ke bahar, use hota hai.
    // Isay as it is rehne dein
    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
        buildTypes {
            release {
                isMinifyEnabled = true
                isShrinkResources = true

                proguardFiles(
                    getDefaultProguardFile("proguard-android-optimize.txt"),
                    "proguard-rules.pro"
                )
            }
        }
    }
}

// NEW — replaces the old android{ kotlinOptions{ jvmTarget = "17" } }
// syntax, which Kotlin 2.3.20 no longer accepts.
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation(platform("com.google.firebase:firebase-bom:32.8.0"))
    implementation("com.google.firebase:firebase-analytics")
}