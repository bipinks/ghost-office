---
name: typescript-patterns
description: Use when writing TypeScript code for frontend or backend. Covers type system fundamentals, generics, utility types, discriminated unions, type guards, declaration files, strict mode patterns, and enterprise TypeScript architecture.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# TypeScript Patterns -- Enterprise Development

## Interfaces vs Types

**Interfaces** for extendable object shapes. **Types** for unions, intersections, mapped/computed types.

```typescript
interface Customer { id: number; name: string; email: string; }
interface PremiumCustomer extends Customer { discountRate: number; }

type Status = 'draft' | 'pending' | 'approved' | 'rejected';
type Nullable<T> = T | null;
type ApiEndpoint = `/api/v1/${string}`;
type StatusLabel = `${Status}Label`; // 'draftLabel' | 'pendingLabel' | ...
```

## Generics

```typescript
function findById<T extends { id: number }>(items: T[], id: number): T | undefined {
  return items.find((item) => item.id === id);
}

// Conditional types with infer
type Unwrap<T> = T extends Promise<infer U> ? U : T;
type ApiReturn<T extends (...args: any) => Promise<any>> =
  T extends (...args: any) => Promise<{ data: infer D }> ? D : never;

// Generic class with multi-tenant constraint
class Repository<T extends { id: number; branch_id: number }> {
  private items: T[] = [];
  findById(id: number): T | undefined { return this.items.find(i => i.id === id); }
  filterByBranch(branchId: number): T[] { return this.items.filter(i => i.branch_id === branchId); }
  create(item: Omit<T, 'id'>): T { return { ...item, id: Date.now() } as T; }
}
```

## Utility Types

```typescript
interface Invoice {
  id: number; customer_id: number; date: string;
  due_date: string; status: Status; total: number;
  notes?: string; branch_id: number;
}

type InvoiceUpdate = Partial<Invoice>;                          // all optional
type InvoiceSummary = Pick<Invoice, 'id' | 'date' | 'total'>; // subset
type CreateInvoice = Omit<Invoice, 'id' | 'branch_id'>;       // exclude system fields
type StatusCounts = Record<Status, number>;                     // typed map
type ActiveStatus = Extract<Status, 'pending' | 'approved'>;  // filter union
type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>; // selective optional
```

## Discriminated Unions

```typescript
type ApiResponse<T> =
  | { status: 'success'; data: T; meta?: PaginationMeta }
  | { status: 'error'; message: string; errors?: Record<string, string[]> }
  | { status: 'loading' };

// State machine -- each status carries its own context
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

## Type Guards and Assertions

```typescript
function isCustomer(contact: Customer | Vendor): contact is Customer {
  return contact.type === 'customer';
}

function assertDefined<T>(value: T | null | undefined, name: string): asserts value is T {
  if (value == null) throw new Error(`Expected ${name} to be defined`);
}
```

## Mapped Types

```typescript
type FormFields<T> = { [K in keyof T]: { value: T[K]; error: string | null; touched: boolean } };
type StringProps<T> = { [K in keyof T as T[K] extends string ? K : never]: T[K] };
type NullableProps<T> = { [K in keyof T]: T[K] | null };
```

## Declaration Files

```typescript
// types/vue-shims.d.ts -- module augmentation
declare module 'vue-router' {
  interface RouteMeta { requiresAuth?: boolean; permission?: string; breadcrumb?: string; }
}

// types/env.d.ts -- Vite environment variables
interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_APP_TITLE: string;
}
```

## Zod Validation (Single Source of Truth)

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

type CreateInvoicePayload = z.infer<typeof InvoiceSchema>; // inferred from schema
```

## Result Type Pattern

```typescript
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };
function ok<T>(value: T): Result<T, never> { return { ok: true, value }; }
function err<E>(error: E): Result<never, E> { return { ok: false, error }; }

// Exhaustive switch guard
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${JSON.stringify(value)}`);
}
```

## API Type Definitions

```typescript
interface PaginatedResponse<T> {
  data: T[];
  meta: { total: number; per_page: number; current_page: number; last_page: number };
  links: { next: string | null; prev: string | null };
}
interface SingleResponse<T> { data: T; }
interface ErrorResponse { message: string; errors?: Record<string, string[]>; }
```

## tsconfig -- Recommended Strict Options

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
    "paths": { "@/*": ["src/*"] }
  }
}
```

## Anti-Patterns

- **Avoid `any`** -- use `unknown` and narrow; use generics for flexible functions
- **Avoid type assertions** (`as`) -- validate at runtime boundaries with Zod/schemas
- **Prefer union types over enums** -- enums generate runtime code; use `as const` arrays for runtime lists
- **Avoid non-null assertions** (`!`) -- use optional chaining (`?.`) and nullish coalescing (`??`)
- **Avoid implicit `any` in callbacks** -- type the source array or annotate parameters
