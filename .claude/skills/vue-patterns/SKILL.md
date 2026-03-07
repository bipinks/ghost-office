---
name: vue-patterns
description: Use when building Vue.js applications. Covers Vue 3 Composition API, composables, Pinia state management, Vue Router, Vite configuration, component design patterns, form handling, and enterprise application architecture.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Vue.js Patterns -- Enterprise Application Development

## 1. Project Structure

Feature-based organization with barrel exports and path aliases.

```
src/
├── api/                    -- API client, interceptors, endpoint modules
│   ├── client.ts
│   ├── endpoints/
│   │   ├── invoices.ts
│   │   ├── inventory.ts
│   │   └── index.ts        -- barrel export
│   └── index.ts
├── assets/                 -- Static assets, global CSS, fonts
├── components/
│   ├── common/             -- Button, Modal, Alert, Spinner, Badge
│   ├── forms/              -- FormInput, FormSelect, DatePicker, FileUpload
│   ├── layout/             -- AppLayout, Sidebar, Header, BranchSwitcher
│   ├── data/               -- DataTable, Pagination, ChartWrapper
│   └── index.ts            -- barrel export for common components
├── composables/            -- Reusable logic hooks
│   ├── useAuth.ts
│   ├── usePagination.ts
│   ├── useForm.ts
│   ├── useBranchScope.ts
│   └── index.ts
├── modules/                -- Feature modules (pages + module-specific components)
│   ├── accounting/
│   ├── inventory/
│   ├── hr/
│   └── sales/
├── router/                 -- Route definitions and guards
│   ├── index.ts
│   └── guards.ts
├── stores/                 -- Pinia stores
│   ├── auth.ts
│   ├── branch.ts
│   ├── ui.ts
│   └── index.ts
├── types/                  -- TypeScript interfaces and enums
│   ├── models.ts
│   ├── api.ts
│   └── index.ts
├── utils/                  -- Pure helper functions
│   ├── formatters.ts
│   ├── validators.ts
│   └── index.ts
├── plugins/                -- Vue plugin registrations
├── App.vue
└── main.ts
```

