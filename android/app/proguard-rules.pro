# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# record plugin
-keep class com.llfbandit.record.** { *; }

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
