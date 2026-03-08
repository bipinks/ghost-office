---
name: frontend-patterns
description: Use when building frontend components, pages, or client-side logic. Covers Vue 3 Composition API, TypeScript patterns, component design, state management, form handling, data tables, and responsive layouts for enterprise applications.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Frontend Patterns -- Platform Development

## Vue 3 Component (Composition API)

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type { Invoice } from '@/types';
import { useInvoiceStore } from '@/stores/invoice';
import { useNotification } from '@/composables/useNotification';

const props = defineProps<{ invoiceId?: number; readonly?: boolean }>();
const emit = defineEmits<{ (e: 'saved', invoice: Invoice): void; (e: 'cancelled'): void }>();

const store = useInvoiceStore();
const { notify } = useNotification();
const loading = ref(false);
const form = ref<Partial<Invoice>>({ customer_id: null, date: new Date().toISOString().split('T')[0], items: [] });

const subtotal = computed(() => form.value.items?.reduce((s, i) => s + i.quantity * i.price, 0) ?? 0);
const isValid = computed(() => form.value.customer_id && form.value.items?.length > 0);

async function save() {
  if (!isValid.value) return;
  loading.value = true;
  try {
    const invoice = await store.createInvoice(form.value);
    notify({ type: 'success', message: 'Invoice created' });
    emit('saved', invoice);
  } catch (error) { notify({ type: 'error', message: error.message }); }
  finally { loading.value = false; }
}

onMounted(async () => { if (props.invoiceId) form.value = await store.fetchInvoice(props.invoiceId); });
</script>

<template>
  <form @submit.prevent="save" class="space-y-6">
    <CustomerSelect v-model="form.customer_id" :disabled="readonly" />
    <LineItemsTable v-model="form.items" :readonly="readonly" />
    <div class="flex justify-between">
      <p class="font-bold">Total: {{ formatCurrency(subtotal) }}</p>
      <div class="space-x-3">
        <button type="button" @click="emit('cancelled')" class="btn-secondary">Cancel</button>
        <button type="submit" :disabled="!isValid || loading" class="btn-primary">
          {{ loading ? 'Saving...' : 'Save' }}
        </button>
      </div>
    </div>
  </form>
</template>
```

## Composable Pattern (useDataTable)

```typescript
export function useDataTable<T>(options: {
  fetchFn: (params: Record<string, any>) => Promise<{ data: T[]; meta: { total: number } }>;
  defaultSort?: string; defaultPerPage?: number;
}) {
  const items = ref<T[]>([]), loading = ref(false), total = ref(0);
  const page = ref(1), perPage = ref(options.defaultPerPage ?? 25);
  const sortBy = ref(options.defaultSort ?? 'created_at'), sortDesc = ref(true);
  const search = ref(''), filters = ref<Record<string, any>>({});

  const params = computed(() => ({
    page: page.value, per_page: perPage.value,
    sort: sortDesc.value ? `-${sortBy.value}` : sortBy.value,
    search: search.value || undefined, ...filters.value,
  }));

  async function fetch() {
    loading.value = true;
    try { const r = await options.fetchFn(params.value); items.value = r.data; total.value = r.meta.total; }
    finally { loading.value = false; }
  }

  let timer: ReturnType<typeof setTimeout>;
  watch(search, () => { clearTimeout(timer); timer = setTimeout(() => { page.value = 1; fetch(); }, 300); });
  watch([page, perPage, sortBy, sortDesc, filters], fetch, { deep: true });

  return { items, loading, total, page, perPage, sortBy, sortDesc, search, filters, fetch };
}
```

## API Client

```typescript
import axios from 'axios';
const client = axios.create({ baseURL: '/api/v1', headers: { 'Content-Type': 'application/json' } });

client.interceptors.request.use((c) => {
  const token = localStorage.getItem('auth_token');
  if (token) c.headers.Authorization = `Bearer ${token}`;
  return c;
});
client.interceptors.response.use(r => r, (e) => {
  if (e.response?.status === 401) { localStorage.removeItem('auth_token'); window.location.href = '/login'; }
  return Promise.reject(e);
});

export const api = {
  get: <T>(url: string, params?: any): Promise<T> => client.get(url, { params }).then(r => r.data),
  post: <T>(url: string, data?: any): Promise<T> => client.post(url, data).then(r => r.data),
  put: <T>(url: string, data?: any): Promise<T> => client.put(url, data).then(r => r.data),
  delete: <T>(url: string): Promise<T> => client.delete(url).then(r => r.data),
};
```

## Pinia Store

```typescript
export const useInvoiceStore = defineStore('invoice', {
  state: () => ({ invoices: [] as Invoice[], currentInvoice: null as Invoice | null, loading: false }),
  actions: {
    async fetchInvoices(filters?: InvoiceFilters) {
      this.loading = true;
      try { const r = await api.get<{ data: Invoice[] }>('/invoices', filters); this.invoices = r.data; return r; }
      finally { this.loading = false; }
    },
    async createInvoice(data: Partial<Invoice>): Promise<Invoice> {
      const r = await api.post<{ data: Invoice }>('/invoices', data);
      this.invoices.unshift(r.data);
      return r.data;
    },
  },
});
```

## Form Validation Composable

```typescript
type Rule = (value: any) => string | true;
const required: Rule = (v) => (v != null && v !== '') || 'Required';
const email: Rule = (v) => !v || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) || 'Invalid email';
const min = (n: number): Rule => (v) => !v || v.length >= n || `Min ${n} chars`;

export function useFormValidation<T extends Record<string, any>>(form: T, rules: Partial<Record<keyof T, Rule[]>>) {
  const errors = ref<Partial<Record<keyof T, string>>>({});
  function validate(): boolean {
    errors.value = {};
    for (const [field, fieldRules] of Object.entries(rules))
      for (const rule of fieldRules as Rule[]) {
        const r = rule(form[field as keyof T]);
        if (r !== true) { errors.value[field as keyof T] = r; break; }
      }
    return Object.keys(errors.value).length === 0;
  }
  return { errors, validate, rules: { required, email, min } };
}
```

## Performance Rules

- **Code splitting**: `() => import('@/pages/Invoices.vue')` per route
- **Virtual scrolling**: Lists > 100 items (`vue-virtual-scroller`)
- **Debounce search**: 300ms
- **Memoize**: Use `computed` for derived state
- **Images**: WebP, `loading="lazy"`
- **Bundle**: < 200KB gzipped initial
- **SFC limit**: Max 300 lines; extract composables for logic

## File Structure

```
src/
  api/          -- Client and endpoint definitions
  components/   -- Shared (forms/, layout/, data/)
  composables/  -- Reusable logic (useDataTable, useAuth)
  pages/        -- Route-level components by module
  router/       -- Vue Router config
  stores/       -- Pinia stores per module
  types/        -- TypeScript interfaces
  utils/        -- Helpers (formatCurrency, formatDate)
```
