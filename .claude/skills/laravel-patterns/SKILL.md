---
name: laravel-patterns
description: Use when building Laravel applications. Covers application architecture, Eloquent ORM, service layer patterns, form requests, API resources, events/listeners, jobs/queues, middleware, and testing in Laravel 11+.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Laravel Patterns -- Laravel 11+ Best Practices

## 1. Application Architecture

```
app/
├── Models/           # Eloquent models with scopes, casts, relationships
├── Services/         # Business logic (one per domain concept)
├── Http/
│   ├── Controllers/  # Thin -- delegate to services
│   ├── Requests/     # Form request validation
│   ├── Resources/    # API response transformers
│   └── Middleware/
├── Policies/         # Authorization rules
├── Events/           # Domain events
├── Listeners/        # Event handlers (often queued)
├── Jobs/             # Background processing
└── Providers/        # AppServiceProvider is primary in L11
```

```php
// AppServiceProvider -- Laravel 11 setup
public function boot(): void {
    Model::shouldBeStrict(! app()->isProduction());
}
```

## 2. Service Layer

All business logic in services, never in controllers or models.

```php
class InvoiceService
{
    public function __construct(private readonly InventoryService $inventory, private readonly TaxCalculator $tax) {}

    public function create(array $data): Invoice
    {
        return DB::transaction(function () use ($data) {
            $invoice = Invoice::create([
                'branch_id' => auth()->user()->branch_id,
                'customer_id' => $data['customer_id'],
                'date' => $data['date'], 'due_date' => $data['due_date'],
                'status' => InvoiceStatus::Draft,
            ]);
            foreach ($data['items'] as $item) {
                $invoice->items()->create([
                    'product_id' => $item['product_id'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $item['unit_price'],
                    'tax_rate' => $this->tax->rateFor($item['product_id']),
                ]);
                $this->inventory->reserve($item['product_id'], $item['quantity'], Invoice::class, $invoice->id);
            }
            $invoice->recalculateTotal();
            event(new InvoiceCreated($invoice));
            return $invoice->load('items.product', 'customer');
        });
    }
}
```

## 3. Eloquent Model (Multi-Tenant)

```php
class Invoice extends Model
{
    use SoftDeletes, HasBranch, Auditable;

    protected $fillable = ['branch_id', 'customer_id', 'invoice_number', 'date', 'due_date',
        'status', 'subtotal', 'tax_total', 'total', 'notes', 'paid_at'];

    protected function casts(): array {
        return ['date' => 'date', 'due_date' => 'date', 'paid_at' => 'datetime',
            'subtotal' => 'decimal:2', 'total' => 'decimal:2', 'status' => InvoiceStatus::class];
    }

    protected static function booted(): void {
        static::addGlobalScope('branch', fn (Builder $q) =>
            auth()->check() ? $q->where('invoices.branch_id', auth()->user()->branch_id) : null);
        static::creating(fn (Invoice $inv) =>
            $inv->invoice_number ??= static::generateNumber($inv->branch_id ??= auth()->user()?->branch_id));
    }

    public function items(): HasMany { return $this->hasMany(InvoiceItem::class); }
    public function customer(): BelongsTo { return $this->belongsTo(Customer::class); }
    public function payments(): HasMany { return $this->hasMany(Payment::class); }

    public function scopeUnpaid(Builder $q): Builder { return $q->whereIn('status', [InvoiceStatus::Draft, InvoiceStatus::Sent]); }
    public function scopeOverdue(Builder $q): Builder { return $q->where('status', InvoiceStatus::Sent)->where('due_date', '<', now()); }

    public function recalculateTotal(): void {
        $this->subtotal = $this->items->sum(fn ($i) => $i->quantity * $i->unit_price);
        $this->tax_total = $this->items->sum(fn ($i) => $i->quantity * $i->unit_price * $i->tax_rate);
        $this->total = $this->subtotal + $this->tax_total;
        $this->save();
    }
}
```

### HasBranch Trait
```php
trait HasBranch {
    public function branch(): BelongsTo { return $this->belongsTo(Branch::class); }
    public function scopeForBranch(Builder $q, int $branchId): Builder {
        return $q->where($this->getTable() . '.branch_id', $branchId);
    }
}
```

## 4. Form Request Validation

```php
class CreateInvoiceRequest extends FormRequest
{
    public function authorize(): bool { return $this->user()->can('create', Invoice::class); }

    public function rules(): array {
        $branchId = $this->user()->branch_id;
        return [
            'customer_id' => ['required', 'integer', Rule::exists('customers', 'id')->where('branch_id', $branchId)],
            'date' => ['required', 'date', 'before_or_equal:today'],
            'due_date' => ['required', 'date', 'after:date'],
            'items' => ['required', 'array', 'min:1', 'max:100'],
            'items.*.product_id' => ['required', 'integer', Rule::exists('products', 'id')->where('branch_id', $branchId)],
            'items.*.quantity' => ['required', 'numeric', 'min:0.01'],
            'items.*.unit_price' => ['required', 'numeric', 'min:0'],
        ];
    }
}
```

Always scope `exists` rules with `branch_id` to prevent cross-tenant references.

## 5. API Resources & Controllers

