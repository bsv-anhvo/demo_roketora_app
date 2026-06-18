# FFmpegKit registers JNI methods at load time; R8 must not rename/strip them.
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
