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
├── api/              -- Client, interceptors, endpoint modules
├── components/
│   ├── common/       -- Button, Modal, Alert, Spinner
│   ├── forms/        -- FormInput, FormSelect, DatePicker
│   ├── layout/       -- AppLayout, Sidebar, Header
│   └── data/         -- DataTable, Pagination, ChartWrapper
├── composables/      -- useAuth, usePagination, useForm, useBranchScope
├── modules/          -- Feature modules (accounting/, inventory/, hr/, sales/)
├── router/           -- Route definitions and guards
├── stores/           -- Pinia stores (auth, branch, ui)
├── types/            -- TypeScript interfaces and enums
├── utils/            -- Pure helpers (formatters, validators)
└── main.ts
```

Path aliases: `@/*` -> `src/*`, `@components/*`, `@composables/*`, `@stores/*`, `@api/*`, `@types/*` in tsconfig and vite config.

---

## 2. Reactivity Quick Reference

```typescript
// ref -- single value (.value in script, unwrapped in template)
const count = ref(0);
const invoice = ref<Invoice | null>(null);

// reactive -- object (no .value, cannot reassign root)
const filters = reactive<Filters>({ status: 'all', search: '' });

// computed -- derived, cached
const unpaidTotal = computed(() => invoices.value.filter(i => i.status === 'unpaid').reduce((s, i) => s + i.total, 0));

// watch specific source; watchEffect auto-tracks
watch(() => filters.status, (val) => { page.value = 1; fetchInvoices(); });
watch([() => filters.status, () => filters.search], () => fetchInvoices());

// toRefs -- destructure reactive without losing reactivity
const { status, search } = toRefs(filters);
```

Lifecycle: `onMounted` (fetch data, attach listeners), `onUnmounted` (cleanup listeners, abort requests).

---

## 3. Key Composables

### useForm (generic form with validation + 422 handling)

```typescript
export function useForm<T extends Record<string, any>>(opts: {
  initialValues: T; onSubmit: (v: T) => Promise<void>; validate?: (v: T) => Record<string, string>;
}) {
  const values = reactive<T>({ ...opts.initialValues }) as T;
  const errors = ref<Record<string, string>>({});
  const submitting = ref(false);
  const isDirty = computed(() => JSON.stringify(values) !== JSON.stringify(opts.initialValues));

  async function submit() {
    errors.value = {};
    if (opts.validate) { const e = opts.validate(values); if (Object.keys(e).length) { errors.value = e; return; } }
    submitting.value = true;
    try { await opts.onSubmit(values); }
    catch (err: any) {
      if (err.response?.status === 422 && err.response.data?.errors)
        for (const [k, v] of Object.entries(err.response.data.errors))
          errors.value[k] = Array.isArray(v) ? v[0] : v as string;
      else throw err;
    } finally { submitting.value = false; }
  }
  function reset() { Object.assign(values, opts.initialValues); errors.value = {}; }
  return { values, errors, submitting, isDirty, submit, reset };
}
```

### useBranchScope (multi-tenant context)

```typescript
export function useBranchScope() {
  const store = useBranchStore();
  const branchId = computed(() => store.currentBranch?.id);
  function switchBranch(id: number) { store.setBranch(id); }
  function onBranchChange(cb: (id: number) => void) { watch(branchId, (v) => { if (v) cb(v); }); }
  return { branchId, branches: computed(() => store.branches), switchBranch, onBranchChange };
}
```

---

## 4. Pinia Store Pattern

```typescript
export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({ user: null, token: localStorage.getItem('auth_token'), permissions: [] }),
  getters: {
    isAuthenticated: (s) => !!s.token,
    hasPermission: (s) => (p: string) => s.permissions.includes(p),
  },
  actions: {
    async login(payload: LoginPayload) {
      const { data } = await api.post<{ data: { user: User; token: string } }>('/auth/login', payload);
      this.user = data.user; this.token = data.token; this.permissions = data.user.permissions ?? [];
      localStorage.setItem('auth_token', data.token);
    },
    async logout() {
      try { await api.post('/auth/logout'); } catch {}
      this.$reset(); localStorage.removeItem('auth_token');
    },
  },
});
```

---

## 5. Router with Auth Guards

```typescript
const routes: RouteRecordRaw[] = [
  { path: '/login', name: 'login', component: () => import('@/modules/auth/LoginPage.vue'), meta: { guest: true } },
  {
    path: '/', component: () => import('@/components/layout/AppLayout.vue'), meta: { requiresAuth: true },
    children: [
      { path: '', name: 'dashboard', component: () => import('@/modules/dashboard/DashboardPage.vue') },
      { path: 'invoices', children: [
        { path: '', name: 'invoices.index', component: () => import('@/modules/accounting/InvoiceList.vue'), meta: { permission: 'invoices.view' } },
        { path: 'create', name: 'invoices.create', component: () => import('@/modules/accounting/InvoiceForm.vue'), meta: { permission: 'invoices.create' } },
        { path: ':id', name: 'invoices.show', component: () => import('@/modules/accounting/InvoiceDetail.vue'), props: true },
      ]},
    ],
  },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/modules/errors/NotFound.vue') },
];

// Guard: redirect unauth to login, check permission meta, set document.title
router.beforeEach(async (to) => {
  const auth = useAuthStore();
  if (to.meta.requiresAuth && !auth.isAuthenticated) return { name: 'login', query: { redirect: to.fullPath } };
  if (to.meta.guest && auth.isAuthenticated) return { name: 'dashboard' };
  if (to.meta.permission && !auth.hasPermission(to.meta.permission as string)) return { name: 'dashboard' };
});
```

---

## 6. Component Patterns

### Renderless (Slot-Based Logic)

```vue
<script setup lang="ts" generic="T">
const props = defineProps<{ url: string }>();
const data = ref<T | null>(null); const loading = ref(false); const error = ref<string | null>(null);
async function execute() { /* fetch props.url, set data/error/loading */ }
onMounted(execute);
</script>
<template><slot :data="data" :loading="loading" :error="error" :refresh="execute" /></template>
```

### Typed Props + Emits

```vue
<script setup lang="ts">
const props = withDefaults(defineProps<{ modelValue: string; label: string; error?: string; required?: boolean }>(), { required: false });
const emit = defineEmits<{ (e: 'update:modelValue', value: string): void }>();
</script>
```

### Generic Components

```vue
<script setup lang="ts" generic="T extends { id: number; name: string }">
defineProps<{ items: T[]; selected?: T }>();
defineEmits<{ (e: 'select', item: T): void }>();
</script>
```

### Provide/Inject for Compound Components

Use `InjectionKey<Context>` symbol, provide from parent (Tabs), inject in children (Tab). Enables clean compound APIs like `<Tabs><Tab id="a" label="A">...</Tab></Tabs>`.

---

## 7. API Client

```typescript
const client = axios.create({ baseURL: import.meta.env.VITE_API_URL ?? '/api/v1', timeout: 30000 });
client.interceptors.request.use((c) => { const t = useAuthStore().token; if (t) c.headers.Authorization = `Bearer ${t}`; return c; });
client.interceptors.response.use((r) => r, (err) => {
  if (err.response?.status === 401) useAuthStore().logout();
  return Promise.reject(err);
});

