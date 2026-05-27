# Supabase / ktor / kotlinx.serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
# Keep @Serializable model classes and their serializers
-keep,includedescriptorclasses class com.loucesario.seek.**$$serializer { *; }
-keepclassmembers class com.loucesario.seek.** {
    *** Companion;
}
-keepclasseswithmembers class com.loucesario.seek.** {
    kotlinx.serialization.KSerializer serializer(...);
}
