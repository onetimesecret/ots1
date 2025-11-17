<script setup lang="ts">
import { onMounted } from 'vue';
import { useSecretStore } from '@/stores/secretStore';

const secretStore = useSecretStore();

onMounted(() => {
  secretStore.fetchRecentSecrets();
});

function formatDate(timestamp: number): string {
  return new Date(timestamp * 1000).toLocaleString();
}

function formatTimeRemaining(ttl: number, created: number): string {
  const now = Math.floor(Date.now() / 1000);
  const elapsed = now - created;
  const remaining = ttl - elapsed;

  if (remaining <= 0) return 'Expired';

  const days = Math.floor(remaining / 86400);
  const hours = Math.floor((remaining % 86400) / 3600);
  const minutes = Math.floor((remaining % 3600) / 60);

  if (days > 0) return `${days}d ${hours}h`;
  if (hours > 0) return `${hours}h ${minutes}m`;
  return `${minutes}m`;
}

async function handleBurn(metadataKey: string) {
  if (!confirm('Are you sure you want to burn this secret? This cannot be undone.')) {
    return;
  }

  try {
    await secretStore.burnSecret(metadataKey);
  } catch (error) {
    console.error('Failed to burn secret:', error);
    alert('Failed to burn secret. Please try again.');
  }
}

function copyToClipboard(text: string) {
  navigator.clipboard.writeText(text);
}

function getSecretUrl(secretKey: string): string {
  return `https://onetimesecret.dev/secret/${secretKey}`;
}

function getMetadataUrl(metadataKey: string): string {
  return `https://onetimesecret.dev/private/${metadataKey}`;
}
</script>

<template>
  <div class="secret-list">
    <div class="header">
      <h2>My Secrets</h2>
      <button @click="secretStore.fetchRecentSecrets()" class="btn btn-secondary" :disabled="secretStore.loading">
        {{ secretStore.loading ? 'Refreshing...' : 'Refresh' }}
      </button>
    </div>

    <div v-if="secretStore.error" class="error-message">
      {{ secretStore.error }}
    </div>

    <div v-if="secretStore.loading && !secretStore.hasSecrets" class="loading">
      Loading secrets...
    </div>

    <div v-else-if="!secretStore.hasSecrets" class="empty-state">
      <p>No secrets found</p>
      <p class="help-text">Create a secret to see it listed here</p>
    </div>

    <div v-else class="secrets-grid">
      <div v-for="secret in secretStore.secrets" :key="secret.metadata_key" class="secret-card">
        <div class="secret-header">
          <span :class="['status-badge', secret.state]">
            {{ secret.state }}
          </span>
          <span class="ttl">
            {{ formatTimeRemaining(secret.ttl, secret.created) }}
          </span>
        </div>

        <div class="secret-info">
          <div class="info-row">
            <span class="label">Created:</span>
            <span class="value">{{ formatDate(secret.created) }}</span>
          </div>

          <div v-if="secret.recipient && secret.recipient.length > 0" class="info-row">
            <span class="label">Recipient:</span>
            <span class="value">{{ secret.recipient.join(', ') }}</span>
          </div>

          <div class="info-row">
            <span class="label">Passphrase:</span>
            <span class="value">{{ secret.passphrase_required ? 'Required' : 'Not required' }}</span>
          </div>
        </div>

        <div class="secret-actions">
          <button
            @click="copyToClipboard(getSecretUrl(secret.secret_key))"
            class="btn btn-small btn-secondary"
            title="Copy secret link"
          >
            Copy Link
          </button>
          <button
            @click="copyToClipboard(getMetadataUrl(secret.metadata_key))"
            class="btn btn-small btn-secondary"
            title="Copy metadata link"
          >
            Copy Metadata
          </button>
          <button
            @click="handleBurn(secret.metadata_key)"
            class="btn btn-small btn-danger"
            title="Burn secret"
          >
            Burn
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.secret-list {
  max-width: 1000px;
  margin: 0 auto;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

h2 {
  margin: 0;
  color: white;
}

.error-message {
  margin-bottom: 1rem;
  padding: 1rem;
  background: #fee;
  border-left: 4px solid #f44;
  border-radius: 4px;
  color: #c33;
}

.loading,
.empty-state {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 3rem;
  text-align: center;
}

.empty-state p {
  margin: 0.5rem 0;
  color: #666;
}

.help-text {
  font-size: 0.9rem;
  color: #999;
}

.secrets-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}

.secret-card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.secret-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.secret-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e0e0e0;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: 500;
  text-transform: uppercase;
}

.status-badge.new {
  background: #d4edda;
  color: #155724;
}

.status-badge.received {
  background: #d1ecf1;
  color: #0c5460;
}

.status-badge.viewed {
  background: #fff3cd;
  color: #856404;
}

.status-badge.expired {
  background: #f8d7da;
  color: #721c24;
}

.ttl {
  font-size: 0.9rem;
  color: #666;
  font-weight: 500;
}

.secret-info {
  margin-bottom: 1rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
}

.label {
  color: #666;
  font-weight: 500;
}

.value {
  color: #333;
}

.secret-actions {
  display: flex;
  gap: 0.5rem;
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

.btn-secondary {
  background: #f0f0f0;
  color: #333;
}

.btn-secondary:hover:not(:disabled) {
  background: #e0e0e0;
}

.btn-small {
  padding: 0.5rem 1rem;
  font-size: 0.85rem;
}

.btn-danger {
  background: #dc3545;
  color: white;
}

.btn-danger:hover {
  background: #c82333;
}
</style>
