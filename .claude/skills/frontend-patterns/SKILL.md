---
name: frontend-patterns
description: Use when building ERP frontend components, pages, or client-side logic. Covers Vue 3 Composition API, TypeScript patterns, component design, state management, form handling, data tables, and responsive layouts for enterprise applications.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Frontend Patterns — ERP Platform

## Vue 3 Component Pattern (Composition API)

```vue
<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import type { Invoice, LineItem } from '@/types';
import { useInvoiceStore } from '@/stores/invoice';
import { useNotification } from '@/composables/useNotification';

// Props & Emits
const props = defineProps<{
  invoiceId?: number;
  readonly?: boolean;
}>();

const emit = defineEmits<{
  (e: 'saved', invoice: Invoice): void;
  (e: 'cancelled'): void;
}>();

// State
const store = useInvoiceStore();
const { notify } = useNotification();
const loading = ref(false);
const form = ref<Partial<Invoice>>({
  customer_id: null,
  date: new Date().toISOString().split('T')[0],
  due_date: '',
  items: [],
});

// Computed
const subtotal = computed(() =>
  form.value.items?.reduce((sum, item) => sum + item.quantity * item.price, 0) ?? 0
);
const tax = computed(() => subtotal.value * 0.05);
const total = computed(() => subtotal.value + tax.value);
const isValid = computed(() =>
  form.value.customer_id && form.value.items?.length > 0
);

// Methods
async function save() {
  if (!isValid.value) return;
  loading.value = true;
  try {
    const invoice = await store.createInvoice(form.value);
    notify({ type: 'success', message: 'Invoice created' });
    emit('saved', invoice);
  } catch (error) {
    notify({ type: 'error', message: error.message });
  } finally {
    loading.value = false;
  }
}

// Lifecycle
onMounted(async () => {
  if (props.invoiceId) {
    form.value = await store.fetchInvoice(props.invoiceId);
  }
});
</script>

<template>
  <form @submit.prevent="save" class="space-y-6">
    <CustomerSelect v-model="form.customer_id" :disabled="readonly" />
    <DatePicker v-model="form.date" label="Invoice Date" />
    <LineItemsTable v-model="form.items" :readonly="readonly" />

    <div class="flex justify-between items-center">
      <div class="text-right">
        <p>Subtotal: {{ formatCurrency(subtotal) }}</p>
        <p>Tax (5%): {{ formatCurrency(tax) }}</p>
        <p class="font-bold text-lg">Total: {{ formatCurrency(total) }}</p>
      </div>
      <div class="space-x-3">
        <button type="button" @click="emit('cancelled')" class="btn-secondary">Cancel</button>
        <button type="submit" :disabled="!isValid || loading" class="btn-primary">
          {{ loading ? 'Saving...' : 'Save Invoice' }}
        </button>
      </div>
    </div>
  </form>
</template>
```

## Composable Pattern (Reusable Logic)

```typescript
// composables/useDataTable.ts
import { ref, computed, watch } from 'vue';
import type { Ref } from 'vue';

interface DataTableOptions<T> {
  fetchFn: (params: Record<string, any>) => Promise<{ data: T[]; meta: { total: number } }>;
  defaultSort?: string;
  defaultPerPage?: number;
}

export function useDataTable<T>(options: DataTableOptions<T>) {
  const items: Ref<T[]> = ref([]);
  const loading = ref(false);
  const total = ref(0);
  const page = ref(1);
  const perPage = ref(options.defaultPerPage ?? 25);
  const sortBy = ref(options.defaultSort ?? 'created_at');
  const sortDesc = ref(true);
  const search = ref('');
  const filters = ref<Record<string, any>>({});

  const params = computed(() => ({
    page: page.value,
    per_page: perPage.value,
    sort: sortDesc.value ? `-${sortBy.value}` : sortBy.value,
    search: search.value || undefined,
    ...filters.value,
  }));

  async function fetch() {
    loading.value = true;
    try {
      const result = await options.fetchFn(params.value);
      items.value = result.data;
      total.value = result.meta.total;
    } finally {
      loading.value = false;
    }
  }

  // Debounced search
  let searchTimer: ReturnType<typeof setTimeout>;
  watch(search, () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      page.value = 1;
      fetch();
    }, 300);
  });

  watch([page, perPage, sortBy, sortDesc, filters], fetch, { deep: true });

  return { items, loading, total, page, perPage, sortBy, sortDesc, search, filters, fetch };
}
```

## API Client Pattern

```typescript
// api/client.ts
import axios from 'axios';
import type { AxiosInstance, AxiosResponse } from 'axios';

const API_BASE_URL = '/api/v1';

const client: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
});

// Auto-attach auth token
client.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Global error handling
client.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('auth_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Typed API methods
export const api = {
  get: <T>(url: string, params?: Record<string, any>): Promise<T> =>
    client.get(url, { params }).then((r: AxiosResponse<T>) => r.data),
  post: <T>(url: string, data?: any): Promise<T> =>
    client.post(url, data).then((r: AxiosResponse<T>) => r.data),
  put: <T>(url: string, data?: any): Promise<T> =>
    client.put(url, data).then((r: AxiosResponse<T>) => r.data),
  delete: <T>(url: string): Promise<T> =>
    client.delete(url).then((r: AxiosResponse<T>) => r.data),
};
```

## Pinia Store Pattern