### Path Aliases (tsconfig.json)

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@composables/*": ["src/composables/*"],
      "@stores/*": ["src/stores/*"],
      "@api/*": ["src/api/*"],
      "@types/*": ["src/types/*"]
    }
  }
}
```

### Barrel Exports

```typescript
// src/components/index.ts
export { default as AppButton } from './common/AppButton.vue';
export { default as AppModal } from './common/AppModal.vue';
export { default as DataTable } from './data/DataTable.vue';
export { default as Pagination } from './data/Pagination.vue';
```

---

## 2. Composition API Deep Dive

### Reactivity Primitives

```typescript
import { ref, reactive, computed, watch, watchEffect, toRefs } from 'vue';

// ref -- single value reactivity (primitives and objects)
const count = ref(0);
const invoice = ref<Invoice | null>(null);
count.value++;  // access via .value in script

// reactive -- object reactivity (no .value needed, but cannot reassign root)
const filters = reactive<InvoiceFilters>({
  status: 'all',
  dateFrom: '',
  dateTo: '',
  search: '',
});

// computed -- derived state, cached until dependencies change
const unpaidTotal = computed(() =>
  invoices.value
    .filter((inv) => inv.status === 'unpaid')
    .reduce((sum, inv) => sum + inv.total, 0)
);

// watch -- react to specific source changes
watch(
  () => filters.status,
  (newStatus, oldStatus) => {
    console.log(`Status changed from ${oldStatus} to ${newStatus}`);
    fetchInvoices();
  },
  { immediate: false }
);

// watch multiple sources
watch([() => filters.status, () => filters.search], () => {
  page.value = 1;
  fetchInvoices();
});

// watchEffect -- auto-tracks dependencies, runs immediately
watchEffect(() => {
  document.title = `Invoices (${unpaidTotal.value} unpaid)`;
});

// toRefs -- destructure reactive without losing reactivity
const { status, search } = toRefs(filters);
```

### Lifecycle Hooks

```typescript
import { onMounted, onUnmounted, onBeforeMount, onUpdated } from 'vue';

onBeforeMount(() => {
  // before DOM is created
});

onMounted(() => {
  // DOM is ready; fetch data, attach event listeners
  fetchInitialData();
  window.addEventListener('resize', handleResize);
});

onUpdated(() => {
  // after reactive state change causes DOM update
});

onUnmounted(() => {
  // cleanup: remove listeners, cancel timers, abort requests
  window.removeEventListener('resize', handleResize);
  abortController.abort();
});
```

---

## 3. Composables

### useAuth

```typescript
// composables/useAuth.ts
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@stores/auth';

export function useAuth() {
  const store = useAuthStore();
  const router = useRouter();

  const user = computed(() => store.user);
  const isAuthenticated = computed(() => !!store.token);
  const branchId = computed(() => store.user?.branch_id);

  async function login(email: string, password: string) {
    await store.login({ email, password });
    router.push({ name: 'dashboard' });
  }

  async function logout() {
    await store.logout();
    router.push({ name: 'login' });
  }

  function can(permission: string): boolean {
    return store.user?.permissions?.includes(permission) ?? false;
  }

  return { user, isAuthenticated, branchId, login, logout, can };
}
```

### usePagination

```typescript
// composables/usePagination.ts
import { ref, computed, watch } from 'vue';

interface PaginationOptions {
  defaultPage?: number;
  defaultPerPage?: number;
  onPageChange?: (page: number) => void;
}

export function usePagination(options: PaginationOptions = {}) {
  const page = ref(options.defaultPage ?? 1);
  const perPage = ref(options.defaultPerPage ?? 25);
  const total = ref(0);

  const totalPages = computed(() => Math.ceil(total.value / perPage.value));
  const hasNextPage = computed(() => page.value < totalPages.value);
  const hasPrevPage = computed(() => page.value > 1);
  const offset = computed(() => (page.value - 1) * perPage.value);

  function nextPage() {
    if (hasNextPage.value) page.value++;
  }

  function prevPage() {
    if (hasPrevPage.value) page.value--;
  }

  function goToPage(p: number) {
    if (p >= 1 && p <= totalPages.value) page.value = p;
  }

  watch(page, (val) => options.onPageChange?.(val));

  return { page, perPage, total, totalPages, hasNextPage, hasPrevPage, offset, nextPage, prevPage, goToPage };
}
```

### useForm

```typescript
// composables/useForm.ts
import { ref, reactive, computed } from 'vue';
import type { AxiosError } from 'axios';

interface UseFormOptions<T> {
  initialValues: T;
  onSubmit: (values: T) => Promise<void>;
  validate?: (values: T) => Record<string, string>;
}

export function useForm<T extends Record<string, any>>(options: UseFormOptions<T>) {
  const values = reactive<T>({ ...options.initialValues }) as T;
  const errors = ref<Record<string, string>>({});
  const submitting = ref(false);
  const submitted = ref(false);

  const isDirty = computed(() =>
    JSON.stringify(values) !== JSON.stringify(options.initialValues)
  );

  function setErrors(errs: Record<string, string | string[]>) {
    errors.value = {};
    for (const [key, val] of Object.entries(errs)) {
      errors.value[key] = Array.isArray(val) ? val[0] : val;
    }
  }

  function reset() {
    Object.assign(values, options.initialValues);
    errors.value = {};
    submitted.value = false;
  }

  async function submit() {
    errors.value = {};
    if (options.validate) {
      const validationErrors = options.validate(values);
      if (Object.keys(validationErrors).length > 0) {
        errors.value = validationErrors;
        return;
      }
    }
    submitting.value = true;
    try {
      await options.onSubmit(values);
      submitted.value = true;
    } catch (err) {
      const axiosErr = err as AxiosError<{ errors?: Record<string, string[]> }>;
      if (axiosErr.response?.status === 422 && axiosErr.response.data?.errors) {
        setErrors(axiosErr.response.data.errors);
      } else {
        throw err;
      }
    } finally {
      submitting.value = false;
    }
  }

  return { values, errors, submitting, submitted, isDirty, submit, reset, setErrors };
}
```

### useBranchScope

```typescript
// composables/useBranchScope.ts
import { computed, watch } from 'vue';
import { useBranchStore } from '@stores/branch';

export function useBranchScope() {
  const store = useBranchStore();

  const currentBranch = computed(() => store.currentBranch);
  const branchId = computed(() => store.currentBranch?.id);
  const branchName = computed(() => store.currentBranch?.name ?? 'No Branch');
  const branches = computed(() => store.branches);

  function switchBranch(id: number) {
    store.setBranch(id);
  }

  function onBranchChange(callback: (branchId: number) => void) {
    watch(branchId, (newId) => {
      if (newId) callback(newId);
    });
  }

  return { currentBranch, branchId, branchName, branches, switchBranch, onBranchChange };
}
```

---

## 4. Pinia State Management

### Store Design

```typescript
// stores/auth.ts
import { defineStore } from 'pinia';
import { api } from '@api/client';
import type { User, LoginPayload, AuthState } from '@types';

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    user: null,
    token: localStorage.getItem('auth_token'),
    permissions: [],
  }),

  getters: {
    isAuthenticated: (state) => !!state.token,
    fullName: (state) => state.user ? `${state.user.first_name} ${state.user.last_name}` : '',
    hasPermission: (state) => (perm: string) => state.permissions.includes(perm),
  },

  actions: {
    async login(payload: LoginPayload) {
      const { data } = await api.post<{ data: { user: User; token: string } }>('/auth/login', payload);
      this.user = data.user;
      this.token = data.token;
      this.permissions = data.user.permissions ?? [];
      localStorage.setItem('auth_token', data.token);
    },

    async logout() {
      try { await api.post('/auth/logout'); } catch { /* ignore */ }
      this.$reset();
      localStorage.removeItem('auth_token');
    },

    async fetchUser() {
      const { data } = await api.get<{ data: User }>('/auth/me');
      this.user = data;
      this.permissions = data.permissions ?? [];
    },
  },
});
```

### Pinia Persistence Plugin

```typescript
// plugins/pinia-persist.ts
import type { PiniaPluginContext } from 'pinia';

