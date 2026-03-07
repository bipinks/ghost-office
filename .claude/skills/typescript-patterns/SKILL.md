---
name: typescript-patterns
description: Use when writing TypeScript code for frontend or backend. Covers type system fundamentals, generics, utility types, discriminated unions, type guards, declaration files, strict mode patterns, and enterprise TypeScript architecture.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# TypeScript Patterns — Enterprise Development

## 1. Type System Fundamentals

### Interfaces vs Types

Use **interfaces** for object shapes that may be extended. Use **types** for unions, intersections, and computed types.

```typescript
// Interface — extendable, mergeable
interface Customer {
  id: number;
  name: string;
  email: string;
}

interface PremiumCustomer extends Customer {
  discountRate: number;
  accountManager: string;
}

// Type — unions, intersections, mapped
type Status = 'draft' | 'pending' | 'approved' | 'rejected';
type Nullable<T> = T | null;
type ReadonlyCustomer = Readonly<Customer>;
type CustomerOrVendor = Customer | Vendor;
```

### Literal Types and Template Literals

```typescript
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
type Environment = 'local' | 'staging' | 'production';

// Template literal types
type ApiEndpoint = `/api/v1/${string}`;
type EventName = `on${Capitalize<string>}`;
type BranchColumn = `${string}_branch_id`;

// Computed keys from unions
type StatusLabel = `${Status}Label`; // 'draftLabel' | 'pendingLabel' | ...
```

## 2. Generics

### Generic Functions and Constraints

```typescript
// Basic generic function
function first<T>(items: T[]): T | undefined {
  return items[0];
}

// Constrained generic — T must have an id
function findById<T extends { id: number }>(items: T[], id: number): T | undefined {
  return items.find((item) => item.id === id);
}

// Multiple constraints
function merge<T extends object, U extends object>(target: T, source: U): T & U {
  return { ...target, ...source };
}

// Generic with default
function createList<T = string>(): T[] {
  return [];
}
```

### Conditional Types and Infer

```typescript
// Conditional type
type IsArray<T> = T extends any[] ? true : false;

// Infer — extract inner type
type ElementOf<T> = T extends (infer E)[] ? E : never;
type Unwrap<T> = T extends Promise<infer U> ? U : T;

// Practical example: extract response data type from API function
type ApiReturn<T extends (...args: any) => Promise<any>> =
  T extends (...args: any) => Promise<{ data: infer D }> ? D : never;

// Usage
async function fetchInvoices(): Promise<{ data: Invoice[] }> { /* ... */ }
type Invoices = ApiReturn<typeof fetchInvoices>; // Invoice[]
```

### Generic Classes

```typescript
class Repository<T extends { id: number; branch_id: number }> {
  private items: T[] = [];

  findById(id: number): T | undefined {
    return this.items.find((item) => item.id === id);
  }

  filterByBranch(branchId: number): T[] {
    return this.items.filter((item) => item.branch_id === branchId);
  }

  create(item: Omit<T, 'id'>): T {
    const newItem = { ...item, id: Date.now() } as T;
    this.items.push(newItem);
    return newItem;
  }
}
```

## 3. Utility Types

```typescript
interface Invoice {
  id: number;
  customer_id: number;
  date: string;
  due_date: string;
  status: Status;
  total: number;
  notes?: string;
  branch_id: number;
}

// Partial — all fields optional (useful for update payloads)
type InvoiceUpdate = Partial<Invoice>;

// Required — all fields required (remove optional markers)
type StrictInvoice = Required<Invoice>;

// Pick — select specific fields
type InvoiceSummary = Pick<Invoice, 'id' | 'date' | 'status' | 'total'>;

// Omit — exclude fields (useful for creation payloads)
type CreateInvoice = Omit<Invoice, 'id' | 'branch_id'>;

// Record — typed key-value maps
type StatusCounts = Record<Status, number>;
type ModulePermissions = Record<string, boolean>;

// Extract / Exclude — filter union members
type ActiveStatus = Extract<Status, 'pending' | 'approved'>; // 'pending' | 'approved'
type NonFinalStatus = Exclude<Status, 'approved' | 'rejected'>; // 'draft' | 'pending'

// ReturnType — extract function return type
type ServiceResult = ReturnType<typeof invoiceService.create>;

// Parameters — extract function parameter types
type CreateParams = Parameters<typeof invoiceService.create>;
```

