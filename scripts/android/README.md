# Android Build and Deployment Scripts

This directory contains automation scripts for building and deploying M365 Agents SDK Android samples.

## Scripts

### build.sh

Builds all Android samples and creates distribution packages.

**Usage:**
```bash
./build.sh [options]

Options:
  --skip-tests    Skip running tests
  --with-docs     Generate documentation
```

**Examples:**
```bash
# Standard build with tests
./build.sh

# Build without tests
./build.sh --skip-tests

# Build with documentation
./build.sh --with-docs
```

**Output:**
- Debug and Release APKs
- Test reports
- Lint reports
- Distribution package (tar.gz)

### deploy.sh

Deploys Android samples to various targets.

**Usage:**
```bash
./deploy.sh [target] [options]

Targets:
  device      Deploy to connected Android device
  emulator    Deploy to running emulator
  store       Prepare for Google Play Store
  enterprise  Prepare for enterprise distribution
  ci          CI/CD deployment

Options:
  --sample <name>    Specify sample to deploy (default: quickstart-kotlin)
  --variant <type>   Build variant (debug|release) (default: debug)
```

**Examples:**
```bash
# Deploy debug to connected device
./deploy.sh device

# Deploy release to device
./deploy.sh device --variant release

# Deploy to emulator
./deploy.sh emulator

# Prepare for Play Store
./deploy.sh store

# Enterprise distribution
./deploy.sh enterprise

# CI/CD deployment
./deploy.sh ci
```

## Prerequisites

### Required Tools

1. **Android SDK**: Set `ANDROID_HOME` environment variable
   ```bash
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

2. **Java JDK**: Version 11 or higher
   ```bash
   java -version
   ```

3. **ADB** (Android Debug Bridge): For device deployment
   ```bash
   adb version
   ```

4. **Gradle**: Included as wrapper in samples

### Optional Tools

- **Emulator**: For testing without physical device
- **Keystore**: For release builds (see [Signing Configuration](#signing-configuration))

## Signing Configuration

For release builds, create `keystore.properties` in the sample directory:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=/path/to/your/keystore.jks
```

Generate a keystore:
```bash
keytool -genkey -v -keystore release.keystore -alias release \
    -keyalg RSA -keysize 2048 -validity 10000
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/android.yml`:

```yaml
name: Android Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 11
      uses: actions/setup-java@v3
      with:
        java-version: '11'
        distribution: 'temurin'
    
    - name: Build with Gradle
      run: |
        cd scripts/android
        ./build.sh --skip-tests
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: android-artifacts
        path: build/android/
```

### Azure Pipelines

Create `azure-pipelines.yml`:

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: JavaToolInstaller@0
  inputs:
    versionSpec: '11'
    jdkArchitectureOption: 'x64'
    jdkSourceOption: 'PreInstalled'

- script: |
    cd scripts/android
    chmod +x build.sh
    ./build.sh
  displayName: 'Build Android Samples'

- task: PublishBuildArtifacts@1
  inputs:
    pathToPublish: 'build/android'
    artifactName: 'android-artifacts'
```

## Troubleshooting

### Build Issues

**Problem**: Gradle build fails
```bash
# Clean and rebuild
cd samples/android/quickstart-kotlin
./gradlew clean
./gradlew build --refresh-dependencies
```

**Problem**: SDK not found
```bash
# Check ANDROID_HOME
echo $ANDROID_HOME

# Set if not configured
export ANDROID_HOME=$HOME/Android/Sdk
```

### Deployment Issues

**Problem**: Device not detected
```bash
# Check connected devices
adb devices

# Restart ADB server
adb kill-server
adb start-server
```

**Problem**: Permission denied on device
```bash
# Enable USB debugging on device
# Settings > Developer options > USB debugging

# Grant USB debugging permission when prompted
```

## Best Practices

1. **Clean Builds**: Run clean before important builds
   ```bash
   ./build.sh --skip-tests
   ```

2. **Test Before Deploy**: Always test debug builds first
   ```bash
   ./deploy.sh device
   # Test the app
   ./deploy.sh device --variant release
   ```

3. **Version Control**: Don't commit:
   - `keystore.properties`
   - `*.jks` files
   - `local.properties`

4. **Security**: Keep signing keys secure
   - Use environment variables in CI/CD
   - Rotate keys periodically
   - Use separate keys for debug/release

## Environment Variables

Useful environment variables for scripts:

```bash
# Android SDK location
export ANDROID_HOME=/path/to/android/sdk

# Java home
export JAVA_HOME=/path/to/java

# Keystore password (for CI/CD)
export KEYSTORE_PASSWORD=your-password
export KEY_PASSWORD=your-key-password

# Build configuration
export BUILD_VARIANT=release
export SAMPLE_NAME=quickstart-kotlin
```

## Advanced Usage

### Custom Build Configuration

Create a custom build configuration file `build.config`:

```bash
# Build configuration
SAMPLE_NAME="quickstart-kotlin"
BUILD_VARIANT="release"
SKIP_TESTS="false"
GENERATE_DOCS="true"
OUTPUT_DIR="custom-output"
```

Use with scripts:
```bash
source build.config
./build.sh
```

### Parallel Builds

Build multiple samples in parallel:

```bash
# Build all samples
for sample in quickstart-kotlin copilot-integration enterprise-agent; do
    (cd "$sample" && ./gradlew assembleDebug) &
done
wait
```

### Automated Testing

Run comprehensive tests:

```bash
cd samples/android/quickstart-kotlin

# Unit tests
./gradlew test

# Instrumentation tests (requires device/emulator)
./gradlew connectedAndroidTest

# Lint
./gradlew lint

# All checks
./gradlew check
```

## Support

For issues with these scripts:
1. Check prerequisites are installed
2. Review error messages carefully
3. Consult sample-specific README files
4. Open an issue in the repository

## License

These scripts are provided under the MIT License.