export function piniaPersistedState({ store }: PiniaPluginContext) {
  const stored = localStorage.getItem(`pinia-${store.$id}`);
  if (stored) {
    store.$patch(JSON.parse(stored));
  }
  store.$subscribe((_, state) => {
    localStorage.setItem(`pinia-${store.$id}`, JSON.stringify(state));
  });
}
```

---

## 5. Vue Router

### Route Configuration with Lazy Loading

```typescript
// router/index.ts
import { createRouter, createWebHistory } from 'vue-router';
import type { RouteRecordRaw } from 'vue-router';
import { useAuthStore } from '@stores/auth';

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/modules/auth/LoginPage.vue'),
    meta: { guest: true, title: 'Login' },
  },
  {
    path: '/',
    component: () => import('@/components/layout/AppLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', name: 'dashboard', component: () => import('@/modules/dashboard/DashboardPage.vue'), meta: { title: 'Dashboard' } },
      {
        path: 'invoices',
        children: [
          { path: '', name: 'invoices.index', component: () => import('@/modules/accounting/InvoiceList.vue'), meta: { title: 'Invoices', permission: 'invoices.view' } },
          { path: 'create', name: 'invoices.create', component: () => import('@/modules/accounting/InvoiceForm.vue'), meta: { title: 'New Invoice', permission: 'invoices.create' } },
          { path: ':id', name: 'invoices.show', component: () => import('@/modules/accounting/InvoiceDetail.vue'), meta: { title: 'Invoice Detail' }, props: true },
          { path: ':id/edit', name: 'invoices.edit', component: () => import('@/modules/accounting/InvoiceForm.vue'), meta: { title: 'Edit Invoice', permission: 'invoices.edit' }, props: true },
        ],
      },
    ],
  },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/modules/errors/NotFound.vue') },
];

const router = createRouter({ history: createWebHistory(), routes });

// Global navigation guard
router.beforeEach(async (to) => {
  const auth = useAuthStore();
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } };
  }
  if (to.meta.guest && auth.isAuthenticated) {
    return { name: 'dashboard' };
  }
  if (to.meta.permission && !auth.hasPermission(to.meta.permission as string)) {
    return { name: 'dashboard' };
  }
  document.title = `${to.meta.title ?? 'App'} | ERP`;
});

export default router;
```

---

## 6. Component Patterns

### Renderless Component (Slot-Based Logic)

```vue
<!-- components/common/FetchData.vue -->
<script setup lang="ts" generic="T">
import { ref, onMounted } from 'vue';

const props = defineProps<{ url: string; immediate?: boolean }>();
const data = ref<T | null>(null);
const error = ref<string | null>(null);
const loading = ref(false);