## 4. Discriminated Unions

### Tagged Unions for API Responses

```typescript
type ApiResponse<T> =
  | { status: 'success'; data: T; meta?: PaginationMeta }
  | { status: 'error'; message: string; errors?: Record<string, string[]> }
  | { status: 'loading' };

function handleResponse<T>(response: ApiResponse<T>): void {
  switch (response.status) {
    case 'success':
      console.log(response.data); // T is accessible, narrowed
      break;
    case 'error':
      console.error(response.message); // message is accessible
      break;
    case 'loading':
      // no data or message available — type-safe
      break;
  }
}
```

### State Machines

```typescript
type InvoiceState =
  | { status: 'draft'; editedBy: number }
  | { status: 'pending_approval'; submittedAt: string; submittedBy: number }
  | { status: 'approved'; approvedAt: string; approvedBy: number }
  | { status: 'rejected'; rejectedAt: string; reason: string }
  | { status: 'paid'; paidAt: string; paymentRef: string };

function getNextActions(state: InvoiceState): string[] {
  switch (state.status) {
    case 'draft': return ['submit', 'delete'];
    case 'pending_approval': return ['approve', 'reject'];
    case 'approved': return ['record_payment', 'void'];
    case 'rejected': return ['resubmit', 'delete'];
    case 'paid': return ['refund'];
  }
}
```

## 5. Type Guards

### Custom Type Guards with `is`

```typescript
interface Customer { type: 'customer'; creditLimit: number }
interface Vendor { type: 'vendor'; paymentTerms: number }
type Contact = Customer | Vendor;

function isCustomer(contact: Contact): contact is Customer {
  return contact.type === 'customer';
}

function isVendor(contact: Contact): contact is Vendor {
  return contact.type === 'vendor';
}

// Usage
function getTerms(contact: Contact): string {
  if (isCustomer(contact)) {
    return `Credit limit: ${contact.creditLimit}`; // narrowed to Customer
  }
  return `Payment terms: ${contact.paymentTerms} days`; // narrowed to Vendor
}
```

### The `in` Operator and Assertion Functions

```typescript
// in operator — check property existence
function formatContact(contact: Customer | Vendor): string {
  if ('creditLimit' in contact) {
    return `Customer (limit: ${contact.creditLimit})`;
  }
  return `Vendor (terms: ${contact.paymentTerms}d)`;
}

// Assertion function — throws if condition fails
function assertDefined<T>(value: T | null | undefined, name: string): asserts value is T {
  if (value === null || value === undefined) {
    throw new Error(`Expected ${name} to be defined`);
  }
}

// Usage
const invoice = await fetchInvoice(id);
assertDefined(invoice, 'invoice'); // throws or narrows
console.log(invoice.total); // safely narrowed to Invoice
```

## 6. Mapped Types

### Custom Mapped Types

```typescript
// Make all properties nullable
type NullableProps<T> = { [K in keyof T]: T[K] | null };

// Make all properties into form fields
type FormFields<T> = {
  [K in keyof T]: {
    value: T[K];
    error: string | null;
    touched: boolean;
  };
};

// Key remapping — prefix all keys
type Prefixed<T, P extends string> = {
  [K in keyof T as `${P}${Capitalize<string & K>}`]: T[K];
};

type InvoiceForm = FormFields<Pick<Invoice, 'customer_id' | 'date' | 'due_date'>>;
// { customer_id: { value: number; error: string | null; touched: boolean }; ... }
```

### Conditional Mapped Types

