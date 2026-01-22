# ProGuard/R8 rules for the app.
# Keep ML Kit Pose Detection classes from being stripped
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Keep TensorFlow Lite classes (used by ML Kit)
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep model classes
-keepclassmembers class * {
    @com.google.mlkit.common.model.DownloadConditions *;
}

# Preserve annotations
-keepattributes *Annotation*

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
