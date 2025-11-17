<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useSettingsStore } from '@/stores/settingsStore';
import { otsApi } from '@/services/otsApi';

const settingsStore = useSettingsStore();

const username = ref('');
const apiKey = ref('');
const showApiKey = ref(false);
const testingConnection = ref(false);
const connectionStatus = ref<'success' | 'error' | null>(null);

onMounted(() => {
  if (settingsStore.apiCredentials) {
    username.value = settingsStore.apiCredentials.username;
    apiKey.value = settingsStore.apiCredentials.apiKey;
  }
});

async function handleSaveCredentials() {
  if (!username.value || !apiKey.value) {
    alert('Please enter both username and API key');
    return;
  }

  try {
    await settingsStore.saveApiCredentials({
      username: username.value,
      apiKey: apiKey.value,
    });
    alert('API credentials saved successfully!');
  } catch (error) {
    console.error('Failed to save credentials:', error);
    alert('Failed to save credentials. Please try again.');
  }
}

async function handleTestConnection() {
  if (!username.value || !apiKey.value) {
    alert('Please enter both username and API key');
    return;
  }

  testingConnection.value = true;
  connectionStatus.value = null;

  try {
    // Temporarily set credentials for testing
    otsApi.setCredentials(username.value, apiKey.value);
    await otsApi.getStatus();
    connectionStatus.value = 'success';
  } catch (error) {
    console.error('Connection test failed:', error);
    connectionStatus.value = 'error';
  } finally {
    testingConnection.value = false;

    // Restore original credentials
    if (settingsStore.apiCredentials) {
      otsApi.setCredentials(
        settingsStore.apiCredentials.username,
        settingsStore.apiCredentials.apiKey
      );
    } else {
      otsApi.clearCredentials();
    }
  }
}

async function handleClearCredentials() {
  if (!confirm('Are you sure you want to clear your API credentials?')) {
    return;
  }

  try {
    await settingsStore.clearApiCredentials();
    username.value = '';
    apiKey.value = '';
    connectionStatus.value = null;
    alert('API credentials cleared successfully!');
  } catch (error) {
    console.error('Failed to clear credentials:', error);
    alert('Failed to clear credentials. Please try again.');
  }
}
</script>

<template>
  <div class="settings">
    <div class="settings-container">
      <h2>Settings</h2>

      <section class="settings-section">
        <h3>API Credentials</h3>
        <p class="section-description">
          Configure your One-Time Secret API credentials to access additional features like
          viewing your secret history and metadata.
        </p>

        <div class="form-group">
          <label for="username">Username</label>
          <input
            id="username"
            v-model="username"
            type="text"
            placeholder="Enter your username"
            class="form-control"
          />
        </div>

        <div class="form-group">
          <label for="api-key">API Key</label>
          <div class="input-group">
            <input
              id="api-key"
              v-model="apiKey"
              :type="showApiKey ? 'text' : 'password'"
              placeholder="Enter your API key"
              class="form-control"
            />
            <button @click="showApiKey = !showApiKey" class="btn btn-secondary">
              {{ showApiKey ? 'Hide' : 'Show' }}
            </button>
          </div>
          <p class="help-text">
            You can find your API key at
            <a href="https://onetimesecret.dev/account" target="_blank">
              https://onetimesecret.dev/account
            </a>
          </p>
        </div>

        <div v-if="connectionStatus" :class="['status-message', connectionStatus]">
          <span v-if="connectionStatus === 'success'">✓ Connection successful!</span>
          <span v-else>✗ Connection failed. Please check your credentials.</span>
        </div>

        <div class="form-actions">
          <button @click="handleTestConnection" class="btn btn-secondary" :disabled="testingConnection">
            {{ testingConnection ? 'Testing...' : 'Test Connection' }}
          </button>
          <button @click="handleSaveCredentials" class="btn btn-primary" :disabled="settingsStore.loading">
            {{ settingsStore.loading ? 'Saving...' : 'Save Credentials' }}
          </button>
          <button
            @click="handleClearCredentials"
            class="btn btn-danger"
            v-if="settingsStore.apiCredentials"
          >
            Clear Credentials
          </button>
        </div>
      </section>

      <section class="settings-section">
        <h3>About</h3>
        <div class="about-info">
          <p>
            <strong>One-Time Secret Desktop</strong> is a secure desktop client for creating and
            managing one-time secrets.
          </p>
          <p>Version: 0.1.0</p>
          <p>
            Built with Tauri, Vue 3, and TypeScript for maximum security and performance.
          </p>
          <p class="links">
            <a href="https://onetimesecret.dev" target="_blank">One-Time Secret</a> |
            <a href="https://github.com/onetimesecret" target="_blank">GitHub</a> |
            <a href="https://onetimesecret.dev/docs" target="_blank">Documentation</a>
          </p>
        </div>
      </section>

      <section class="settings-section">
        <h3>Security & Privacy</h3>
        <div class="security-info">
          <ul>
            <li>✓ All API credentials are stored securely using platform-native credential storage</li>
            <li>✓ No data is stored on our servers beyond what's necessary for the OTS service</li>
            <li>✓ All network communication uses HTTPS encryption</li>
            <li>✓ Secrets are encrypted and can only be viewed once</li>
            <li>✓ Optional passphrase protection for additional security</li>
          </ul>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.settings {
  max-width: 800px;
  margin: 0 auto;
}

.settings-container {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}

h2 {
  margin: 0 0 2rem;
  color: #333;
}

.settings-section {
  margin-bottom: 3rem;
  padding-bottom: 2rem;
  border-bottom: 1px solid #e0e0e0;
}

.settings-section:last-child {
  margin-bottom: 0;
  padding-bottom: 0;
  border-bottom: none;
}

h3 {
  margin: 0 0 1rem;
  color: #444;
}

.section-description {
  margin: 0 0 1.5rem;
  color: #666;
  font-size: 0.95rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #555;
  font-weight: 500;
}

.form-control {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 1rem;
  font-family: inherit;
  transition: border-color 0.3s ease;
}

.form-control:focus {
  outline: none;
  border-color: #667eea;
}

.input-group {
  display: flex;
  gap: 0.5rem;
}

.input-group .form-control {
  flex: 1;
}

.help-text {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: #777;
}

.help-text a {
  color: #667eea;
  text-decoration: none;
}

.help-text a:hover {
  text-decoration: underline;
}

.status-message {
  margin: 1rem 0;
  padding: 1rem;
  border-radius: 8px;
  font-weight: 500;
}

.status-message.success {
  background: #d4edda;
  color: #155724;
}

.status-message.error {
  background: #f8d7da;
  color: #721c24;
}

.form-actions {
  margin-top: 2rem;
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-secondary {
  background: #f0f0f0;
  color: #333;
}

.btn-secondary:hover:not(:disabled) {
  background: #e0e0e0;
}

.btn-danger {
  background: #dc3545;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: #c82333;
}

.about-info,
.security-info {
  color: #666;
}

.about-info p {
  margin: 0.75rem 0;
}

.links a {
  color: #667eea;
  text-decoration: none;
  margin: 0 0.5rem;
}

.links a:hover {
  text-decoration: underline;
}

.security-info ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.security-info li {
  padding: 0.5rem 0;
  color: #555;
}
</style>
