#!/bin/bash

# Android Deployment Script for M365 Agents SDK
# This script deploys Android samples to various targets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SAMPLES_DIR="$PROJECT_ROOT/samples/android"

echo -e "${GREEN}===================================${NC}"
echo -e "${GREEN}M365 Agents SDK - Android Deployer${NC}"
echo -e "${GREEN}===================================${NC}"

# Show usage
show_usage() {
    echo -e "\n${BLUE}Usage:${NC}"
    echo -e "  $0 [target] [options]"
    echo -e "\n${BLUE}Targets:${NC}"
    echo -e "  device      Deploy to connected Android device"
    echo -e "  emulator    Deploy to running emulator"
    echo -e "  store       Prepare for Google Play Store"
    echo -e "  enterprise  Prepare for enterprise distribution"
    echo -e "  ci          CI/CD deployment"
    echo -e "\n${BLUE}Options:${NC}"
    echo -e "  --sample <name>    Specify sample to deploy (default: quickstart-kotlin)"
    echo -e "  --variant <type>   Build variant (debug|release) (default: debug)"
    echo -e "  --help             Show this help message"
    echo -e "\n${BLUE}Examples:${NC}"
    echo -e "  $0 device                           # Deploy debug to device"
    echo -e "  $0 device --variant release         # Deploy release to device"
    echo -e "  $0 emulator --sample quickstart     # Deploy to emulator"
    echo -e "  $0 store                            # Prepare for Play Store"
}

# Check prerequisites
check_prerequisites() {
    echo -e "\n${YELLOW}Checking prerequisites...${NC}"
    
    # Check ADB
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}Error: adb is not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ ADB found${NC}"
}

