plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.app_weather"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // 锁定 GroMore(mediation-sdk) 到 7.7.1.6，并排除旧 gromore_ads 插件残留的
    // mediation-auto-adapter:1.0.3（它定义了冲突的 TTAdNative，导致 onRewardVideoCached
    // 有参/无参签名矛盾）。强制全局排除该孤儿 artifact。
    configurations.all {
        resolutionStrategy {
            force("com.pangle.cn:mediation-sdk:7.7.1.6")
            exclude(group = "com.pangle.cn", module = "mediation-auto-adapter")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.app_weather"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // GroMore(穿山甲聚合) 要求 minSdk >= 24
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // GroMore 应用 ID 占位符（替换为你申请的真实 AppID）。
        manifestPlaceholders["GROMORE_APPID"] = "5870813"
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // GroMore(mediation-sdk) 的 fat-aar 内部引用了 okhttp3/bytedance-keva/
            // component-annotation 等类，R8 严格检查会报 Missing classes 失败。
            // 关闭 minify 绕过（官方接入亦常如此），代价是 APK 略大、无混淆。
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 官方 GroMore(穿山甲聚合) Android SDK 7.7.1.6（直接依赖，对齐官方版本）
    implementation("com.pangle.cn:mediation-sdk:7.7.1.6")
}
