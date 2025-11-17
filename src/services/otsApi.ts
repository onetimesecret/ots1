/**
 * One-Time Secret API Service
 *
 * Handles all communication with the OTS API v2
 * Documentation: https://onetimesecret.dev/docs/api
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import type {
  CreateSecretDto,
  SecretResponse,
  ApiStatus,
  RetrieveSecretDto,
  GenerateSecretDto,
  ShareSecretDto,
  SecretMetadata,
} from '@/types';

export class OTSApiService {
  private client: AxiosInstance;
  private username: string = '';
  private apiKey: string = '';

  constructor(baseURL: string = 'https://onetimesecret.dev/api/v2') {
    this.client = axios.create({
      baseURL,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 30000, // 30 seconds
    });

    // Add response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response) {
          // Server responded with error status
          console.error('API Error:', error.response.status, error.response.data);
        } else if (error.request) {
          // Request made but no response
          console.error('Network Error:', error.message);
        }
        return Promise.reject(error);
      }
    );
  }

  /**
   * Set API credentials for authenticated requests
   */
  setCredentials(username: string, apiKey: string): void {
    this.username = username;
    this.apiKey = apiKey;

    // Update axios defaults with basic auth
    this.client.defaults.auth = {
      username,
      password: apiKey,
    };
  }

  /**
   * Clear API credentials
   */
  clearCredentials(): void {
    this.username = '';
    this.apiKey = '';
    delete this.client.defaults.auth;
  }

  /**
   * Check if credentials are set
   */
  hasCredentials(): boolean {
    return !!(this.username && this.apiKey);
  }

  /**
   * Get API status
   */
  async getStatus(): Promise<ApiStatus> {
    const response = await this.client.get<ApiStatus>('/status');
    return response.data;
  }

  /**
   * Create a secret (anonymous)
   */
  async createSecret(data: CreateSecretDto): Promise<SecretResponse> {
    const formData = new URLSearchParams();
    formData.append('secret', data.secret);

    if (data.passphrase) {
      formData.append('passphrase', data.passphrase);
    }
    if (data.ttl) {
      formData.append('ttl', data.ttl.toString());
    }
    if (data.recipient) {
      formData.append('recipient', data.recipient);
    }
    if (data.metadata_ttl) {
      formData.append('metadata_ttl', data.metadata_ttl.toString());
    }

    const response = await this.client.post<SecretResponse>('/share', formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });

    return response.data;
  }

  /**
   * Share a secret (authenticated)
   */
  async shareSecret(data: ShareSecretDto): Promise<SecretResponse> {
    if (!this.hasCredentials()) {
      throw new Error('API credentials required for sharing secrets');
    }
    return this.createSecret(data);
  }

  /**
   * Generate a short, unique secret (authenticated)
   */
  async generateSecret(data: GenerateSecretDto): Promise<SecretResponse> {
    if (!this.hasCredentials()) {
      throw new Error('API credentials required for generating secrets');
    }

    const formData = new URLSearchParams();

    if (data.passphrase) {
      formData.append('passphrase', data.passphrase);
    }
    if (data.ttl) {
      formData.append('ttl', data.ttl.toString());
    }
    if (data.recipient) {
      formData.append('recipient', data.recipient);
    }
    if (data.metadata_ttl) {
      formData.append('metadata_ttl', data.metadata_ttl.toString());
    }

    const response = await this.client.post<SecretResponse>('/generate', formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });

    return response.data;
  }

  /**
   * Retrieve a secret
   */
  async retrieveSecret(data: RetrieveSecretDto): Promise<SecretResponse> {
    const formData = new URLSearchParams();

    if (data.passphrase) {
      formData.append('passphrase', data.passphrase);
    }

    const response = await this.client.post<SecretResponse>(
      `/secret/${data.secret_key}`,
      formData,
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      }
    );

    return response.data;
  }

  /**
   * Get secret metadata (authenticated)
   */
  async getSecretMetadata(metadataKey: string): Promise<SecretMetadata> {
    if (!this.hasCredentials()) {
      throw new Error('API credentials required for getting secret metadata');
    }

    const response = await this.client.post<SecretMetadata>(`/private/${metadataKey}`);
    return response.data;
  }

  /**
   * Burn a secret (delete it before it expires) - authenticated
   */
  async burnSecret(metadataKey: string): Promise<SecretMetadata> {
    if (!this.hasCredentials()) {
      throw new Error('API credentials required for burning secrets');
    }

    const response = await this.client.post<SecretMetadata>(`/private/${metadataKey}/burn`);
    return response.data;
  }

  /**
   * Get recent metadata (authenticated)
   */
  async getRecentMetadata(): Promise<SecretMetadata[]> {
    if (!this.hasCredentials()) {
      throw new Error('API credentials required for getting recent metadata');
    }

    const response = await this.client.get<SecretMetadata[]>('/private/recent');
    return response.data;
  }
}

// Export a singleton instance
export const otsApi = new OTSApiService();
