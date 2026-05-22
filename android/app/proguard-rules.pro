# TFLite Flutter — keep all TensorFlow Lite classes from R8 stripping
-keep class org.tensorflow.** { *; }
-keepclassmembers class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# FlatBuffers (TFLite dependency)
-keep class com.google.flatbuffers.** { *; }
-keepclassmembers class com.google.flatbuffers.** { *; }
-dontwarn com.google.flatbuffers.**

# tflite_flutter JNI bridge
-keep class com.tfliteflutter.** { *; }
-keepclassmembers class com.tfliteflutter.** { *; }
