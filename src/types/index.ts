/**
 * TypeScript type definitions for One-Time Secret Desktop App
 */

export interface Secret {
  custid: string;
  metadata_key: string;
  secret_key: string;
  ttl: number;
  metadata_ttl?: number;
  secret_ttl?: number;
  state?: string;
  updated?: number;
  created?: number;
  recipient?: string[];
  passphrase_required?: boolean;
}

export interface SecretMetadata {
  custid: string;
  metadata_key: string;
  secret_key: string;
  ttl: number;
  metadata_ttl: number;
  secret_ttl: number;
  state: string;
  updated: number;
  created: number;
  recipient?: string[];
  passphrase_required: boolean;
}

export interface CreateSecretDto {
  secret: string;
  passphrase?: string;
  ttl?: number;
  recipient?: string;
  metadata_ttl?: number;
}

export interface ShareSecretDto extends CreateSecretDto {
  // Additional fields for sharing
}

export interface GenerateSecretDto {
  passphrase?: string;
  ttl?: number;
  recipient?: string;
  metadata_ttl?: number;
}

export interface SecretResponse {
  custid: string;
  metadata_key: string;
  secret_key: string;
  ttl: number;
  passphrase_required?: boolean;
  metadata_ttl?: number;
  secret_ttl?: number;
  value?: string;
}

export interface RetrieveSecretDto {
  secret_key: string;
  passphrase?: string;
}

export interface ApiStatus {
  status: string;
  version: string;
}

export interface ApiCredentials {
  username: string;
  apiKey: string;
}

export interface AppSettings {
  apiBaseUrl: string;
  defaultTTL: number;
  defaultMetadataTTL: number;
  autoCloseAfterView: boolean;
  showNotifications: boolean;
}

export enum SecretState {
  NEW = 'new',
  RECEIVED = 'received',
  VIEWED = 'viewed',
  EXPIRED = 'expired',
}

export interface PassphraseOptions {
  word_count: number;
  separator: string;
}
