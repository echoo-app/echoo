# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Encrypt library
-keep class com.tozny.crypto.** { *; }

# Http & Dio
-keep class io.flutter.plugin.editing.** { *; }
-dontwarn org.codehaus.mojo.animal_sniffer.*

# Ignore missing Play Store classes
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
