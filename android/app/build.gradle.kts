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
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // Isay as it is rehne dein
    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }
}

flutter {
    source = "../.."
}

dependencies {
    // MultiDex support for older Android versions
    implementation("androidx.multidex:multidex:2.0.1")

    // Firebase ki basic dependency
    implementation(platform("com.google.firebase:firebase-bom:32.8.0"))
    implementation("com.google.firebase:firebase-analytics")
}
