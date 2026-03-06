# Coding Standards — ERP Platform

## General Principles

1. **Readability over cleverness** — Code is read 10x more than written
2. **Consistency** — Follow existing patterns in the codebase
3. **Single responsibility** — Each class/function does one thing well
4. **DRY but not premature** — Extract after 3+ duplications, not before
5. **Fail fast** — Validate early, throw meaningful exceptions

## PHP / Laravel Standards

### Naming Conventions
```php
// Classes: PascalCase
class InvoiceService {}
class CreateInvoiceRequest {}

// Methods: camelCase
public function calculateTotal(): float {}
public function getUnpaidInvoices(): Collection {}

// Variables: camelCase
$invoiceTotal = 0;
$branchId = auth()->user()->branch_id;

// Constants: UPPER_SNAKE_CASE
const MAX_LINE_ITEMS = 100;
const TAX_RATE_DEFAULT = 0.05;

// Database columns: snake_case
// invoice_number, branch_id, created_at, total_amount

// Routes: kebab-case
// /api/v1/sales-orders, /api/v1/purchase-requests
```

### Controller Pattern (Thin)
```php
class InvoiceController extends Controller
{
    public function store(CreateInvoiceRequest $request, InvoiceService $service)
    {
        $invoice = $service->create($request->validated());
        return new InvoiceResource($invoice);
    }
}
```

### Service Pattern (Business Logic)
```php
class InvoiceService
{
    public function create(array $data): Invoice
    {
        return DB::transaction(function () use ($data) {
            $invoice = Invoice::create([
                'branch_id' => auth()->user()->branch_id,
                ...$data,
            ]);

            foreach ($data['items'] as $item) {
                $invoice->items()->create($item);
            }

            $invoice->calculateTotal();
            event(new InvoiceCreated($invoice));

            return $invoice;
        });
    }
}
```

### Model Pattern
```php
class Invoice extends Model
{
    use SoftDeletes, HasBranch, Auditable;

    protected $fillable = ['customer_id', 'date', 'due_date', 'notes'];

    // Always scope to branch
    protected static function booted()
    {
        static::addGlobalScope('branch', function ($query) {
            if (auth()->check()) {
                $query->where('branch_id', auth()->user()->branch_id);
            }
        });
    }

    // Relationships
    public function items(): HasMany { return $this->hasMany(InvoiceItem::class); }
    public function customer(): BelongsTo { return $this->belongsTo(Customer::class); }

    // Scopes
    public function scopeUnpaid($query) { return $query->where('status', 'unpaid'); }
    public function scopeOverdue($query) { return $query->where('due_date', '<', now()); }
}
```

### Validation (Form Requests)
```php
class CreateInvoiceRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'exists:customers,id'],
            'date' => ['required', 'date'],
            'due_date' => ['required', 'date', 'after:date'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'exists:products,id'],
            'items.*.quantity' => ['required', 'numeric', 'min:0.01'],
            'items.*.price' => ['required', 'numeric', 'min:0'],
        ];
    }
}
```

## JavaScript / TypeScript Standards

### Naming
```typescript
// Components: PascalCase
InvoiceForm.vue, DataTable.tsx

// Functions: camelCase
function calculateSubtotal(items: LineItem[]): number {}

// Constants: UPPER_SNAKE_CASE
const API_BASE_URL = '/api/v1';

// Types/Interfaces: PascalCase
interface Invoice { id: number; total: number; }
```

### Component Pattern (Vue 3)
```vue
<script setup lang="ts">
import { ref, computed } from 'vue';
import type { Invoice } from '@/types';

const props = defineProps<{ invoice: Invoice }>();
const emit = defineEmits<{ (e: 'save', invoice: Invoice): void }>();

const isEditing = ref(false);
const total = computed(() => props.invoice.items.reduce((sum, i) => sum + i.amount, 0));
</script>
```

## API Response Format

```json
// Success (single)
{ "data": { "id": 1, "invoice_number": "INV-001" } }

// Success (list)
{ "data": [...], "meta": { "total": 100, "per_page": 25, "current_page": 1 } }

// Error (validation)
{ "message": "Validation failed", "errors": { "date": ["Required"] } }

// Error (not found)
{ "message": "Invoice not found" }
```

## Git Conventions

### Commit Format
```
feat: add invoice PDF generation
fix: correct tax calculation for exempt items
refactor: extract payment processing to service
test: add multi-tenant isolation tests for invoices
docs: update API documentation for sales module
chore: update Laravel to 11.x
```

### Branch Naming
```
feat/invoice-pdf-generation
fix/tax-calculation-exempt
hotfix/payment-gateway-timeout
```

## File Organization
- Maximum 300 lines per file
- One class per file
- Group by feature/module, not by type
- Tests mirror the source directory structure
