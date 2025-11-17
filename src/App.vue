<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { useSettingsStore } from '@/stores/settingsStore';
import CreateSecret from '@/components/CreateSecret.vue';
import ViewSecret from '@/components/ViewSecret.vue';
import Settings from '@/components/Settings.vue';
import SecretList from '@/components/SecretList.vue';

const settingsStore = useSettingsStore();
const activeTab = ref<'create' | 'view' | 'list' | 'settings'>('create');

onMounted(async () => {
  // Load settings on app start
  await settingsStore.loadSettings();
});

function setActiveTab(tab: 'create' | 'view' | 'list' | 'settings') {
  activeTab.value = tab;
}
</script>

<template>
  <div class="app">
    <header class="app-header">
      <h1 class="app-title">
        <span class="icon">🔐</span>
        One-Time Secret
      </h1>
      <p class="app-subtitle">Secure secret sharing desktop client</p>
    </header>

    <nav class="app-nav">
      <button
        :class="['nav-button', { active: activeTab === 'create' }]"
        @click="setActiveTab('create')"
      >
        Create Secret
      </button>
      <button
        :class="['nav-button', { active: activeTab === 'view' }]"
        @click="setActiveTab('view')"
      >
        View Secret
      </button>
      <button
        :class="['nav-button', { active: activeTab === 'list' }]"
        @click="setActiveTab('list')"
        v-if="settingsStore.apiCredentials"
      >
        My Secrets
      </button>
      <button
        :class="['nav-button', { active: activeTab === 'settings' }]"
        @click="setActiveTab('settings')"
      >
        Settings
      </button>
    </nav>

    <main class="app-main">
      <CreateSecret v-if="activeTab === 'create'" />
      <ViewSecret v-else-if="activeTab === 'view'" />
      <SecretList v-else-if="activeTab === 'list'" />
      <Settings v-else-if="activeTab === 'settings'" />
    </main>

    <footer class="app-footer">
      <p>
        <a href="https://onetimesecret.dev" target="_blank">onetimesecret.dev</a> |
        <a href="https://github.com/onetimesecret" target="_blank">GitHub</a>
      </p>
    </footer>
  </div>
</template>

<style scoped>
.app {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.app-header {
  background: rgba(255, 255, 255, 0.95);
  padding: 1.5rem 2rem;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  text-align: center;
}

.app-title {
  margin: 0;
  font-size: 2rem;
  color: #333;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.icon {
  font-size: 2rem;
}

.app-subtitle {
  margin: 0.5rem 0 0;
  color: #666;
  font-size: 0.95rem;
}

.app-nav {
  display: flex;
  gap: 0.5rem;
  padding: 1rem 2rem;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.nav-button {
  padding: 0.75rem 1.5rem;
  border: none;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  font-size: 0.95rem;
  font-weight: 500;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.nav-button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.nav-button.active {
  background: rgba(255, 255, 255, 0.95);
  color: #667eea;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.app-main {
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
}

.app-footer {
  background: rgba(0, 0, 0, 0.2);
  padding: 1rem 2rem;
  text-align: center;
}

.app-footer p {
  margin: 0;
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.9rem;
}

.app-footer a {
  color: rgba(255, 255, 255, 0.9);
  text-decoration: none;
  margin: 0 0.5rem;
}

.app-footer a:hover {
  text-decoration: underline;
}
</style>