// Endpoint module pattern
export const invoiceApi = {
  list: (params?: Record<string, any>) => api.get<PaginatedResponse<Invoice>>('/invoices', params),
  show: (id: number) => api.get<ApiResponse<Invoice>>(`/invoices/${id}`),
  create: (data: Partial<Invoice>) => api.post<ApiResponse<Invoice>>('/invoices', data),
  update: (id: number, data: Partial<Invoice>) => api.put<ApiResponse<Invoice>>(`/invoices/${id}`, data),
  delete: (id: number) => api.delete<void>(`/invoices/${id}`),
};
```

---

## 8. Server-Side DataTable Composable

```typescript
export function useDataTable<T>(fetchFn: FetchFn<T>, defaultSort = '-created_at') {
  const items = ref<T[]>([]); const loading = ref(false);
  const page = ref(1); const perPage = ref(25); const total = ref(0);
  const sort = ref(defaultSort); const search = ref(''); const filters = ref<Record<string, any>>({});

  async function fetch() {
    loading.value = true;
    try { const r = await fetchFn({ page: page.value, per_page: perPage.value, sort: sort.value, ...filters.value }); items.value = r.data; total.value = r.meta.total; }
    finally { loading.value = false; }
  }
  function toggleSort(col: string) { sort.value = sort.value === col ? `-${col}` : col; }

  // Debounce search 300ms, watch page/sort/filters
  watch(search, () => { clearTimeout(t); t = setTimeout(() => { page.value = 1; fetch(); }, 300); });
  watch([page, perPage, sort, filters], fetch, { deep: true });
  return { items, loading, page, perPage, total, sort, search, filters, fetch, toggleSort };
}
```

---

## 9. Vite Config Essentials

```typescript
export default defineConfig({
  plugins: [vue()],
  resolve: { alias: { '@': resolve(__dirname, 'src') } },
  server: { proxy: { '/api': { target: 'http://localhost:8000', changeOrigin: true } } },
  build: {
    rollupOptions: { output: { manualChunks: { vendor: ['vue', 'vue-router', 'pinia', 'axios'] } } },
    chunkSizeWarningLimit: 500,
  },
});
```

---

## 10. Testing

```typescript
// Component test (Vitest + Vue Test Utils)
const wrapper = mount(InvoiceForm, {
  props: { customerId: 1 },
  global: { plugins: [createTestingPinia({ createSpy: vi.fn })] },
});
expect(wrapper.find('[data-testid="add-item"]').exists()).toBe(true);

// Composable test
const { total, perPage, totalPages } = usePagination();
total.value = 100; perPage.value = 25;
expect(totalPages.value).toBe(4);
```

---

## 11. Performance Checklist

- Route-level code splitting: `component: () => import(...)` on every route
- Virtual scrolling for lists > 100 items (`vue-virtual-scroller`)
- Debounce search inputs (300ms), throttle scroll events (100ms)
- `v-once` for static content, `v-memo` for expensive list items
- `shallowRef` for large objects without deep reactivity
- `defineAsyncComponent` for heavy below-fold components
- Manual chunks in Vite for vendor splitting
- Initial bundle target: < 200KB gzipped

---

## 12. Type Definitions

```typescript
// types/models.ts
export interface Invoice {
  id: number; branch_id: number; customer_id: number; invoice_number: string;
  date: string; due_date: string; status: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled';
  subtotal: number; tax: number; total: number; items: InvoiceItem[]; customer?: Customer;
}

// types/api.ts
export interface ApiResponse<T> { data: T; }
export interface PaginatedResponse<T> {
  data: T[]; meta: { total: number; current_page: number; last_page: number; per_page: number };
  links: { next: string | null; prev: string | null };
}
```