async function execute() {
  loading.value = true;
  error.value = null;
  try {
    const res = await fetch(props.url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    data.value = await res.json();
  } catch (e: any) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
}

onMounted(() => { if (props.immediate !== false) execute(); });
</script>

<template>
  <slot :data="data" :loading="loading" :error="error" :refresh="execute" />
</template>
```

Usage:

```vue
<FetchData url="/api/v1/stats" v-slot="{ data, loading, error }">
  <Spinner v-if="loading" />
  <ErrorAlert v-else-if="error" :message="error" />
  <StatsCard v-else :stats="data" />
</FetchData>
```

### Provide/Inject for Compound Components

```typescript
// components/common/tabs/types.ts
import type { InjectionKey, Ref } from 'vue';

export interface TabsContext {
  activeTab: Ref<string>;
  registerTab: (id: string, label: string) => void;
  switchTab: (id: string) => void;
}

export const TabsKey: InjectionKey<TabsContext> = Symbol('Tabs');
```

```vue
<!-- components/common/tabs/Tabs.vue -->
<script setup lang="ts">
import { ref, provide } from 'vue';
import { TabsKey } from './types';

const activeTab = ref('');
const tabs = ref<{ id: string; label: string }[]>([]);

provide(TabsKey, {
  activeTab,
  registerTab(id: string, label: string) {
    tabs.value.push({ id, label });
    if (!activeTab.value) activeTab.value = id;
  },
  switchTab(id: string) { activeTab.value = id; },
});
</script>

<template>
  <div>
    <nav class="flex border-b" role="tablist">
      <button v-for="tab in tabs" :key="tab.id" role="tab"
              :aria-selected="activeTab === tab.id"
              :class="['px-4 py-2', activeTab === tab.id ? 'border-b-2 border-blue-600 font-semibold' : 'text-gray-500']"
              @click="activeTab = tab.id">
        {{ tab.label }}
      </button>
    </nav>
    <div class="pt-4"><slot /></div>
  </div>
</template>
```

```vue
<!-- components/common/tabs/Tab.vue -->
<script setup lang="ts">
import { inject, onMounted } from 'vue';
import { TabsKey } from './types';

const props = defineProps<{ id: string; label: string }>();
const ctx = inject(TabsKey)!;
onMounted(() => ctx.registerTab(props.id, props.label));
</script>

<template>
  <div v-show="ctx.activeTab.value === id" role="tabpanel"><slot /></div>
</template>
```

---

## 7. Form Handling

### VeeValidate + Zod Integration

```vue
<script setup lang="ts">
import { useForm } from 'vee-validate';
import { toTypedSchema } from '@vee-validate/zod';
import { z } from 'zod';

const schema = toTypedSchema(z.object({
  customer_id: z.number({ required_error: 'Customer is required' }),
  date: z.string().min(1, 'Date is required'),
  due_date: z.string().min(1, 'Due date is required'),
  items: z.array(z.object({
    product_id: z.number(),
    quantity: z.number().positive('Quantity must be positive'),
    price: z.number().min(0, 'Price cannot be negative'),
  })).min(1, 'At least one line item is required'),
}));

const { handleSubmit, errors, resetForm, setFieldError } = useForm({ validationSchema: schema });

const onSubmit = handleSubmit(async (values) => {
  try {
    await api.post('/invoices', values);
  } catch (err: any) {
    if (err.response?.status === 422) {
      for (const [field, messages] of Object.entries(err.response.data.errors)) {
        setFieldError(field, (messages as string[])[0]);
      }
    }
  }
});
</script>
```

---

## 8. Data Tables

### Server-Side DataTable Composable

```typescript
// composables/useDataTable.ts
import { ref, computed, watch } from 'vue';
import type { Ref } from 'vue';

interface Column { key: string; label: string; sortable?: boolean; }
interface FetchResult<T> { data: T[]; meta: { total: number; current_page: number; last_page: number } }
type FetchFn<T> = (params: Record<string, any>) => Promise<FetchResult<T>>;

export function useDataTable<T>(fetchFn: FetchFn<T>, defaultSort = '-created_at') {
  const items: Ref<T[]> = ref([]);
  const loading = ref(false);
  const page = ref(1);
  const perPage = ref(25);
  const total = ref(0);
  const sort = ref(defaultSort);
  const search = ref('');
  const filters = ref<Record<string, any>>({});

  const queryParams = computed(() => ({
    page: page.value,
    per_page: perPage.value,
    sort: sort.value,
    ...(search.value ? { search: search.value } : {}),
    ...filters.value,
  }));

  async function fetch() {
    loading.value = true;
    try {
      const result = await fetchFn(queryParams.value);
      items.value = result.data;
      total.value = result.meta.total;
    } finally {
      loading.value = false;
    }
  }

  function toggleSort(column: string) {
    sort.value = sort.value === column ? `-${column}` : column;
  }

  let debounceTimer: ReturnType<typeof setTimeout>;
  watch(search, () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => { page.value = 1; fetch(); }, 300);
  });
  watch([page, perPage, sort, filters], fetch, { deep: true });

  return { items, loading, page, perPage, total, sort, search, filters, fetch, toggleSort };
}
```

---

## 9. API Integration

### API Service Layer

```typescript
// api/client.ts
import axios from 'axios';
import { useAuthStore } from '@stores/auth';
import { useNotification } from '@composables/useNotification';

