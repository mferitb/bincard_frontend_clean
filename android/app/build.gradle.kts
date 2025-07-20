plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")

}

android {
    namespace = "com.example.city_card.city_card"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Desugaring için iCore8 kütüphanelerini etkinleştir
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.city_card.city_card"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23 // Biyometrik kimlik doğrulama için minimum SDK 23 olmalı
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // MultiDex desteğini etkinleştir
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Desugaring bağımlılığı
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // MultiDex desteği
    implementation("androidx.multidex:multidex:2.0.1")
    // Biyometrik kimlik doğrulama için destek
    implementation("androidx.biometric:biometric:1.1.0")
    // Core bağımlılıklarını uyumlu sürümlere düşür
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.core:core:1.12.0")
    implementation("com.google.firebase:firebase-messaging:23.0.0")
}

flutter {
    source = "../.."
}