```php
class InvoiceResource extends JsonResource {
    public function toArray(Request $request): array {
        return [
            'id' => $this->id, 'invoice_number' => $this->invoice_number,
            'date' => $this->date->toDateString(), 'status' => $this->status->value,
            'total' => (float) $this->total,
            'customer' => new CustomerResource($this->whenLoaded('customer')),
            'items' => InvoiceItemResource::collection($this->whenLoaded('items')),
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}

class InvoiceController extends Controller {
    public function __construct(private readonly InvoiceService $service) {}
    public function index(Request $request): AnonymousResourceCollection {
        return InvoiceResource::collection(
            Invoice::with('customer')
                ->when($request->status, fn ($q, $s) => $q->where('status', $s))
                ->latest('date')->cursorPaginate($request->integer('per_page', 25))
        );
    }
    public function store(CreateInvoiceRequest $request): InvoiceResource {
        return new InvoiceResource($this->service->create($request->validated()));
    }
}
```

## 6. Events, Listeners & Jobs

```php
// Event (broadcastable)
class InvoiceCreated implements ShouldBroadcast {
    use Dispatchable, SerializesModels;
    public function __construct(public readonly Invoice $invoice) {}
    public function broadcastOn(): Channel { return new PrivateChannel("branch.{$this->invoice->branch_id}"); }
}

// Queued listener
class GenerateInvoicePdf implements ShouldQueue {
    public function handle(InvoiceCreated $event): void {
        $pdf = Pdf::loadView('invoices.pdf', ['invoice' => $event->invoice->load('items.product', 'customer')]);
        Storage::disk('s3')->put("invoices/{$event->invoice->branch_id}/{$event->invoice->invoice_number}.pdf", $pdf->output());
    }
}

// Job with retries and batching
class ProcessBulkInvoices implements ShouldQueue {
    use Queueable;
    public int $tries = 3; public int $backoff = 60; public int $timeout = 300;
    public function __construct(private readonly int $branchId, private readonly array $invoiceIds) {}
    public function handle(InvoiceService $service): void {
        Invoice::withoutGlobalScopes()->where('branch_id', $this->branchId)
            ->whereIn('id', $this->invoiceIds)->chunk(50, fn ($inv) => $inv->each(fn ($i) => $service->finalize($i)));
    }
}
```

## 7. Middleware & Exception Handling

```php
// Tenant scoping middleware
class EnsureBranchScope {
    public function handle(Request $request, Closure $next): Response {
        abort_unless($request->user()?->branch_id, 403, 'No branch assigned.');
        app()->instance('current_branch_id', $request->user()->branch_id);
        return $next($request);
    }
}

// Domain exceptions with render()
class InsufficientStockException extends DomainException {
    public function __construct(public readonly Product $product, public readonly float $requested, public readonly float $available) {
        parent::__construct("Insufficient stock for {$product->name}: requested {$requested}, available {$available}.");
    }
    public function render(): JsonResponse { return response()->json(['message' => $this->getMessage()], 422); }
}
```

## 8. Caching

```php
// Cache with tags for group invalidation
$products = Cache::tags(["branch:{$branchId}", 'products'])
    ->remember("products:branch:{$branchId}:page:{$page}", now()->addMinutes(15), fn () =>
        Product::where('branch_id', $branchId)->paginate(25));

// Invalidate via model observer
class ProductObserver {
    public function saved(Product $p): void { Cache::tags(["branch:{$p->branch_id}", 'products'])->flush(); }
}
```

## 9. Testing

```php
// Feature test -- API endpoint
public function test_create_invoice_with_items(): void {
    $branch = Branch::factory()->create();
    $user = User::factory()->for($branch)->create();
    $customer = Customer::factory()->for($branch)->create();
    $product = Product::factory()->for($branch)->create(['price' => 100.00]);

    $this->actingAs($user)->postJson('/api/v1/invoices', [
        'customer_id' => $customer->id, 'date' => '2026-03-01', 'due_date' => '2026-03-31',
        'items' => [['product_id' => $product->id, 'quantity' => 2, 'unit_price' => 100.00]],
    ])->assertCreated()->assertJsonPath('data.total', 200.00);
}

// Tenant isolation test
public function test_tenant_isolation(): void {
    $branchA = Branch::factory()->create();
    $userA = User::factory()->for($branchA)->create();
    $invoiceB = Invoice::factory()->create(); // different branch
    $this->actingAs($userA)->getJson("/api/v1/invoices/{$invoiceB->id}")->assertNotFound();
}

// Factory with states
class InvoiceFactory extends Factory {
    public function definition(): array {
        return ['branch_id' => Branch::factory(), 'customer_id' => Customer::factory(),
            'invoice_number' => fn () => 'INV-TEST-' . $this->faker->unique()->numerify('#####'),
            'date' => now(), 'due_date' => now()->addDays(30), 'status' => InvoiceStatus::Draft,
            'subtotal' => 0, 'total' => 0];
    }
    public function sent(): static { return $this->state(['status' => InvoiceStatus::Sent]); }
    public function overdue(): static { return $this->state(['status' => InvoiceStatus::Sent, 'due_date' => now()->subDays(15)]); }
}
```
