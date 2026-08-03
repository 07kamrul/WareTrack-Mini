import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load the release signing configuration from android/key.properties (git-ignored).
// When the file is absent (e.g. a fresh clone or `flutter run --release` on a dev
// machine without the keystore) we fall back to the debug signing config below.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKeystore) {
        keystorePropertiesFile.inputStream().use { stream -> load(stream) }
    }
}

// Flutter passes --dart-define values to Gradle as a comma-separated list of
// base64-encoded "KEY=VALUE" strings in the "dart-defines" project property.
fun dartDefine(key: String, defaultValue: String): String {
    val raw = project.findProperty("dart-defines") as? String ?: return defaultValue
    return raw.split(",")
        .mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            }.getOrNull()
        }
        .firstOrNull { it.startsWith("$key=") }
        ?.substringAfter("=")
        ?: defaultValue
}

// Defaults must match BaseApi / AppBuildConfig in lib/.
val appBuildApiEnv = dartDefine("API_ENV", "demo440")
val appBuildName = dartDefine("APP_NAME", "標準")
val appBuildVersion = dartDefine("APP_VERSION", "Ver 1.0")
val appBuildToday = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
// Every base API environment has a trial counterpart named "<base>Trial"
// (see ApiEnvironment in lib/core/api_services/api_environment.dart), so
// trial-ness is derived from that suffix rather than from one hard-coded name.
// Mirrors ApiEnvironmentX.isTrial in lib/.
val appBuildIsTrial = appBuildApiEnv.endsWith("Trial")
// A trial build shares the same app name (標準) as its base build, which made the
// two APKs indistinguishable in a file listing. Prefix "Trial" onto the app name
// portion for trial builds only; every base build keeps its existing filename.
val appBuildApkDisplayName = if (appBuildIsTrial) "Trial$appBuildName" else appBuildName
val appBuildApkFileName = "${appBuildToday}_${appBuildApiEnv}_${appBuildApkDisplayName}_${appBuildVersion}.apk"

android {
    namespace = "com.anshintech.waretrackmini"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Every base environment shares this applicationId so their release-signed
        // APKs update each other in place — except the trial builds, which
        // share their own applicationId so a trial installs side-by-side with a
        // real WareTrack Mini install instead of overwriting it.
        applicationId = if (appBuildIsTrial) {
            "com.anshintech.waretrackmini.trial"
        } else {
            "com.anshintech.waretrackmini"
        }
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AndroidManifest.xml references @string/app_name so the launcher
        // label can differ for trial builds without a Gradle flavor.
        resValue(
            "string",
            "app_name",
            if (appBuildIsTrial) "WareTrack Mini Trial" else "WareTrack Mini"
        )

        // Only include arm64-v8a architecture (most common on modern devices)
        // Removes x86, x86_64, armeabi-v7a to reduce APK size
        ndk {
            abiFilters.clear()
            abiFilters.add("arm64-v8a")
        }
    }

    signingConfigs {
        // A single shared release keystore signs every update-compatible build
        // (Standard 標準 and Customized カスタマイズ alike). Identical applicationId +
        // identical signing certificate = clean in-place update with data/SQLite
        // preserved. Only created when key.properties is present.
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sign release builds with the shared release keystore so all variants
            // update each other. Falls back to the debug key only when key.properties
            // is absent (local dev), which is NOT update-compatible across machines.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // Enable code minification with R8
            isMinifyEnabled = true
            
            // Enable resource shrinking
            isShrinkResources = true
            
            // Use proguard-android-optimize.txt as the default ProGuard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Bundle configuration for Play Store
    bundle {
        language {
            // Enable language splits on Play Store
            enableSplit = false
        }
    }

    // Exclude unwanted native libraries to reduce APK size
    // Keep only arm64-v8a (most common on modern Android devices)
    packagingOptions {
        excludes.add("lib/armeabi-v7a/**")
        excludes.add("lib/x86/**")
        excludes.add("lib/x86_64/**")
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.camera:camera-camera2:1.5.3")
    implementation("androidx.camera:camera-core:1.5.3")
    implementation("androidx.camera:camera-lifecycle:1.5.3")
    // Only Japanese text recognition is needed
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
}

flutter {
    source = "../.."
}

val createConfiguredReleaseApk by tasks.registering {
    group = "build"
    description = "Creates the Flutter release APK named from AppBuildConfig."

    doLast {
        val outputDirectory = project.layout.projectDirectory
            .dir("../../build/app/outputs/flutter-apk")
            .asFile
        val sourceApk = outputDirectory.resolve("app-release.apk")
        val targetApk = outputDirectory.resolve(appBuildApkFileName)

        if (!sourceApk.exists()) {
            error("Release APK was not found: ${sourceApk.path}")
        }

        sourceApk.copyTo(targetApk, overwrite = true)
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy(createConfiguredReleaseApk)
}

// External tooling (editor/AI assistant context notes) sometimes drops a
// CLAUDE.md file directly into res/values*/, which Android's resource merger
// rejects outright since every file there must be a values XML. Strip any
// stray non-XML file before each resource merge so the build is self-healing
// regardless of when that file reappears.
val stripStrayResourceValueFiles by tasks.registering {
    group = "build"
    description = "Removes stray non-XML files from res/values* before resource merging."

    doLast {
        val resDir = project.layout.projectDirectory.dir("src/main/res").asFile
        resDir.listFiles { file -> file.isDirectory && file.name.startsWith("values") }
            ?.forEach { valuesDir ->
                valuesDir.listFiles { file -> file.isFile && !file.name.endsWith(".xml") }
                    ?.forEach { it.delete() }
            }
    }
}

tasks.matching { it.name.startsWith("merge") && it.name.contains("Resources") }.configureEach {
    dependsOn(stripStrayResourceValueFiles)
}

// Launcher icon per environment: two tracked baselines live side by side —
// src/standardIcons/res (every non-trial environment) and src/trialIcons/res
// (generated via tool/generate_trial_branding_images.dart + flutter_launcher_icons,
// pointed at app_icon_trial.png / app_icon_foreground_trial.png).
// Copying the right set into src/main/res via a registered Gradle task
// wired with dependsOn(mergeResources) — AGP's task-graph validation
// flags this because other tasks (mapDebugSourceSetPaths,
// generateDebugResources, ...) read src/main/res without an explicit
// dependency on that task, i.e. an "implicit dependency" hazard.

copy {
    from(file(if (appBuildIsTrial) "src/trialIcons/res" else "src/standardIcons/res"))
    into(file("src/main/res"))
}

val restoreStandardLauncherIcons by tasks.registering(Copy::class) {
    group = "build"
    description = "Restores the standard launcher icon set into src/main/res after every build."

    from(file("src/standardIcons/res"))
    into(file("src/main/res"))
}

tasks.matching { it.name.startsWith("assemble") }.configureEach {
    finalizedBy(restoreStandardLauncherIcons)
}