```typescript
// stores/invoice.ts
import { defineStore } from 'pinia';
import { api } from '@/api/client';
import type { Invoice, InvoiceFilters } from '@/types';

export const useInvoiceStore = defineStore('invoice', {
  state: () => ({
    invoices: [] as Invoice[],
    currentInvoice: null as Invoice | null,
    loading: false,
  }),

  actions: {
    async fetchInvoices(filters?: InvoiceFilters) {
      this.loading = true;
      try {
        const result = await api.get<{ data: Invoice[] }>('/invoices', filters);
        this.invoices = result.data;
        return result;
      } finally {
        this.loading = false;
      }
    },

    async fetchInvoice(id: number): Promise<Invoice> {
      const result = await api.get<{ data: Invoice }>(`/invoices/${id}`);
      this.currentInvoice = result.data;
      return result.data;
    },

    async createInvoice(data: Partial<Invoice>): Promise<Invoice> {
      const result = await api.post<{ data: Invoice }>('/invoices', data);
      this.invoices.unshift(result.data);
      return result.data;
    },
  },
});
```

## Form Validation Pattern

```typescript
// composables/useFormValidation.ts
import { ref, computed } from 'vue';

type Rule = (value: any) => string | true;

const required: Rule = (v) => (v !== null && v !== undefined && v !== '') || 'Required';
const email: Rule = (v) => !v || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) || 'Invalid email';
const min = (n: number): Rule => (v) => !v || v.length >= n || `Minimum ${n} characters`;
const numeric: Rule = (v) => !v || !isNaN(Number(v)) || 'Must be a number';
const positive: Rule = (v) => !v || Number(v) > 0 || 'Must be positive';

export function useFormValidation<T extends Record<string, any>>(
  form: T,
  rules: Partial<Record<keyof T, Rule[]>>
) {
  const errors = ref<Partial<Record<keyof T, string>>>({});

  function validate(): boolean {
    errors.value = {};
    let valid = true;
    for (const [field, fieldRules] of Object.entries(rules)) {
      for (const rule of (fieldRules as Rule[])) {
        const result = rule(form[field as keyof T]);
        if (result !== true) {
          errors.value[field as keyof T] = result;
          valid = false;
          break;
        }
      }
    }
    return valid;
  }

  const isValid = computed(() => Object.keys(errors.value).length === 0);

  return { errors, validate, isValid, rules: { required, email, min, numeric, positive } };
}
```

## Data Table Component Pattern

```vue
<!-- components/DataTable.vue -->
<script setup lang="ts" generic="T extends { id: number }">
defineProps<{
  columns: { key: string; label: string; sortable?: boolean; align?: string }[];
  items: T[];
  loading: boolean;
  total: number;
  page: number;
  perPage: number;
}>();

defineEmits<{
  (e: 'update:page', value: number): void;
  (e: 'update:perPage', value: number): void;
  (e: 'sort', column: string): void;
  (e: 'row-click', item: T): void;
}>();
</script>

<template>
  <div class="overflow-x-auto">
    <table class="min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
        <tr>
          <th v-for="col in columns" :key="col.key"
              :class="['px-6 py-3 text-xs font-medium text-gray-500 uppercase', col.align ?? 'text-left']"
              @click="col.sortable && $emit('sort', col.key)">
            {{ col.label }}
            <span v-if="col.sortable" class="ml-1 cursor-pointer">⇅</span>
          </th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        <tr v-if="loading">
          <td :colspan="columns.length" class="text-center py-8">Loading...</td>
        </tr>
        <tr v-else-if="items.length === 0">
          <td :colspan="columns.length" class="text-center py-8 text-gray-400">No data</td>
        </tr>
        <tr v-for="item in items" :key="item.id"
            class="hover:bg-gray-50 cursor-pointer"
            @click="$emit('row-click', item)">
          <slot name="row" :item="item">
            <td v-for="col in columns" :key="col.key" class="px-6 py-4 whitespace-nowrap">
              {{ item[col.key as keyof T] }}
            </td>
          </slot>
        </tr>
      </tbody>
    </table>
    <Pagination :page="page" :per-page="perPage" :total="total"
                @update:page="$emit('update:page', $event)"
                @update:per-page="$emit('update:perPage', $event)" />
  </div>
</template>
```

## Performance Rules

- **Code splitting**: Lazy-load routes with `() => import('@/pages/Invoices.vue')`
- **Virtual scrolling**: Use for lists > 100 items (`vue-virtual-scroller`)
- **Debounce search**: 300ms delay on search inputs
- **Memoize**: Use `computed` for derived state, avoid recalculating in templates
- **Image optimization**: WebP format, lazy loading with `loading="lazy"`
- **Bundle size**: Keep initial bundle < 200KB gzipped
- **Component size**: Max 300 lines per SFC — extract composables for logic

## File Structure

```
src/
├── api/            — API client and endpoint definitions
├── assets/         — Static assets (images, fonts, global CSS)
├── components/     — Shared/reusable components
│   ├── forms/      — Form inputs (DatePicker, Select, etc.)
│   ├── layout/     — Shell, Sidebar, Navbar
│   └── data/       — DataTable, Charts, Cards
├── composables/    — Reusable logic (useDataTable, useAuth, etc.)
├── pages/          — Route-level page components
│   ├── invoices/   — Invoice CRUD pages
│   ├── inventory/  — Inventory pages
│   └── ...
├── router/         — Vue Router configuration
├── stores/         — Pinia stores per module
├── types/          — TypeScript interfaces and enums
└── utils/          — Helpers (formatCurrency, formatDate, etc.)
```
