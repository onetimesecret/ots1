<script setup lang="ts">
import { ref } from 'vue';
import { useSecretStore } from '@/stores/secretStore';

const secretStore = useSecretStore();

const secretKey = ref('');
const passphrase = ref('');
const retrievedSecret = ref<string | null>(null);
const showPassphraseInput = ref(false);

function extractSecretKey(input: string): string {
  // If it's a full URL, extract the key
  if (input.includes('onetimesecret.dev/secret/')) {
    const match = input.match(/secret\/([a-z0-9]+)/i);
    return match ? match[1] : input;
  }
  return input;
}

async function handleRetrieve() {
  if (!secretKey.value.trim()) {
    alert('Please enter a secret key or URL');
    return;
  }

  try {
    const key = extractSecretKey(secretKey.value.trim());
    const response = await secretStore.retrieveSecret({
      secret_key: key,
      passphrase: passphrase.value || undefined,
    });

    retrievedSecret.value = response.value || 'Secret retrieved but content not available';
  } catch (error: any) {
    console.error('Failed to retrieve secret:', error);

    // Check if passphrase is required
    if (error.response?.status === 401 || error.message?.includes('passphrase')) {
      showPassphraseInput.value = true;
      alert('This secret requires a passphrase');
    } else {
      alert('Failed to retrieve secret. It may have already been viewed or expired.');
    }
  }
}

function handleReset() {
  secretKey.value = '';
  passphrase.value = '';
  retrievedSecret.value = null;
  showPassphraseInput.value = false;
  secretStore.clearError();
}

function copyToClipboard(text: string) {
  navigator.clipboard.writeText(text);
}
</script>

<template>
  <div class="view-secret">
    <div v-if="!retrievedSecret" class="form-container">
      <h2>View a Secret</h2>

      <div class="form-group">
        <label for="secret-key">Secret Link or Key</label>
        <input
          id="secret-key"
          v-model="secretKey"
          type="text"
          placeholder="Enter secret link or key"
          class="form-control"
        />
        <p class="help-text">
          Paste the full secret URL or just the secret key
        </p>
      </div>

      <div v-if="showPassphraseInput" class="form-group">
        <label for="passphrase">Passphrase</label>
        <input
          id="passphrase"
          v-model="passphrase"
          type="text"
          placeholder="Enter the passphrase"
          class="form-control"
        />
      </div>

      <div class="form-actions">
        <button @click="handleRetrieve" class="btn btn-primary" :disabled="secretStore.loading">
          {{ secretStore.loading ? 'Retrieving...' : 'View Secret' }}
        </button>
      </div>

      <div v-if="secretStore.error" class="error-message">
        {{ secretStore.error }}
      </div>

      <div class="warning-box">
        <p><strong>⚠️ Warning:</strong></p>
        <p>
          Once you view a secret, it will be permanently deleted and cannot be viewed again.
          Make sure you're ready to save or use the information before retrieving it.
        </p>
      </div>
    </div>

    <div v-else class="result-container">
      <h2>Secret Retrieved 🔓</h2>

      <div class="secret-display">
        <div class="secret-content">
          {{ retrievedSecret }}
        </div>
        <button @click="copyToClipboard(retrievedSecret)" class="btn btn-secondary">
          Copy to Clipboard
        </button>
      </div>

      <div class="warning-box">
        <p><strong>⚠️ Important:</strong></p>
        <p>
          This secret has been permanently deleted and cannot be viewed again.
          Make sure to save or copy it now if you need it.
        </p>
      </div>

      <div class="form-actions">
        <button @click="handleReset" class="btn btn-primary">
          View Another Secret
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.view-secret {
  max-width: 700px;
  margin: 0 auto;
}

.form-container,
.result-container {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}

h2 {
  margin: 0 0 1.5rem;
  color: #333;
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

.help-text {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: #777;
}

.form-actions {
  margin-top: 2rem;
  display: flex;
  gap: 1rem;
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
  margin-top: 1rem;
}

.btn-secondary:hover {
  background: #e0e0e0;
}

.error-message {
  margin-top: 1rem;
  padding: 1rem;
  background: #fee;
  border-left: 4px solid #f44;
  border-radius: 4px;
  color: #c33;
}

.warning-box {
  margin-top: 2rem;
  padding: 1rem;
  background: #fff3cd;
  border-left: 4px solid #ffc107;
  border-radius: 4px;
}

.warning-box p {
  margin: 0.5rem 0;
  color: #856404;
}

.secret-display {
  margin-bottom: 2rem;
}

.secret-content {
  padding: 1.5rem;
  background: #f8f9fa;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-family: 'Courier New', monospace;
  font-size: 1rem;
  word-wrap: break-word;
  white-space: pre-wrap;
  max-height: 400px;
  overflow-y: auto;
}
</style>
