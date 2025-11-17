<script setup lang="ts">
import { ref, computed } from 'vue';
import { useSecretStore } from '@/stores/secretStore';
import { useSettingsStore } from '@/stores/settingsStore';
import { generatePassphrase } from '@/services/tauri';

const secretStore = useSecretStore();
const settingsStore = useSettingsStore();

const secretContent = ref('');
const passphrase = ref('');
const usePassphrase = ref(false);
const ttl = ref(604800); // 7 days in seconds
const recipient = ref('');
const showResult = ref(false);

const secretUrl = computed(() => {
  if (!secretStore.lastCreatedSecret) return '';
  const baseUrl = 'https://onetimesecret.dev';
  return `${baseUrl}/secret/${secretStore.lastCreatedSecret.secret_key}`;
});

const metadataUrl = computed(() => {
  if (!secretStore.lastCreatedSecret) return '';
  const baseUrl = 'https://onetimesecret.dev';
  return `${baseUrl}/private/${secretStore.lastCreatedSecret.metadata_key}`;
});

async function handleGeneratePassphrase() {
  try {
    const generated = await generatePassphrase({
      word_count: 4,
      separator: '-'
    });
    passphrase.value = generated;
  } catch (error) {
    console.error('Failed to generate passphrase:', error);
  }
}

async function handleCreateSecret() {
  if (!secretContent.value.trim()) {
    alert('Please enter a secret');
    return;
  }

  try {
    const hasCredentials = !!settingsStore.apiCredentials;

    if (hasCredentials) {
      await secretStore.shareSecret({
        secret: secretContent.value,
        passphrase: usePassphrase.value ? passphrase.value : undefined,
        ttl: ttl.value,
        recipient: recipient.value || undefined,
      });
    } else {
      await secretStore.createSecret({
        secret: secretContent.value,
        passphrase: usePassphrase.value ? passphrase.value : undefined,
        ttl: ttl.value,
        recipient: recipient.value || undefined,
      });
    }

    showResult.value = true;
  } catch (error) {
    console.error('Failed to create secret:', error);
    alert('Failed to create secret. Please try again.');
  }
}

function handleReset() {
  secretContent.value = '';
  passphrase.value = '';
  usePassphrase.value = false;
  recipient.value = '';
  showResult.value = false;
  secretStore.clearLastCreated();
}

function copyToClipboard(text: string) {
  navigator.clipboard.writeText(text);
}

const ttlOptions = [
  { value: 300, label: '5 minutes' },
  { value: 1800, label: '30 minutes' },
  { value: 3600, label: '1 hour' },
  { value: 14400, label: '4 hours' },
  { value: 86400, label: '1 day' },
  { value: 259200, label: '3 days' },
  { value: 604800, label: '7 days' },
];
</script>

<template>
  <div class="create-secret">
    <div v-if="!showResult" class="form-container">
      <h2>Create a Secret</h2>

      <div class="form-group">
        <label for="secret">Secret Content</label>
        <textarea
          id="secret"
          v-model="secretContent"
          placeholder="Enter your secret message, password, or sensitive data..."
          rows="6"
          class="form-control"
        ></textarea>
      </div>

      <div class="form-group">
        <label>
          <input type="checkbox" v-model="usePassphrase" />
          Require passphrase to view
        </label>
      </div>

      <div v-if="usePassphrase" class="form-group">
        <label for="passphrase">Passphrase</label>
        <div class="input-group">
          <input
            id="passphrase"
            v-model="passphrase"
            type="text"
            placeholder="Enter a passphrase"
            class="form-control"
          />
          <button @click="handleGeneratePassphrase" class="btn btn-secondary">
            Generate
          </button>
        </div>
      </div>

      <div class="form-group">
        <label for="ttl">Time to Live</label>
        <select id="ttl" v-model.number="ttl" class="form-control">
          <option v-for="option in ttlOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </option>
        </select>
      </div>

      <div class="form-group">
        <label for="recipient">Recipient Email (optional)</label>
        <input
          id="recipient"
          v-model="recipient"
          type="email"
          placeholder="recipient@example.com"
          class="form-control"
        />
      </div>

      <div class="form-actions">
        <button @click="handleCreateSecret" class="btn btn-primary" :disabled="secretStore.loading">
          {{ secretStore.loading ? 'Creating...' : 'Create Secret' }}
        </button>
      </div>

      <div v-if="secretStore.error" class="error-message">
        {{ secretStore.error }}
      </div>
    </div>

    <div v-else class="result-container">
      <h2>Secret Created Successfully! 🎉</h2>

      <div class="result-group">
        <label>Secret Link (share this)</label>
        <div class="input-group">
          <input
            :value="secretUrl"
            readonly
            class="form-control"
          />
          <button @click="copyToClipboard(secretUrl)" class="btn btn-secondary">
            Copy
          </button>
        </div>
        <p class="help-text">
          Share this link with the recipient. It can only be viewed once!
        </p>
      </div>

      <div v-if="settingsStore.apiCredentials" class="result-group">
        <label>Metadata Link (for you)</label>
        <div class="input-group">
          <input
            :value="metadataUrl"
            readonly
            class="form-control"
          />
          <button @click="copyToClipboard(metadataUrl)" class="btn btn-secondary">
            Copy
          </button>
        </div>
        <p class="help-text">
          Use this link to check the status or burn the secret before it's viewed.
        </p>
      </div>

      <div v-if="usePassphrase" class="result-group">
        <label>Passphrase</label>
        <div class="input-group">
          <input
            :value="passphrase"
            readonly
            class="form-control"
          />
          <button @click="copyToClipboard(passphrase)" class="btn btn-secondary">
            Copy
          </button>
        </div>
        <p class="help-text">
          Share this passphrase separately with the recipient.
        </p>
      </div>

      <div class="form-actions">
        <button @click="handleReset" class="btn btn-primary">
          Create Another Secret
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.create-secret {
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

textarea.form-control {
  resize: vertical;
}

.input-group {
  display: flex;
  gap: 0.5rem;
}

.input-group .form-control {
  flex: 1;
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

.result-group {
  margin-bottom: 2rem;
}

.result-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #555;
  font-weight: 500;
}

.help-text {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: #777;
}
</style>