const client = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? '/api/v1',
  headers: { Accept: 'application/json' },
  timeout: 30000,
});

client.interceptors.request.use((config) => {
  const auth = useAuthStore();
  if (auth.token) config.headers.Authorization = `Bearer ${auth.token}`;
  return config;
});

client.interceptors.response.use(
  (response) => response,
  (error) => {
    const { notify } = useNotification();
    if (error.response?.status === 401) {
      useAuthStore().logout();
    } else if (error.response?.status === 403) {
      notify({ type: 'error', message: 'You do not have permission for this action.' });
    } else if (error.response?.status === 500) {
      notify({ type: 'error', message: 'Server error. Please try again later.' });
    }
    return Promise.reject(error);
  }
);

export const api = {
  get: <T>(url: string, params?: Record<string, any>) =>
    client.get<T>(url, { params }).then((r) => r.data),
  post: <T>(url: string, data?: unknown) =>
    client.post<T>(url, data).then((r) => r.data),
  put: <T>(url: string, data?: unknown) =>
    client.put<T>(url, data).then((r) => r.data),
  patch: <T>(url: string, data?: unknown) =>
    client.patch<T>(url, data).then((r) => r.data),
  delete: <T>(url: string) =>
    client.delete<T>(url).then((r) => r.data),
};
```

### Endpoint Module Pattern

```typescript
// api/endpoints/invoices.ts
import { api } from '../client';
import type { Invoice, PaginatedResponse, ApiResponse } from '@types';

export const invoiceApi = {
  list: (params?: Record<string, any>) =>
    api.get<PaginatedResponse<Invoice>>('/invoices', params),
  show: (id: number) =>
    api.get<ApiResponse<Invoice>>(`/invoices/${id}`),
  create: (data: Partial<Invoice>) =>
    api.post<ApiResponse<Invoice>>('/invoices', data),
  update: (id: number, data: Partial<Invoice>) =>
    api.put<ApiResponse<Invoice>>(`/invoices/${id}`, data),
  delete: (id: number) =>
    api.delete<void>(`/invoices/${id}`),
  downloadPdf: (id: number) =>
    api.get<Blob>(`/invoices/${id}/pdf`),
};
```

---

## 10. Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { resolve } from 'path';

export default defineConfig(({ mode }) => ({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@components': resolve(__dirname, 'src/components'),
      '@composables': resolve(__dirname, 'src/composables'),
      '@stores': resolve(__dirname, 'src/stores'),
      '@api': resolve(__dirname, 'src/api'),
      '@types': resolve(__dirname, 'src/types'),
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia', 'axios'],
          charts: ['chart.js', 'vue-chartjs'],
        },
      },
    },
    chunkSizeWarningLimit: 500,
  },
  define: {
    __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
  },
}));
```

---

## 11. Testing Components

### Component Test with Vitest and Vue Test Utils

```typescript
// tests/components/InvoiceForm.spec.ts
import { describe, it, expect, vi } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import InvoiceForm from '@/modules/accounting/InvoiceForm.vue';

describe('InvoiceForm', () => {
  function createWrapper(props = {}) {
    return mount(InvoiceForm, {
      props,
      global: {
        plugins: [createTestingPinia({ createSpy: vi.fn })],
        stubs: { CustomerSelect: true, DatePicker: true },
      },
    });
  }

  it('disables submit when form is empty', () => {
    const wrapper = createWrapper();
    const btn = wrapper.find('button[type="submit"]');
    expect(btn.attributes('disabled')).toBeDefined();
  });

  it('emits saved event on successful submission', async () => {
    const wrapper = createWrapper();
    // fill form fields...
    await wrapper.find('form').trigger('submit');
    await flushPromises();
    expect(wrapper.emitted('saved')).toBeTruthy();
  });

  it('displays server validation errors', async () => {
    const wrapper = createWrapper();
    // mock API to return 422...
    await wrapper.find('form').trigger('submit');
    await flushPromises();
    expect(wrapper.find('[data-test="error-customer_id"]').text()).toBe('Customer is required');
  });
});
```

