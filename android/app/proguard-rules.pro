# Keep TensorFlow Lite GPU delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-keepclassmembers class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

