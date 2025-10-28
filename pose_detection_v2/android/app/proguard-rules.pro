# Flutter 최적화 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Camera 플러그인 최적화
-keep class io.flutter.plugins.camera.** { *; }

# HTTP 플러그인 최적화  
-keep class io.flutter.plugins.http.** { *; }

# Permission Handler 최적화
-keep class com.baseflow.permissionhandler.** { *; }

# 일반적인 최적화 규칙
-dontwarn java.lang.invoke.StringConcatFactory
-dontwarn java.lang.invoke.MethodHandles
-dontwarn java.lang.invoke.MethodHandles$Lookup

# 메모리 최적화
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
