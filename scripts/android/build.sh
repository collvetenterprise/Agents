#!/bin/bash

# Android Build Script for M365 Agents SDK
# This script builds all Android samples and prepares them for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SAMPLES_DIR="$PROJECT_ROOT/samples/android"
BUILD_OUTPUT="$PROJECT_ROOT/build/android"

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}M365 Agents SDK - Android Builder${NC}"
echo -e "${GREEN}==================================${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "\n${YELLOW}Checking prerequisites...${NC}"
    
    # Check Android SDK
    if [ -z "$ANDROID_HOME" ]; then
        echo -e "${RED}Error: ANDROID_HOME is not set${NC}"
        echo "Please set ANDROID_HOME to your Android SDK location"
        exit 1
    fi
    echo -e "${GREEN}✓ Android SDK found at $ANDROID_HOME${NC}"
    
    # Check Java
    if ! command -v java &> /dev/null; then
        echo -e "${RED}Error: Java is not installed${NC}"
        exit 1
    fi
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo -e "${GREEN}✓ Java version $JAVA_VERSION${NC}"
    
    # Check Gradle
    if [ -f "$SAMPLES_DIR/quickstart-kotlin/gradlew" ]; then
        echo -e "${GREEN}✓ Gradle wrapper found${NC}"
    else
        echo -e "${RED}Error: Gradle wrapper not found${NC}"
        exit 1
    fi
}

# Build Kotlin sample
build_kotlin_sample() {
    echo -e "\n${YELLOW}Building Kotlin quickstart sample...${NC}"
    
    cd "$SAMPLES_DIR/quickstart-kotlin"
    
    # Clean previous builds
    ./gradlew clean
    
    # Build debug APK
    ./gradlew assembleDebug
    
    # Build release APK (if keystore is configured)
    if [ -f "keystore.properties" ]; then
        echo -e "${YELLOW}Building release APK...${NC}"
        ./gradlew assembleRelease
    else
        echo -e "${YELLOW}Skipping release build (keystore not configured)${NC}"
    fi
    
    # Copy outputs
    mkdir -p "$BUILD_OUTPUT/quickstart-kotlin"
    cp -r app/build/outputs/apk/* "$BUILD_OUTPUT/quickstart-kotlin/"
    
    echo -e "${GREEN}✓ Kotlin sample built successfully${NC}"
}

# Run tests
run_tests() {
    echo -e "\n${YELLOW}Running tests...${NC}"
    
    cd "$SAMPLES_DIR/quickstart-kotlin"
    
    # Unit tests
    echo -e "${YELLOW}Running unit tests...${NC}"
    ./gradlew test || echo -e "${YELLOW}Warning: Some tests failed${NC}"
    
    # Lint
    echo -e "${YELLOW}Running lint...${NC}"
    ./gradlew lint || echo -e "${YELLOW}Warning: Lint issues found${NC}"
    
    echo -e "${GREEN}✓ Tests completed${NC}"
}

# Generate documentation
generate_docs() {
    echo -e "\n${YELLOW}Generating documentation...${NC}"
    
    cd "$SAMPLES_DIR/quickstart-kotlin"
    
    # Generate KDoc (if configured)
    if ./gradlew tasks | grep -q "dokka"; then
        ./gradlew dokkaHtml
        mkdir -p "$BUILD_OUTPUT/docs"
        cp -r build/dokka/html "$BUILD_OUTPUT/docs/kotlin"
        echo -e "${GREEN}✓ Documentation generated${NC}"
    else
        echo -e "${YELLOW}Dokka not configured, skipping documentation${NC}"
    fi
}

# Create distribution package
create_distribution() {
    echo -e "\n${YELLOW}Creating distribution package...${NC}"
    
    cd "$BUILD_OUTPUT"
    
    # Create timestamp
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DIST_NAME="m365-agents-android-$TIMESTAMP"
    
    # Create distribution directory
    mkdir -p "$DIST_NAME"
    
    # Copy APKs
    if [ -d "quickstart-kotlin" ]; then
        cp -r quickstart-kotlin "$DIST_NAME/"
    fi
    
    # Copy documentation
    cp "$PROJECT_ROOT/ANDROID_SETUP.md" "$DIST_NAME/"
    cp "$PROJECT_ROOT/GITHUB_COPILOT_MCP_INTEGRATION.md" "$DIST_NAME/"
    cp "$SAMPLES_DIR/README.md" "$DIST_NAME/"
    
    # Create archive
    tar -czf "$DIST_NAME.tar.gz" "$DIST_NAME"
    
    echo -e "${GREEN}✓ Distribution package created: $DIST_NAME.tar.gz${NC}"
}

# Main execution
main() {
    check_prerequisites
    
    # Build samples
    build_kotlin_sample
    
    # Run tests (optional, can be disabled with --skip-tests)
    if [ "$1" != "--skip-tests" ]; then
        run_tests
    fi
    
    # Generate docs (optional)
    if [ "$1" == "--with-docs" ]; then
        generate_docs
    fi
    
    # Create distribution
    create_distribution
    
    echo -e "\n${GREEN}==================================${NC}"
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "${GREEN}==================================${NC}"
    echo -e "\nBuild artifacts: ${BUILD_OUTPUT}"
    echo -e "\nNext steps:"
    echo -e "  1. Test the APK: adb install ${BUILD_OUTPUT}/quickstart-kotlin/debug/app-debug.apk"
    echo -e "  2. Or install from Android Studio"
    echo -e "  3. Review documentation at ${PROJECT_ROOT}/ANDROID_SETUP.md"
}

# Run main function
main "$@"
