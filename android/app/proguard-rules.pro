# Flutter specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Camera and AndroidX
-keep class androidx.camera.** { *; }
-keep class androidx.lifecycle.** { *; }

# Barcode scanning (mobile_scanner)
-keep class com.google.android.gms.internal.mlkit_barcode_scanning.** { *; }

# Text recognition
-keep class com.google.mlkit.vision.** { *; }

# Keep custom application classes
-keep class com.anshintech.waretrackmini.** { *; }

# Keep Play Services classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Don't warn about missing Play Core classes (not using App Bundle)
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager

# Don't warn about unused text recognition languages
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

