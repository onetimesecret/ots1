/**
 * Tauri IPC Service
 *
 * Wrapper for Tauri commands with type safety
 */

import { invoke } from '@tauri-apps/api/core';
import type { PassphraseOptions } from '@/types';

/**
 * Store a value securely in the platform's credential store
 */
export async function storeSecure(key: string, value: string): Promise<void> {
  return invoke('store_secure', { key, value });
}

/**
 * Retrieve a value from the platform's credential store
 */
export async function retrieveSecure(key: string): Promise<string> {
  return invoke('retrieve_secure', { key });
}

/**
 * Delete a value from the platform's credential store
 */
export async function deleteSecure(key: string): Promise<void> {
  return invoke('delete_secure', { key });
}

/**
 * Generate a random passphrase
 */
export async function generatePassphrase(options: PassphraseOptions): Promise<string> {
  return invoke('generate_passphrase', { options });
}