```typescript
// Extract only string properties
type StringProps<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K];
};

// Make only certain keys optional
type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

type CreateInvoicePayload = PartialBy<Invoice, 'id' | 'branch_id' | 'notes'>;
```

## 7. Declaration Files

### Module Augmentation

```typescript
// types/vue-shims.d.ts — extend Vue component types
import 'vue-router';

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean;
    permission?: string;
    breadcrumb?: string;
  }
}

// types/axios.d.ts — extend Axios response
import 'axios';

declare module 'axios' {
  export interface AxiosRequestConfig {
    skipAuth?: boolean;
    retryCount?: number;
  }
}
```

### Global Type Declarations

```typescript
// types/global.d.ts
declare global {
  interface Window {
    __APP_CONFIG__: {
      apiUrl: string;
      appVersion: string;
      features: Record<string, boolean>;
    };
  }
}

// types/env.d.ts — Vite environment variables
interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_APP_TITLE: string;
  readonly VITE_SENTRY_DSN: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

## 8. Strict Mode Patterns

### strictNullChecks

```typescript
// Always handle null/undefined explicitly
function getCustomerName(customer: Customer | null): string {
  // BAD: customer.name — possible null reference
  // GOOD:
  return customer?.name ?? 'Unknown Customer';
}

// Nullish coalescing for defaults
const perPage = config.perPage ?? 25;
const sortBy = params.sort ?? 'created_at';
```

### noImplicitAny

```typescript
// BAD: implicit any in callbacks
// items.map((item) => item.name);  // item is any if source is untyped

// GOOD: explicitly type parameters
items.map((item: Invoice) => item.date);

// GOOD: type the source so inference works
const items: Invoice[] = await fetchInvoices();
items.map((item) => item.date); // item is Invoice by inference
```

### exactOptionalPropertyTypes

```typescript
// With exactOptionalPropertyTypes enabled:
interface Filters {
  search?: string;    // string | undefined, but NOT assignable with undefined explicitly
  status?: Status;
}

// BAD: const filters: Filters = { search: undefined }; // error
// GOOD: const filters: Filters = {};                     // omit the key
// GOOD: const filters: Filters = { search: 'test' };     // provide a value
```

## 9. API Type Definitions

### Request/Response Types

```typescript
// types/api.ts
interface PaginationMeta {
  total: number;
  per_page: number;
  current_page: number;
  last_page: number;
}

interface PaginatedResponse<T> {
  data: T[];
  meta: PaginationMeta;
  links: { next: string | null; prev: string | null };
}

interface SingleResponse<T> {
  data: T;
}

interface ErrorResponse {
  message: string;
  errors?: Record<string, string[]>;
}

// Typed API function signatures
type FetchList<T, F = Record<string, unknown>> =
  (filters?: F) => Promise<PaginatedResponse<T>>;
type FetchOne<T> = (id: number) => Promise<SingleResponse<T>>;
type CreateOne<T, P = Omit<T, 'id'>> = (payload: P) => Promise<SingleResponse<T>>;
```

### Zod Validation with Type Inference

```typescript
import { z } from 'zod';

