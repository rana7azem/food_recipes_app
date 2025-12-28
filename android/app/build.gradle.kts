plugins {
    // Gradle plugins
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.food_recipes_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        freeCompilerArgs += "-Xno-param-assertions"
    }

    defaultConfig {
        
        applicationId = "com.example.food_recipes_app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    bundle {
        language.enableSplit = false
    }
}

flutter {
    source = "../.."
}

// Copy APK to expected location after build
afterEvaluate {
    tasks.register<Copy>("copyApkToFlutter") {
        dependsOn("assembleDebug")
        from("$buildDir/outputs/apk/debug/app-debug.apk")
        into("../../build/app/outputs/flutter-apk")
        rename { "app.apk" }
    }
    
    tasks.named("assembleDebug") {
        finalizedBy("copyApkToFlutter")
    }
}

dependencies {
    // ✅ Firebase Core Dependencies
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-database")  // Realtime Database
}
