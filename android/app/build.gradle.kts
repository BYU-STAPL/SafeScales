import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Apply Google Services only when google-services.json exists (e.g. after downloading from Firebase Console).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "edu.byu.safe_scales"
    compileSdk = flutter.compileSdkVersion
//    ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "edu.byu.safe_scales"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21 // Explicitly set minimum SDK version
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        val keystoreProperties = Properties()
        val keystorePropertiesFile = rootProject.file("key.properties")
        if (keystorePropertiesFile.exists()) {
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        }
        val keystorePath = if (keystorePropertiesFile.exists()) {
            keystoreProperties["storeFile"] as? String
        } else {
            System.getenv("KEYSTORE_FILE")
        } ?: "keystore.jks"
        val keystoreFile = file(keystorePath)
        val hasReleaseKeystore = keystoreFile.exists()

        if (hasReleaseKeystore) {
            create("release") {
                storeFile = keystoreFile
                storePassword = keystoreProperties["storePassword"] as String? ?: System.getenv("KEYSTORE_PASSWORD") ?: ""
                keyAlias = keystoreProperties["keyAlias"] as String? ?: System.getenv("KEY_ALIAS") ?: ""
                keyPassword = keystoreProperties["keyPassword"] as String? ?: System.getenv("KEY_PASSWORD") ?: ""
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signingConfigs.findByName("release") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.0")
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))
    // Add Firebase product dependencies as needed
}

flutter {
    source = "../.."
}
