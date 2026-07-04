# Workaround for google_mobile_ads 9.x startup crash in release mode:
# WorkManager classes stripped by R8 break androidx.startup.InitializationProvider.
# See https://github.com/googleads/googleads-mobile-flutter/issues/1444
-keep class androidx.work.impl.** { *; }
-dontwarn androidx.work.impl.**
