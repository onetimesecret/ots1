/**
 * Pinia Store for Application Settings
 */

import { defineStore } from 'pinia';
import { ref } from 'vue';
import type { AppSettings, ApiCredentials } from '@/types';
import { otsApi } from '@/services/otsApi';
import { storeSecure, retrieveSecure, deleteSecure } from '@/services/tauri';

const DEFAULT_SETTINGS: AppSettings = {
  apiBaseUrl: 'https://onetimesecret.dev/api/v2',
  defaultTTL: 604800, // 7 days in seconds
  defaultMetadataTTL: 604800,
  autoCloseAfterView: false,
  showNotifications: true,
};

const STORAGE_KEYS = {
  API_USERNAME: 'api_username',
  API_KEY: 'api_key',
  SETTINGS: 'app_settings',
};

export const useSettingsStore = defineStore('settings', () => {
  // State
  const settings = ref<AppSettings>({ ...DEFAULT_SETTINGS });
  const apiCredentials = ref<ApiCredentials | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  // Actions
  async function loadSettings(): Promise<void> {
    loading.value = true;
    error.value = null;

    try {
      // Load settings from secure storage
      const settingsJson = await retrieveSecure(STORAGE_KEYS.SETTINGS).catch(() => null);
      if (settingsJson) {
        settings.value = { ...DEFAULT_SETTINGS, ...JSON.parse(settingsJson) };
      }

      // Load API credentials
      const username = await retrieveSecure(STORAGE_KEYS.API_USERNAME).catch(() => null);
      const apiKey = await retrieveSecure(STORAGE_KEYS.API_KEY).catch(() => null);

      if (username && apiKey) {
        apiCredentials.value = { username, apiKey };
        otsApi.setCredentials(username, apiKey);
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to load settings';
      console.error('Failed to load settings:', e);
    } finally {
      loading.value = false;
    }
  }

  async function saveSettings(newSettings: Partial<AppSettings>): Promise<void> {
    loading.value = true;
    error.value = null;

    try {
      settings.value = { ...settings.value, ...newSettings };
      await storeSecure(STORAGE_KEYS.SETTINGS, JSON.stringify(settings.value));
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to save settings';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function saveApiCredentials(credentials: ApiCredentials): Promise<void> {
    loading.value = true;
    error.value = null;

    try {
      await storeSecure(STORAGE_KEYS.API_USERNAME, credentials.username);
      await storeSecure(STORAGE_KEYS.API_KEY, credentials.apiKey);

      apiCredentials.value = credentials;
      otsApi.setCredentials(credentials.username, credentials.apiKey);
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to save API credentials';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function clearApiCredentials(): Promise<void> {
    loading.value = true;
    error.value = null;

    try {
      await deleteSecure(STORAGE_KEYS.API_USERNAME).catch(() => {});
      await deleteSecure(STORAGE_KEYS.API_KEY).catch(() => {});

      apiCredentials.value = null;
      otsApi.clearCredentials();
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to clear API credentials';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  function resetToDefaults(): void {
    settings.value = { ...DEFAULT_SETTINGS };
  }

  function clearError(): void {
    error.value = null;
  }

  return {
    // State
    settings,
    apiCredentials,
    loading,
    error,

    // Actions
    loadSettings,
    saveSettings,
    saveApiCredentials,
    clearApiCredentials,
    resetToDefaults,
    clearError,
  };
});
