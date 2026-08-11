# ======= Suppress warnings for Play Core (not used but referenced by Flutter) =======
-dontwarn com.google.android.play.core.**

# ======= Flutter Plugins =======
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# ======= Firebase =======
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ======= Google Cast Framework =======
-keep class com.google.android.gms.cast.** { *; }
-keep class com.google.android.gms.cast.framework.** { *; }
-keep class androidx.mediarouter.** { *; }
-keep class com.poltroplay.CastOptionsProvider { *; }

# ======= Firebase Messaging (FCM) - CRÍTICO para notificações em Release =======
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# ======= Flutter Local Notifications - CRÍTICO para exibir notificações =======
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ======= AndroidX =======
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.startup.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# ======= Google Mobile Ads (AdMob) =======
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.ads.mediation.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }

# Keep JavaScript interfaces and WebViews (Required for rendering AdMob HTML5 creatives)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class android.webkit.JavascriptInterface { *; }
-keep class android.webkit.WebView { *; }

# Preserve annotations and signatures required by AdMob reflection
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions
-dontwarn com.google.android.gms.ads.**

# ======= Prevent stripping of Serializable/Parcelable =======
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ======= Keep entry points for background execution =======
-keep class * extends io.flutter.embedding.engine.FlutterEngine { *; }
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }

