#!/bin/bash

# OneTimeSecret Flutter App - Setup Script
# This script sets up the development environment and generates required files

set -e  # Exit on error

echo "════════════════════════════════════════════════════════════"
echo "  OneTimeSecret Flutter App - Setup"
echo "════════════════════════════════════════════════════════════"
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if Flutter is installed
print_step "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    echo "Please install Flutter from https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n1 | awk '{print $2}')
print_success "Flutter $FLUTTER_VERSION detected"

# Check Dart version
DART_VERSION=$(dart --version | awk '{print $4}')
print_success "Dart $DART_VERSION detected"

# Run flutter doctor
print_step "Running flutter doctor..."
flutter doctor -v

# Clean previous builds
print_step "Cleaning previous builds..."
flutter clean
print_success "Clean complete"

# Get dependencies
print_step "Getting Flutter dependencies..."
flutter pub get
print_success "Dependencies installed"

# Run build_runner to generate code
print_step "Generating code (JSON serialization, Retrofit API, DI)..."
print_warning "This may take a few minutes..."

flutter pub run build_runner build --delete-conflicting-outputs

if [ $? -eq 0 ]; then
    print_success "Code generation complete"
else
    print_error "Code generation failed"
    exit 1
fi

# Create necessary directories if they don't exist
print_step "Creating asset directories..."
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts
mkdir -p assets/certificates
print_success "Directories created"

# Check for platform-specific setup
echo ""
print_step "Platform-specific setup:"
echo ""

# Android
if [ -d "android" ]; then
    print_success "Android configuration found"
    echo "  - Min SDK: 24"
    echo "  - Target SDK: 34"
    echo "  - ProGuard: Configured"

    if [ ! -f "android/key.properties" ]; then
        print_warning "android/key.properties not found (required for release builds)"
        echo "  Create it with:"
        echo "    storePassword=<password>"
        echo "    keyPassword=<password>"
        echo "    keyAlias=<alias>"
        echo "    storeFile=<path-to-keystore>"
    fi
else
    print_warning "Android directory not found"
fi

echo ""

# iOS
if [ -d "ios" ]; then
    print_success "iOS configuration found"
    echo "  - Deployment Target: 12.0"
    echo "  - Info.plist: Configured"

    if command -v pod &> /dev/null; then
        print_step "Installing CocoaPods dependencies..."
        cd ios
        pod install
        cd ..
        print_success "CocoaPods dependencies installed"
    else
        print_warning "CocoaPods not installed (required for iOS builds)"
        echo "  Install with: sudo gem install cocoapods"
    fi
else
    print_warning "iOS directory not found"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
print_success "Setup complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure security settings:"
echo "   - Update certificate fingerprints in lib/core/constants/app_constants.dart"
echo "   - Update RASP config in lib/core/security/rasp_config.dart"
echo ""
echo "2. Run the app:"
echo "   flutter run"
echo ""
echo "3. Run tests:"
echo "   flutter test"
echo ""
echo "4. Build for release:"
echo "   Android: flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols"
echo "   iOS:     flutter build ios --release --obfuscate --split-debug-info=build/ios/outputs/symbols"
echo ""
echo "For detailed instructions, see BUILD.md"
echo ""
