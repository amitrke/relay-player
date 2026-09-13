import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key, when there is one. android/key.properties is gitignored and
// is written by .github/workflows/release.yml from repository secrets; see
// docs/RELEASING.md for its shape and for how the key itself was made.
//
// This is the *upload* key, not the app signing key. Play App Signing holds
// the key that users' devices actually verify, so losing this one is
// recoverable (Play Console can reset an upload key) where losing an app
// signing key would not be.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}
val hasUploadKey = !keystoreProperties.isEmpty

android {
    // Deliberately left as the generated value while applicationId below is
    // not. namespace only decides the package of generated R/BuildConfig
    // classes and where MainActivity lives; Play never sees it. Moving it
    // would move MainActivity.kt for no user-visible effect.
    namespace = "com.relayplayer.relay_player"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent. The first bundle uploaded to Play binds this ID to the
        // listing, and it can never be changed or reused afterwards — a
        // different ID is a different app, with no upgrade path and none of
        // the previous install's flutter_secure_storage contents. Sideloaded
        // builds from before this was set used com.relayplayer.relay_player
        // and install alongside, not over, anything built since.
        applicationId = "com.subnext.relay"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key when there is no key.properties, so
            // `flutter run --release` and the sideload builds in build.yml keep
            // working on machines that do not hold the upload key — which is
            // every machine but CI. The fallback is silent here on purpose and
            // loud in release.yml instead, which refuses to upload a bundle
            // signed with a debug certificate.
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
