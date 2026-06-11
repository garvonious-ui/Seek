import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
}

// Load release signing config from ../keystore.properties (gitignored).
// Falls back to null when the file is missing so debug builds and CI without
// the keystore still succeed; release will then fail loudly at signing time.
val keystoreProps: Properties? = run {
    val f = rootProject.file("keystore.properties")
    if (f.exists()) Properties().apply { f.inputStream().use { load(it) } } else null
}

android {
    namespace = "com.loucesario.seek"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.loucesario.seek"
        minSdk = 26
        targetSdk = 35
        versionCode = 2
        versionName = "1.0.0"

        // Same Supabase project as iOS. The anon key is public by design
        // (ships in the iOS bundle and the landing page) and is protected by RLS.
        buildConfigField("String", "SUPABASE_URL", "\"https://hxfiaowayrhuhzhhbaix.supabase.co\"")
        buildConfigField(
            "String",
            "SUPABASE_ANON_KEY",
            "\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4Zmlhb3dheXJodWh6aGhiYWl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NzI2NDksImV4cCI6MjA5MTE0ODY0OX0.tsf-R505B_RJvO8qDI0WMlcLzyPD7xrZK8ll4SbFK2Y\""
        )

        vectorDrawables { useSupportLibrary = true }
    }

    signingConfigs {
        if (keystoreProps != null) {
            create("release") {
                storeFile = rootProject.file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            if (keystoreProps != null) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    buildFeatures {
        compose = true
        buildConfig = true
    }
    packaging {
        resources { excludes += "/META-INF/{AL2.0,LGPL2.1}" }
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.activity.compose)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material.icons.extended)
    implementation(libs.androidx.ui.text.google.fonts)
    implementation(libs.androidx.navigation.compose)
    debugImplementation(libs.androidx.ui.tooling)

    // Room
    implementation(libs.androidx.room.runtime)
    implementation(libs.androidx.room.ktx)
    ksp(libs.androidx.room.compiler)

    // DataStore (auth-state flags, preferences)
    implementation(libs.androidx.datastore.preferences)

    // Supabase
    implementation(platform(libs.supabase.bom))
    implementation(libs.supabase.postgrest)
    implementation(libs.supabase.auth)
    implementation(libs.supabase.functions)
    implementation(libs.ktor.client.okhttp)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)

    // Auth: Google Sign-In (primary on Android) + Apple via web flow
    implementation(libs.androidx.credentials)
    implementation(libs.androidx.credentials.play.services.auth)
    implementation(libs.googleid)
    implementation(libs.androidx.browser)

    implementation(libs.coil.compose)
}
