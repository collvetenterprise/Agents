# Android Quickstart Sample (Kotlin)

This sample demonstrates how to build a basic Microsoft 365 agent for Android using Kotlin and the M365 Agents SDK.

## Features

- ✅ Basic agent initialization and configuration
- ✅ Activity handling and message processing
- ✅ Modern UI with Jetpack Compose
- ✅ GitHub Copilot integration ready
- ✅ MCP (Model Context Protocol) support
- ✅ Enterprise security features
- ✅ Offline capability
- ✅ Material Design 3

## Prerequisites

- Android Studio (Arctic Fox or newer)
- Android SDK (API Level 26+)
- JDK 11 or higher
- An Android device or emulator
- GitHub Copilot subscription (optional, for enhanced development)

## Project Structure

```
quickstart-kotlin/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/microsoft/m365agents/quickstart/
│   │   │   │   ├── MainActivity.kt          # Main entry point
│   │   │   │   ├── AgentActivity.kt         # Agent interaction UI
│   │   │   │   ├── AgentApplication.kt      # App initialization
│   │   │   │   ├── AgentViewModel.kt        # ViewModel for agent
│   │   │   │   └── models/
│   │   │   │       ├── AgentConfig.kt       # Configuration
│   │   │   │       └── AgentMessage.kt      # Message models
│   │   │   ├── res/
│   │   │   │   ├── values/
│   │   │   │   │   ├── strings.xml
│   │   │   │   │   └── themes.xml
│   │   │   │   └── layout/
│   │   │   │       └── activity_main.xml
│   │   │   └── AndroidManifest.xml
│   │   └── test/
│   │       └── java/com/microsoft/m365agents/quickstart/
│   │           └── AgentTest.kt
│   └── build.gradle.kts
├── gradle/
│   └── wrapper/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
└── README.md
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Microsoft/Agents.git
cd Agents/samples/android/quickstart-kotlin
```

### 2. Open in Android Studio

1. Launch Android Studio
2. Select "Open an Existing Project"
3. Navigate to the `quickstart-kotlin` directory
4. Click "OK"

### 3. Configure the Agent

Edit `app/src/main/java/com/microsoft/m365agents/quickstart/models/AgentConfig.kt`:

```kotlin
object AgentConfig {
    // Your Microsoft 365 tenant ID
    const val TENANT_ID = "your-tenant-id"
    
    // Your application client ID
    const val CLIENT_ID = "your-client-id"
    
    // Agent endpoint (optional for local development)
    const val AGENT_ENDPOINT = "https://your-agent-endpoint.com"
    
    // Enable GitHub Copilot integration
    const val ENABLE_COPILOT = true
    
    // Enable MCP support
    const val ENABLE_MCP = true
}
```

### 4. Sync Gradle

Click "Sync Now" when prompted, or run:

```bash
./gradlew sync
```

### 5. Run the App

Click the "Run" button in Android Studio, or:

```bash
./gradlew installDebug
adb shell am start -n com.microsoft.m365agents.quickstart/.MainActivity
```

## Key Components

### MainActivity.kt

The main entry point that sets up the Compose UI:

```kotlin
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            M365AgentTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    AgentScreen()
                }
            }
        }
    }
}
```

### AgentViewModel.kt

Manages agent state and interactions:

```kotlin
@HiltViewModel
class AgentViewModel @Inject constructor(
    private val agentClient: AgentClient,
    private val copilotIntegration: CopilotIntegration
) : ViewModel() {
    
    private val _messages = MutableStateFlow<List<AgentMessage>>(emptyList())
    val messages: StateFlow<List<AgentMessage>> = _messages.asStateFlow()
    
    fun sendMessage(text: String) {
        viewModelScope.launch {
            val response = agentClient.sendActivity(
                Activity.createMessageActivity(text)
            )
            _messages.update { it + AgentMessage(response.text, false) }
        }
    }
}
```

### AgentApplication.kt

Application-level initialization:

```kotlin
@HiltAndroidApp
class AgentApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize M365 Agents SDK
        M365Agents.initialize(
            context = this,
            config = M365AgentConfiguration.builder()
                .setTenantId(AgentConfig.TENANT_ID)
                .setClientId(AgentConfig.CLIENT_ID)
                .enableCopilot(AgentConfig.ENABLE_COPILOT)
                .enableMCP(AgentConfig.ENABLE_MCP)
                .build()
        )
    }
}
```

## GitHub Copilot Integration

This sample is optimized for use with GitHub Copilot:

### Using Copilot in Android Studio

1. Install GitHub Copilot plugin
2. Sign in with your GitHub account
3. Start coding - Copilot will provide suggestions

### Example Copilot Prompts

Try these prompts in Copilot Chat:

- "Add error handling to the agent message sending"
- "Create a retry mechanism for failed requests"
- "Implement offline message queueing"
- "Add unit tests for AgentViewModel"

### Copilot-Enhanced Features

