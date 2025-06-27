# Flutter wrapper classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep all Dart classes (Flutter uses dynamic code)
-keep class com.example.smart_attendance_student.** { *; }

# Needed for Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Needed for Kotlin (especially coroutines, if used)
-dontwarn kotlin.**
-keep class kotlin.** { *; }

# Needed for Retrofit or OkHttp (if used)
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Needed for Gson (if used)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep all classes annotated with @Keep
-keep @androidx.annotation.Keep class * { *; }

# Prevent obfuscation of data classes and models (if serialized)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# If you use reflection, keep those classes
-keepattributes Signature
-keepattributes *Annotation*

# Keep FlutterActivity and FlutterApplication
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.android.** { *; }

# Don't strip out any classes used by Flutter plugins (generic rule)
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
