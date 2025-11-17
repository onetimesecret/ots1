/**
 * Pinia Store for Secret Management
 */

import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type {
  Secret,
  CreateSecretDto,
  SecretResponse,
  SecretMetadata,
  GenerateSecretDto,
  RetrieveSecretDto,
} from '@/types';
import { otsApi } from '@/services/otsApi';

export const useSecretStore = defineStore('secrets', () => {
  // State
  const secrets = ref<SecretMetadata[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const lastCreatedSecret = ref<SecretResponse | null>(null);

  // Getters
  const secretCount = computed(() => secrets.value.length);
  const hasSecrets = computed(() => secrets.value.length > 0);

  // Actions
  async function createSecret(data: CreateSecretDto): Promise<SecretResponse> {
    loading.value = true;
    error.value = null;

    try {
      const response = await otsApi.createSecret(data);
      lastCreatedSecret.value = response;
      return response;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to create secret';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function shareSecret(data: CreateSecretDto): Promise<SecretResponse> {
    loading.value = true;
    error.value = null;

    try {
      const response = await otsApi.shareSecret(data);
      lastCreatedSecret.value = response;

      // Refresh recent secrets
      await fetchRecentSecrets();

      return response;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to share secret';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function generateSecret(data: GenerateSecretDto): Promise<SecretResponse> {
    loading.value = true;
    error.value = null;

    try {
      const response = await otsApi.generateSecret(data);
      lastCreatedSecret.value = response;

      // Refresh recent secrets
      await fetchRecentSecrets();

      return response;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to generate secret';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function retrieveSecret(data: RetrieveSecretDto): Promise<SecretResponse> {
    loading.value = true;
    error.value = null;

    try {
      const response = await otsApi.retrieveSecret(data);
      return response;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to retrieve secret';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function fetchRecentSecrets(): Promise<void> {
    if (!otsApi.hasCredentials()) {
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const response = await otsApi.getRecentMetadata();
      secrets.value = response;
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch recent secrets';
      console.error('Failed to fetch recent secrets:', e);
    } finally {
      loading.value = false;
    }
  }

  async function burnSecret(metadataKey: string): Promise<void> {
    loading.value = true;
    error.value = null;

    try {
      await otsApi.burnSecret(metadataKey);

      // Remove from local list
      secrets.value = secrets.value.filter(s => s.metadata_key !== metadataKey);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to burn secret';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  function clearError(): void {
    error.value = null;
  }

  function clearLastCreated(): void {
    lastCreatedSecret.value = null;
  }

  return {
    // State
    secrets,
    loading,
    error,
    lastCreatedSecret,

    // Getters
    secretCount,
    hasSecrets,

    // Actions
    createSecret,
    shareSecret,
    generateSecret,
    retrieveSecret,
    fetchRecentSecrets,
    burnSecret,
    clearError,
    clearLastCreated,
  };
});