```kotlin
// Ask Copilot: "Add rate limiting to message sending"
class AgentRateLimiter {
    private val messageDeque = ArrayDeque<Long>()
    private val maxMessagesPerMinute = 30
    
    fun canSendMessage(): Boolean {
        val now = System.currentTimeMillis()
        messageDeque.removeAll { it < now - 60_000 }
        return messageDeque.size < maxMessagesPerMinute
    }
    
    fun recordMessage() {
        messageDeque.add(System.currentTimeMillis())
    }
}
```

## MCP (Model Context Protocol) Integration

This sample includes MCP support for enhanced AI capabilities:

### Configuring MCP

```kotlin
val mcpConfig = MCPConfiguration.builder()
    .setServerUrl("http://localhost:3000")
    .setCapabilities(listOf(
        "android-sdk",
        "github-copilot",
        "code-generation"
    ))
    .build()

agentClient.configureMCP(mcpConfig)
```

### Using MCP Context

```kotlin
// MCP provides context-aware responses
viewModelScope.launch {
    val context = mcpClient.getContext(
        type = ContextType.CODE,
        scope = "current-file"
    )
    
    val response = agentClient.sendActivityWithContext(
        activity = activity,
        context = context
    )
}
```

## Testing

### Run Unit Tests

```bash
./gradlew test
```

### Run Instrumentation Tests

```bash
./gradlew connectedAndroidTest
```

### Example Test

```kotlin
@Test
fun testAgentMessageSending() = runTest {
    val viewModel = AgentViewModel(mockAgentClient, mockCopilot)
    
    viewModel.sendMessage("Hello Agent")
    
    advanceUntilIdle()
    
    val messages = viewModel.messages.value
    assertTrue(messages.isNotEmpty())
    assertEquals("Hello Agent", messages.first().text)
}
```

## Building for Release

### 1. Generate Signing Key

```bash
keytool -genkey -v -keystore release.keystore -alias release \
    -keyalg RSA -keysize 2048 -validity 10000
```

### 2. Configure Signing

Create `keystore.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=release
storeFile=/path/to/release.keystore
```

### 3. Build Release APK

```bash
./gradlew assembleRelease
```

The APK will be in `app/build/outputs/apk/release/`

## Performance Optimization

### Memory Management

```kotlin
class AgentCache {
    private val cache = LruCache<String, AgentResponse>(
        maxSize = Runtime.getRuntime().maxMemory().toInt() / 8
    )
    
    fun get(key: String): AgentResponse? = cache.get(key)
    fun put(key: String, value: AgentResponse) = cache.put(key, value)
}
```

### Network Optimization

```kotlin
val retrofit = Retrofit.Builder()
    .baseUrl(AgentConfig.AGENT_ENDPOINT)
    .client(
        OkHttpClient.Builder()
            .cache(Cache(context.cacheDir, 10 * 1024 * 1024))
            .addInterceptor(HttpLoggingInterceptor())
            .build()
    )
    .addConverterFactory(GsonConverterFactory.create())
    .build()
```

### Battery Optimization

```kotlin
// Use WorkManager for background tasks
class AgentSyncWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {
    
    override suspend fun doWork(): Result {
        return try {
            agentClient.syncMessages()
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
```

## Enterprise Features

### Security

```kotlin
// Implement certificate pinning
val certificatePinner = CertificatePinner.Builder()
    .add("your-domain.com", "sha256/AAAAAAAAAA...")
    .build()

val client = OkHttpClient.Builder()
    .certificatePinner(certificatePinner)
    .build()
```

### Multi-Tenant Support

```kotlin
class TenantManager {
    fun switchTenant(tenantId: String) {
        val newConfig = M365AgentConfiguration.builder()
            .setTenantId(tenantId)
            .setClientId(AgentConfig.CLIENT_ID)
            .build()
            
        M365Agents.reconfigure(newConfig)
    }
}
```

## Troubleshooting

### Build Errors

If you encounter build errors:

```bash
./gradlew clean
./gradlew build --refresh-dependencies
```

### Runtime Crashes

Enable verbose logging:

```kotlin
if (BuildConfig.DEBUG) {
    M365Agents.setLogLevel(LogLevel.VERBOSE)
}
```

### Network Issues

Check your network configuration and ensure the agent endpoint is accessible.

## Next Steps

- Explore the [enterprise-agent](../enterprise-agent) sample for advanced features
- Check out [mcp-server](../mcp-server) for MCP implementation details
- Review [copilot-integration](../copilot-integration) for Copilot best practices

## Resources

- [M365 Agents SDK Documentation](https://aka.ms/M365-Agents-SDK-Docs)
- [Android Developer Guide](https://developer.android.com/guide)
- [Kotlin Documentation](https://kotlinlang.org/docs/home.html)
- [Jetpack Compose Guide](https://developer.android.com/jetpack/compose)
- [GitHub Copilot for Android Studio](https://docs.github.com/en/copilot)

## License

This sample is provided under the MIT License. See [LICENSE](../../../LICENSE) for details.
