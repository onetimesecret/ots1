# One-Time Secret Desktop

A secure, privacy-focused desktop application for creating and managing one-time secrets using the [One-Time Secret](https://onetimesecret.dev/) service.

Built with **Tauri**, **Vue 3**, and **TypeScript** for maximum security, performance, and developer experience.

## Features

- **Create Secrets**: Generate one-time secrets with optional passphrase protection
- **View Secrets**: Retrieve and view secrets shared with you
- **Secret Management**: Track your secrets with API authentication
- **Secure Storage**: API credentials stored using platform-native secure storage
  - Windows: Windows Credential Manager (DPAPI)
  - macOS: Keychain
  - Linux: libsecret/kwallet
- **Passphrase Generation**: Built-in secure passphrase generator
- **Cross-Platform**: Windows, macOS, and Linux support
- **Privacy-First**: No data stored beyond what's necessary for the OTS service
- **Modern UI**: Beautiful, responsive interface built with Vue 3

## Security Features

- ✅ **Content Security Policy (CSP)** - Strict CSP headers to prevent XSS attacks
- ✅ **Secure Credential Storage** - Platform-native credential storage (no plaintext)
- ✅ **HTTPS Only** - All API communication uses HTTPS encryption
- ✅ **No Node.js in Renderer** - Tauri's architecture prevents renderer process vulnerabilities
- ✅ **IPC Command Validation** - All backend commands are validated and type-safe
- ✅ **Capability-Based Permissions** - Granular control over app capabilities

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** 18 or later
- **Rust** 1.70 or later (for Tauri)
- **pnpm** (recommended) or npm

### Platform-Specific Requirements

#### Windows
- Microsoft Visual Studio C++ Build Tools
- WebView2 (usually pre-installed on Windows 10/11)

#### macOS
- Xcode Command Line Tools: `xcode-select --install`

#### Linux
```bash
# Debian/Ubuntu
sudo apt update
sudo apt install libwebkit2gtk-4.1-dev \
  build-essential \
  curl \
  wget \
  file \
  libssl-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev \
  libsecret-1-dev

# Fedora
sudo dnf install webkit2gtk4.1-devel \
  openssl-devel \
  curl \
  wget \
  file \
  libappindicator-gtk3-devel \
  librsvg2-devel \
  libsecret-devel

# Arch Linux
sudo pacman -S webkit2gtk-4.1 \
  base-devel \
  curl \
  wget \
  file \
  openssl \
  libappindicator-gtk3 \
  librsvg \
  libsecret
```

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/onetimesecret/ots1.git
cd ots1
```

### 2. Install Dependencies

```bash
# Using pnpm (recommended)
pnpm install

# Or using npm
npm install
```

### 3. Generate Icons (Optional)

Place your application icon in `src-tauri/icons/` directory. You'll need:
- `32x32.png`
- `128x128.png`
- `128x128@2x.png`
- `icon.icns` (macOS)
- `icon.ico` (Windows)

You can use the [Tauri Icon Generator](https://tauri.app/v1/guides/features/icons) or online tools.

## Development

### Run in Development Mode

```bash
# Using pnpm
pnpm tauri:dev

# Or using npm
npm run tauri:dev
```

This will:
1. Start the Vite development server
2. Launch the Tauri application
3. Enable hot-reload for both frontend and backend changes

### Development Tips

- The app will automatically reload when you make changes to Vue components
- Rust changes require a restart (the app will reload automatically)
- DevTools are enabled in development mode (right-click → Inspect Element)

## Building for Production

### Build for Current Platform

```bash
# Using pnpm
pnpm tauri:build

# Or using npm
npm run tauri:build
```

This will create platform-specific installers in `src-tauri/target/release/bundle/`:

- **Windows**: `.msi` and `.exe` installers
- **macOS**: `.dmg` and `.app` bundle
- **Linux**: `.deb`, `.AppImage`, and `.rpm` packages

### Cross-Platform Builds

To build for specific platforms:

```bash
# Windows
pnpm tauri build --target x86_64-pc-windows-msvc

# macOS (Intel)
pnpm tauri build --target x86_64-apple-darwin

# macOS (Apple Silicon)
pnpm tauri build --target aarch64-apple-darwin

# Linux
pnpm tauri build --target x86_64-unknown-linux-gnu
```

## Project Structure

```
ots1/
├── src/                        # Frontend (Vue 3 + TypeScript)
│   ├── components/            # Vue components
│   │   ├── CreateSecret.vue   # Create secret form
│   │   ├── ViewSecret.vue     # View secret form
│   │   ├── SecretList.vue     # List of user's secrets
│   │   └── Settings.vue       # App settings
│   ├── services/              # API and IPC services
│   │   ├── otsApi.ts          # OTS API service
│   │   └── tauri.ts           # Tauri IPC commands
│   ├── stores/                # Pinia state management
│   │   ├── secretStore.ts     # Secret management store
│   │   └── settingsStore.ts   # Settings store
│   ├── types/                 # TypeScript type definitions
│   │   └── index.ts
│   ├── styles/                # Global styles
│   │   └── main.scss
│   ├── App.vue                # Root component
│   ├── main.ts                # App entry point
│   └── vite-env.d.ts          # Vite type definitions
├── src-tauri/                 # Backend (Rust)
│   ├── src/
│   │   ├── main.rs            # Tauri main process
│   │   ├── storage.rs         # Secure storage module
│   │   └── crypto.rs          # Cryptography utilities
│   ├── icons/                 # App icons
│   ├── Cargo.toml             # Rust dependencies
│   ├── tauri.conf.json        # Tauri configuration
│   └── build.rs               # Build script
├── index.html                 # HTML entry point
├── package.json               # Node.js dependencies
├── vite.config.ts             # Vite configuration
├── tsconfig.json              # TypeScript configuration
└── README.md                  # This file
```

## Usage

### First-Time Setup

1. **Launch the Application**
2. **Navigate to Settings**
3. **Configure API Credentials** (optional, for advanced features):
   - Get your API key from [https://onetimesecret.dev/account](https://onetimesecret.dev/account)
   - Enter your username and API key
   - Click "Test Connection" to verify
   - Click "Save Credentials"

### Creating a Secret

1. Go to **Create Secret** tab
2. Enter your secret content
3. (Optional) Enable passphrase protection and generate/enter a passphrase
4. Select the time-to-live (TTL) for the secret
5. (Optional) Enter recipient email
6. Click **Create Secret**
7. Copy the secret link and share it with the recipient
8. If using a passphrase, share it through a separate channel

### Viewing a Secret

1. Go to **View Secret** tab
2. Paste the secret link or key
3. Enter the passphrase if required
4. Click **View Secret**
5. Copy or save the secret (it will be deleted after viewing)

### Managing Secrets (Requires API Credentials)

1. Configure API credentials in Settings
2. Go to **My Secrets** tab
3. View all your created secrets
4. Copy links, view metadata, or burn secrets before they're viewed

## Configuration

### Tauri Configuration

Edit `src-tauri/tauri.conf.json` to customize:
- App name and identifier
- Window size and behavior
- Security policies (CSP)
- Bundle configuration

### API Configuration

The app uses the One-Time Secret API v2 at `https://onetimesecret.dev/api/v2` by default.

## Security Best Practices

When using the app:

1. **Never share secrets and passphrases through the same channel**
2. **Use passphrases for highly sensitive information**
3. **Set appropriate TTL values** - shorter is more secure
4. **Verify the recipient before sharing**
5. **Use the "Burn" feature** if you need to revoke access before viewing
6. **Keep your API credentials secure** - they're stored in your system's credential manager

## Troubleshooting

### Build Errors

**Rust compilation errors:**
```bash
# Update Rust
rustup update

# Clean and rebuild
cd src-tauri
cargo clean
cd ..
pnpm tauri:build
```

**Node.js errors:**
```bash
# Clear node_modules and reinstall
rm -rf node_modules
pnpm install
```

### Runtime Errors

**API connection issues:**
- Check your internet connection
- Verify the API is accessible: https://onetimesecret.dev
- Check API credentials in Settings

**Secure storage issues:**
- On Linux, ensure `libsecret` or `kwallet` is installed
- On Windows, ensure you're logged into your Windows account
- On macOS, check Keychain Access permissions

## Development

### Running Tests

```bash
# Frontend tests
pnpm test

# Rust tests
cd src-tauri
cargo test
```

### Code Style

```bash
# Format TypeScript/Vue
pnpm format

# Format Rust
cd src-tauri
cargo fmt
```

### Linting

```bash
# Lint TypeScript/Vue
pnpm lint

# Lint Rust
cd src-tauri
cargo clippy
```

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [One-Time Secret](https://onetimesecret.dev/) - The amazing secret sharing service
- [Tauri](https://tauri.app/) - The secure framework for desktop apps
- [Vue.js](https://vuejs.org/) - The progressive JavaScript framework
- [Pinia](https://pinia.vuejs.org/) - The Vue Store

## Support

- **Documentation**: [https://onetimesecret.dev/docs](https://onetimesecret.dev/docs)
- **Issues**: [GitHub Issues](https://github.com/onetimesecret/ots1/issues)
- **Discussions**: [GitHub Discussions](https://github.com/onetimesecret/ots1/discussions)

## Comparison: Tauri vs Electron

This app uses **Tauri** instead of Electron for the following reasons:

| Feature | Tauri | Electron |
|---------|-------|----------|
| **Memory Usage** | ~50MB | ~150-300MB |
| **Bundle Size** | ~10MB | ~50-150MB |
| **Security** | Superior - No Node.js in renderer | Requires careful configuration |
| **Native Integration** | Direct Rust bindings | Via Node.js APIs |
| **Startup Time** | Faster | Slower |

### Why Tauri?

1. **Better Security**: No Node.js in the renderer process eliminates entire classes of vulnerabilities
2. **Smaller Footprint**: Users download and run a much smaller application
3. **Native Performance**: Direct access to system APIs through Rust
4. **Modern Architecture**: Built with security-first principles

---

**Built with ❤️ for privacy and security**