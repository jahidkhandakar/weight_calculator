import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.weight_calculator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 🔐 Load keystore info
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    defaultConfig {
        applicationId = "com.example.weight_calculator"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

/**
 * Robust copy/rename tasks that:
 * - look for APKs in BOTH possible locations
 * - don’t fail the build if the file isn’t (yet) in the first place
 */

// Release rename
tasks.register("copyReleaseApk") {
    doLast {
        val flutterOut = file("$buildDir/outputs/flutter-apk/app-release.apk")
        val vanillaOut = file("$buildDir/outputs/apk/release/app-release.apk")
        val src = if (flutterOut.exists()) flutterOut else vanillaOut

        if (src.exists()) {
            copy {
                from(src)
                into("$buildDir/outputs/flutter-apk")
                rename { "WeightCalculator-release.apk" }
            }
            logger.lifecycle("✅ Copied ${src.name} → WeightCalculator-release.apk")
        } else {
            logger.warn("⚠️ No release APK found to copy (checked flutter-apk and apk/release).")
        }
    }
}
tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy("copyReleaseApk")
}

// Debug rename
tasks.register("copyDebugApk") {
    doLast {
        val flutterOut = file("$buildDir/outputs/flutter-apk/app-debug.apk")
        val vanillaOut = file("$buildDir/outputs/apk/debug/app-debug.apk")
        val src = if (flutterOut.exists()) flutterOut else vanillaOut

        if (src.exists()) {
            copy {
                from(src)
                into("$buildDir/outputs/flutter-apk")
                rename { "WeightCalculator-debug.apk" }
            }
            logger.lifecycle("✅ Copied ${src.name} → WeightCalculator-debug.apk")
        } else {
            logger.warn("⚠️ No debug APK found to copy (checked flutter-apk and apk/debug).")
        }
    }
}
tasks.matching { it.name == "assembleDebug" }.configureEach {
    finalizedBy("copyDebugApk")
}
