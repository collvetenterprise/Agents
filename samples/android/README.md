# Android Samples for Microsoft 365 Agents SDK

This directory contains Android-specific samples demonstrating how to build intelligent agents for Android devices using the Microsoft 365 Agents SDK.

## Available Samples

| Sample | Description | Technology |
|--------|-------------|------------|
| [quickstart-kotlin](./quickstart-kotlin) | Basic Android agent in Kotlin | Kotlin, Android SDK |
| [quickstart-react-native](./quickstart-react-native) | Cross-platform agent with React Native | TypeScript, React Native |
| [quickstart-maui](./quickstart-maui) | .NET MAUI Android agent | C#, .NET MAUI |
| [copilot-integration](./copilot-integration) | GitHub Copilot integration demo | Kotlin, Copilot API |
| [mcp-server](./mcp-server) | MCP server implementation for Android | TypeScript, MCP |
| [enterprise-agent](./enterprise-agent) | Enterprise-grade agent with full features | Kotlin, Enterprise SDK |

## Prerequisites

Before running any sample, ensure you have:

1. **Android Studio** (Arctic Fox or newer)
2. **Android SDK** (API Level 26+)
3. **Java Development Kit (JDK)** 11+
4. **Node.js** 18+ (for React Native samples)
5. **.NET SDK** 8.0+ (for MAUI samples)

For detailed setup instructions, see [ANDROID_SETUP.md](../../ANDROID_SETUP.md)

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/Microsoft/Agents.git
cd Agents/samples/android
```

### 2. Choose a Sample

Navigate to the sample you want to try:

```bash
cd quickstart-kotlin
```

### 3. Run the Sample

For Kotlin/Android:
```bash
./gradlew installDebug
adb shell am start -n com.microsoft.m365agents.quickstart/.MainActivity
```

For React Native:
```bash
cd quickstart-react-native
npm install
npx react-native run-android
```

For .NET MAUI:
```bash
cd quickstart-maui
dotnet build -t:Run -f net8.0-android
```

## Sample Details

### Quickstart (Kotlin)

The Kotlin quickstart demonstrates:
- Basic agent initialization
- Activity handling
- Message processing
- UI integration with Jetpack Compose

**File Structure:**
```
quickstart-kotlin/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/microsoft/m365agents/
│   │   │   │   ├── MainActivity.kt
│   │   │   │   ├── AgentActivity.kt
│   │   │   │   └── AgentApplication.kt
│   │   │   ├── res/
│   │   │   └── AndroidManifest.xml
│   │   └── test/
│   └── build.gradle.kts
├── build.gradle.kts
└── README.md
```

### Quickstart (React Native)

Cross-platform sample showing:
- React Native component integration
- TypeScript agent implementation
- Native module bridging
- Cross-platform UI components

### Quickstart (.NET MAUI)

.NET MAUI sample featuring:
- C# agent development
- XAML UI design
- Platform-specific implementations
- Shared code patterns

### GitHub Copilot Integration

Demonstrates:
- Copilot API integration
- Code completion in Android
- AI-assisted development
- Context-aware suggestions

### MCP Server

Shows how to:
- Set up MCP server on Android
- Handle protocol messages
- Integrate with agent runtime
- Enable context sharing

### Enterprise Agent

Full-featured enterprise sample:
- Multi-tenant support
- Advanced security (encryption, auth)
- Scalability patterns
- Offline capabilities
- Cloud synchronization
- Analytics and telemetry

## Building for Production

### Release Build

```bash
# Kotlin/Android
./gradlew assembleRelease

# React Native
cd android && ./gradlew assembleRelease

# .NET MAUI
dotnet publish -f net8.0-android -c Release
```

### Code Signing

Configure signing in `app/build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("path/to/keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

## Testing

### Unit Tests

```bash
./gradlew test
```

### Instrumentation Tests

```bash
./gradlew connectedAndroidTest
```

### UI Tests (Espresso)

```kotlin
@Test
fun testAgentInteraction() {
    onView(withId(R.id.agent_input))
        .perform(typeText("Hello Agent"))
    
    onView(withId(R.id.send_button))
        .perform(click())
    
    onView(withId(R.id.agent_response))
        .check(matches(isDisplayed()))
}
```

## Debugging

### Using Android Studio Debugger

1. Set breakpoints in your code
2. Run in debug mode: Run → Debug 'app'
3. Use Logcat for logging

### Enable Verbose Logging

```kotlin
// In your Application class
if (BuildConfig.DEBUG) {
    AgentConfig.setLogLevel(LogLevel.VERBOSE)
}
```

### Using GitHub Copilot for Debugging

Ask Copilot in Android Studio:
- "Why is my agent not responding?"
- "Explain this crash log"
- "Suggest performance improvements"

## Common Issues

### Gradle Build Failures

```bash
# Clean and rebuild
./gradlew clean
./gradlew build --refresh-dependencies

# Clear Gradle cache
rm -rf ~/.gradle/caches/
```

### Android SDK Not Found

```bash
# Set ANDROID_HOME
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### ProGuard Issues

Add to `proguard-rules.pro`:
```proguard
-keep class com.microsoft.m365agents.** { *; }
-keepclassmembers class * {
    @com.microsoft.m365agents.annotations.* <methods>;
}
```

## Performance Optimization

### Memory

```kotlin
// Implement memory-efficient patterns
class AgentViewModel : ViewModel() {
    private val agentClient = AgentClientFactory.create()
    
    override fun onCleared() {
        super.onCleared()
        agentClient.dispose()
    }
}
```

### Network

```kotlin
// Use efficient networking
val client = OkHttpClient.Builder()
    .cache(Cache(context.cacheDir, 10 * 1024 * 1024)) // 10 MB
    .connectTimeout(15, TimeUnit.SECONDS)
    .build()
```

### Battery

```kotlin
// Implement WorkManager for background tasks
val workRequest = PeriodicWorkRequestBuilder<AgentSyncWorker>(
    15, TimeUnit.MINUTES
).setConstraints(
    Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .setRequiresBatteryNotLow(true)
        .build()
).build()

WorkManager.getInstance(context).enqueue(workRequest)
```

## Contributing

To contribute a new Android sample:

1. Create a new directory under `samples/android/`
2. Include a detailed README.md
3. Follow the existing sample structure
4. Add necessary configuration files
5. Include tests
6. Update this README with your sample

## Resources

- [Android Developer Documentation](https://developer.android.com/docs)
- [Kotlin Documentation](https://kotlinlang.org/docs/home.html)
- [React Native Documentation](https://reactnative.dev/docs/getting-started)
- [.NET MAUI Documentation](https://learn.microsoft.com/en-us/dotnet/maui/)
- [M365 Agents SDK Documentation](https://aka.ms/M365-Agents-SDK-Docs)

## License

All samples are provided under the MIT License. See [LICENSE](../../LICENSE) file for details.

## Support

For questions and issues:
- Open an issue in the main repository
- Check the [ANDROID_SETUP.md](../../ANDROID_SETUP.md) guide
- Visit the community discussions
