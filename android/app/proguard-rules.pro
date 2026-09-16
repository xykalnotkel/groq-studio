# XyStudio AI — R8 / ProGuard (rilis)
# Flutter embedding + plugin + overlay Kotlin harus tetap utuh.

-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-dontwarn io.flutter.**
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugins.**

-keep class com.xyverse.xystudio.** { *; }
-keepclassmembers class com.xyverse.xystudio.** { *; }
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.appwidget.AppWidgetProvider
-keep public class * extends android.content.BroadcastReceiver

-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

-keep class org.json.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.app.** { *; }
-keep class androidx.core.content.** { *; }
-keep class androidx.startup.** { *; }

-keep class xyz.luan.audioplayers.** { *; }
-keep class com.tundralabs.fluttertts.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.share.** { *; }

-dontwarn kotlin.**
-dontwarn kotlinx.**
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}

-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,InnerClasses,EnclosingMethod
-renamesourcefileattribute SourceFile

-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