# Deploy to device
deploy_to_device() {
    local sample=$1
    local variant=$2
    
    echo -e "\n${YELLOW}Deploying to connected device...${NC}"
    
    # Check if device is connected
    DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        echo -e "${RED}Error: No device connected${NC}"
        echo "Please connect an Android device and enable USB debugging"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Device connected${NC}"
    
    # Build if needed
    cd "$SAMPLES_DIR/$sample"
    
    if [ "$variant" == "release" ]; then
        ./gradlew assembleRelease
        APK_PATH="app/build/outputs/apk/release/app-release.apk"
    else
        ./gradlew assembleDebug
        APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    fi
    
    # Install APK
    echo -e "${YELLOW}Installing APK...${NC}"
    adb install -r "$APK_PATH"
    
    # Get package name from APK using aapt (more reliable)
    AAPT_PATH="$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | sort -V | tail -n 1)/aapt"
    if [ -f "$AAPT_PATH" ]; then
        PACKAGE_NAME=$($AAPT_PATH dump badging "$APK_PATH" | grep package: | awk '{print $2}' | sed s/name=//g | sed s/\'//g)
    else
        # Fallback to grep/sed method with more robust pattern
        PACKAGE_NAME=$(grep -E 'applicationId\s*=\s*"[^"]*"' app/build.gradle.kts | sed -E 's/.*applicationId\s*=\s*"([^"]*)".*/\1/' || echo "com.microsoft.m365agents.quickstart")
    fi
    
    echo -e "${GREEN}✓ App installed successfully${NC}"
    echo -e "\n${BLUE}To launch the app:${NC}"
    echo -e "  adb shell am start -n $PACKAGE_NAME/.MainActivity"
}

# Deploy to emulator
deploy_to_emulator() {
    local sample=$1
    local variant=$2
    
    echo -e "\n${YELLOW}Deploying to emulator...${NC}"
    
    # Check if emulator is running
    EMULATOR_COUNT=$(adb devices | grep -c "emulator" || true)
    if [ "$EMULATOR_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}No emulator running. Starting emulator...${NC}"
        
        # List available AVDs
        AVDS=$(emulator -list-avds)
        if [ -z "$AVDS" ]; then
            echo -e "${RED}Error: No AVDs found${NC}"
            echo "Please create an AVD using Android Studio"
            exit 1
        fi
        
        # Start first AVD
        FIRST_AVD=$(echo "$AVDS" | head -n 1)
        echo -e "${YELLOW}Starting AVD: $FIRST_AVD${NC}"
        emulator -avd "$FIRST_AVD" -no-snapshot-load &
        
        # Wait for emulator to fully boot
        echo -e "${YELLOW}Waiting for emulator to boot completely...${NC}"
        adb wait-for-device
        
        # Poll until boot is complete (more reliable than fixed sleep)
        BOOT_COMPLETE=""
        TIMEOUT=120
        ELAPSED=0
        while [ "$BOOT_COMPLETE" != "1" ] && [ $ELAPSED -lt $TIMEOUT ]; do
            BOOT_COMPLETE=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
            if [ "$BOOT_COMPLETE" != "1" ]; then
                sleep 2
                ELAPSED=$((ELAPSED + 2))
                echo -ne "\r${YELLOW}Booting... ${ELAPSED}s${NC}"
            fi
        done
        echo ""
        
        if [ "$BOOT_COMPLETE" != "1" ]; then
            echo -e "${RED}Warning: Emulator boot timeout. Proceeding anyway...${NC}"
        else
            echo -e "${GREEN}✓ Emulator fully booted${NC}"
        fi
    fi
    
    echo -e "${GREEN}✓ Emulator ready${NC}"
    
    # Deploy to emulator
    deploy_to_device "$sample" "$variant"
}

# Prepare for Google Play Store
prepare_for_store() {
    local sample=$1
    
    echo -e "\n${YELLOW}Preparing for Google Play Store...${NC}"
    
    cd "$SAMPLES_DIR/$sample"
    
    # Check for keystore
    if [ ! -f "keystore.properties" ]; then
        echo -e "${RED}Error: keystore.properties not found${NC}"
        echo "Please configure your release keystore"
        exit 1
    fi
    
    # Build release AAB (Android App Bundle)
    echo -e "${YELLOW}Building release AAB...${NC}"
    ./gradlew bundleRelease
    
    AAB_PATH="app/build/outputs/bundle/release/app-release.aab"
    
    if [ -f "$AAB_PATH" ]; then
        echo -e "${GREEN}✓ AAB built successfully${NC}"
        echo -e "\n${BLUE}AAB location:${NC} $AAB_PATH"
        echo -e "\n${BLUE}Next steps:${NC}"
        echo -e "  1. Test the AAB with bundletool"
        echo -e "  2. Upload to Google Play Console"
        echo -e "  3. Configure store listing"
        echo -e "  4. Submit for review"
    else
        echo -e "${RED}Error: AAB build failed${NC}"
        exit 1
    fi
}

# Prepare for enterprise distribution
prepare_for_enterprise() {
    local sample=$1
    
    echo -e "\n${YELLOW}Preparing for enterprise distribution...${NC}"
    
    cd "$SAMPLES_DIR/$sample"
    
    # Build release APK
    ./gradlew assembleRelease
    
    APK_PATH="app/build/outputs/apk/release/app-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        # Create enterprise package
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        PACKAGE_DIR="$PROJECT_ROOT/build/enterprise-$TIMESTAMP"
        mkdir -p "$PACKAGE_DIR"
        
        # Copy APK
        cp "$APK_PATH" "$PACKAGE_DIR/"
        
        # Copy documentation
        cp "$PROJECT_ROOT/ANDROID_SETUP.md" "$PACKAGE_DIR/"
        cp "$SAMPLES_DIR/README.md" "$PACKAGE_DIR/"
        
        # Create deployment guide
        cat > "$PACKAGE_DIR/DEPLOYMENT.md" << 'EOF'
# Enterprise Deployment Guide

## Installation Methods

### 1. Android Enterprise (Managed Google Play)
- Upload APK to Managed Google Play
- Distribute via MDM (Mobile Device Management)

### 2. Direct Installation
```bash
adb install app-release.apk
```

### 3. Enterprise App Store
- Host APK on internal server
- Use enterprise app catalog

## Configuration

Update `AgentConfig.kt` with your tenant settings:
- TENANT_ID
- CLIENT_ID
- AGENT_ENDPOINT

## Security

- APK is signed with release key
- Certificate pinning enabled
- All data encrypted in transit and at rest

## Support

For enterprise support, contact: support@microsoft.com
EOF
        
        # Create archive
        cd "$PROJECT_ROOT/build"
        tar -czf "enterprise-$TIMESTAMP.tar.gz" "enterprise-$TIMESTAMP"
        
        echo -e "${GREEN}✓ Enterprise package created${NC}"
        echo -e "\n${BLUE}Package location:${NC} $PROJECT_ROOT/build/enterprise-$TIMESTAMP.tar.gz"
    else
        echo -e "${RED}Error: Release APK build failed${NC}"
        exit 1
    fi
}

# CI/CD deployment
deploy_ci() {
    local sample=$1
    local variant=$2
    
    echo -e "\n${YELLOW}CI/CD Deployment...${NC}"
    
    cd "$SAMPLES_DIR/$sample"
    
    # Build
    ./gradlew clean
    ./gradlew assemble$variant
    
    # Run tests
    ./gradlew test
    ./gradlew lint
    
    # Generate artifacts
    echo -e "${YELLOW}Generating CI artifacts...${NC}"
    
    ARTIFACTS_DIR="$PROJECT_ROOT/build/ci-artifacts"
    mkdir -p "$ARTIFACTS_DIR"
    
    # Copy APKs
    cp -r "app/build/outputs/apk" "$ARTIFACTS_DIR/"
    
    # Copy test results
    cp -r "app/build/reports" "$ARTIFACTS_DIR/"
    
    echo -e "${GREEN}✓ CI deployment completed${NC}"
    echo -e "\n${BLUE}Artifacts location:${NC} $ARTIFACTS_DIR"
}

# Main execution
main() {
    local target=${1:-device}
    local sample="quickstart-kotlin"
    local variant="debug"
    
    # Parse arguments
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            --sample)
                sample="$2"
                shift 2
                ;;
            --variant)
                variant="$2"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
    
    check_prerequisites
    
    case $target in
        device)
            deploy_to_device "$sample" "$variant"
            ;;
        emulator)
            deploy_to_emulator "$sample" "$variant"
            ;;
        store)
            prepare_for_store "$sample"
            ;;
        enterprise)
            prepare_for_enterprise "$sample"
            ;;
        ci)
            deploy_ci "$sample" "$variant"
            ;;
        *)
            echo -e "${RED}Unknown target: $target${NC}"
            show_usage
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}===================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}===================================${NC}"
}

# Run main function
main "$@"