### Composable Test

```typescript
// tests/composables/usePagination.spec.ts
import { describe, it, expect } from 'vitest';
import { usePagination } from '@composables/usePagination';

describe('usePagination', () => {
  it('calculates total pages', () => {
    const { total, perPage, totalPages } = usePagination();
    total.value = 100;
    perPage.value = 25;
    expect(totalPages.value).toBe(4);
  });

  it('prevents going below page 1', () => {
    const { page, prevPage } = usePagination();
    page.value = 1;
    prevPage();
    expect(page.value).toBe(1);
  });
});
```

---

## 12. Performance

### Route-Level Code Splitting

```typescript
// Every route uses dynamic import for automatic code splitting
{ path: '/invoices', component: () => import('@/modules/accounting/InvoiceList.vue') }
```

### Virtual Scrolling for Large Lists

```vue
<script setup lang="ts">
import { RecycleScroller } from 'vue-virtual-scroller';
import 'vue-virtual-scroller/dist/vue-virtual-scroller.css';
</script>

<template>
  <RecycleScroller :items="largeList" :item-size="48" key-field="id" v-slot="{ item }">
    <div class="flex items-center h-12 px-4 border-b">
      {{ item.name }}
    </div>
  </RecycleScroller>
</template>
```

### Debounced Search Input

```vue
<script setup lang="ts">
import { ref, watch } from 'vue';

const searchInput = ref('');
const debouncedSearch = ref('');

let timer: ReturnType<typeof setTimeout>;
watch(searchInput, (val) => {
  clearTimeout(timer);
  timer = setTimeout(() => { debouncedSearch.value = val; }, 300);
});
</script>

<template>
  <input v-model="searchInput" type="search" placeholder="Search..."
         aria-label="Search" class="w-full rounded border px-3 py-2" />
</template>
```

### Performance Checklist

- Use `v-once` for static content that never changes
- Use `v-memo` for list items with expensive renders
- Prefer `shallowRef` for large objects where deep reactivity is unnecessary
- Lazy-load images with `loading="lazy"` attribute
- Use `defineAsyncComponent` for heavy components below the fold
- Keep initial JS bundle under 200KB gzipped via manual chunks in Vite config
- Avoid watchers on large reactive objects; watch specific properties instead

---

## 13. TypeScript Integration

### Typed Props and Emits

```vue
<script setup lang="ts">
interface Props {
  modelValue: string;
  label: string;
  error?: string;
  required?: boolean;
  disabled?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  required: false,
  disabled: false,
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void;
  (e: 'blur'): void;
}>();
</script>
```

### Generic Components

```vue
<script setup lang="ts" generic="T extends { id: number; name: string }">
defineProps<{
  items: T[];
  selected?: T;
  labelKey?: keyof T;
}>();

defineEmits<{
  (e: 'select', item: T): void;
}>();
</script>
```

### Typed Composable Return

```typescript
interface UseLoadingReturn {
  loading: Ref<boolean>;
  error: Ref<string | null>;
  execute: <T>(fn: () => Promise<T>) => Promise<T | undefined>;
}

export function useLoading(): UseLoadingReturn {
  const loading = ref(false);
  const error = ref<string | null>(null);

  async function execute<T>(fn: () => Promise<T>): Promise<T | undefined> {
    loading.value = true;
    error.value = null;
    try {
      return await fn();
    } catch (e: any) {
      error.value = e.message ?? 'An error occurred';
      return undefined;
    } finally {
      loading.value = false;
    }
  }

  return { loading, error, execute };
}
```

### Shared Type Definitions

```typescript
// types/models.ts
export interface Invoice {
  id: number;
  branch_id: number;
  customer_id: number;
  invoice_number: string;
  date: string;
  due_date: string;
  status: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled';
  subtotal: number;
  tax: number;
  total: number;
  items: InvoiceItem[];
  customer?: Customer;
  created_at: string;
  updated_at: string;
}

// types/api.ts
export interface ApiResponse<T> { data: T; }
export interface PaginatedResponse<T> {
  data: T[];
  meta: { total: number; current_page: number; last_page: number; per_page: number };
  links: { next: string | null; prev: string | null };
}
export interface ApiError {
  message: string;
  errors?: Record<string, string[]>;
}
```