const InvoiceSchema = z.object({
  customer_id: z.number().int().positive(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  due_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  items: z.array(z.object({
    product_id: z.number().int().positive(),
    quantity: z.number().positive(),
    price: z.number().nonnegative(),
  })).min(1),
  notes: z.string().max(1000).optional(),
});

// Infer TypeScript type from Zod schema — single source of truth
type CreateInvoicePayload = z.infer<typeof InvoiceSchema>;

function validateInvoice(data: unknown): CreateInvoicePayload {
  return InvoiceSchema.parse(data); // throws ZodError on invalid input
}
```

## 10. Error Handling

### Result Type Pattern

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

function ok<T>(value: T): Result<T, never> {
  return { ok: true, value };
}

function err<E>(error: E): Result<never, E> {
  return { ok: false, error };
}

// Usage — no try/catch at call site
async function createInvoice(data: CreateInvoicePayload): Promise<Result<Invoice, AppError>> {
  const validation = InvoiceSchema.safeParse(data);
  if (!validation.success) {
    return err({ code: 'VALIDATION_ERROR', message: validation.error.message });
  }
  try {
    const invoice = await api.post<SingleResponse<Invoice>>('/invoices', data);
    return ok(invoice.data);
  } catch (e) {
    return err({ code: 'API_ERROR', message: (e as Error).message });
  }
}

// Caller
const result = await createInvoice(payload);
if (result.ok) {
  notify({ type: 'success', message: `Invoice ${result.value.id} created` });
} else {
  notify({ type: 'error', message: result.error.message });
}
```

### Exhaustive Checking

```typescript
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${JSON.stringify(value)}`);
}

function getStatusColor(status: Status): string {
  switch (status) {
    case 'draft': return 'gray';
    case 'pending': return 'yellow';
    case 'approved': return 'green';
    case 'rejected': return 'red';
    default: return assertNever(status); // compile error if a case is missing
  }
}
```

## 11. Module Patterns

### Barrel Exports

```typescript
// types/index.ts — re-export all domain types
export type { Invoice, InvoiceItem, InvoiceFilters } from './invoice';
export type { Customer, CustomerFilters } from './customer';
export type { Product, StockLevel } from './product';
export type { PaginatedResponse, SingleResponse, ErrorResponse } from './api';

// composables/index.ts
export { useDataTable } from './useDataTable';
export { useFormValidation } from './useFormValidation';
export { useAuth } from './useAuth';
export { useNotification } from './useNotification';
```

### Path Aliases

```json
// tsconfig.json paths
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/types": ["src/types/index.ts"],
      "@/composables": ["src/composables/index.ts"],
      "@/api/*": ["src/api/*"]
    }
  }
}
```

## 12. tsconfig Best Practices

### Vue 3 / React Frontend

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "skipLibCheck": true,
    "types": ["vite/client"]
  },
  "include": ["src/**/*.ts", "src/**/*.tsx", "src/**/*.vue"]
}
```

### Node.js Backend

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "sourceMap": true,
    "noUncheckedIndexedAccess": true,
    "esModuleInterop": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

## 13. Common Anti-patterns

### Avoid `any` Abuse

```typescript
// BAD
function processData(data: any): any { return data.items.map((i: any) => i.name); }

// GOOD
function processData<T extends { items: { name: string }[] }>(data: T): string[] {
  return data.items.map((i) => i.name);
}

// When truly unknown, use unknown and narrow
function handleEvent(payload: unknown): void {
  if (typeof payload === 'object' && payload !== null && 'type' in payload) {
    // narrowed safely
  }
}
```

### Avoid Unnecessary Type Assertions

```typescript
// BAD — hiding a potential bug
const invoice = response.data as Invoice;

// GOOD — validate at runtime boundaries
const parsed = InvoiceSchema.parse(response.data);

// ACCEPTABLE — when you genuinely know more than the compiler
const canvas = document.getElementById('chart') as HTMLCanvasElement;
```

### Prefer Union Types Over Enums

```typescript
// AVOID — enums generate runtime code and have quirks
enum StatusEnum { Draft = 'draft', Pending = 'pending' }

// PREFER — union types are zero-cost and more flexible
type Status = 'draft' | 'pending' | 'approved' | 'rejected';

// If you need a runtime list, use const arrays
const STATUSES = ['draft', 'pending', 'approved', 'rejected'] as const;
type Status = (typeof STATUSES)[number];
```

### Avoid Overusing Non-null Assertion

```typescript
// BAD — suppresses null checks, crashes at runtime
const name = user!.name;

// GOOD — handle the null case
const name = user?.name ?? 'Anonymous';

// GOOD — assert with a meaningful error
assertDefined(user, 'authenticated user');
const name = user.name;
```
