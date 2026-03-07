---
name: laravel-patterns
description: Use when building Laravel applications. Covers application architecture, Eloquent ORM, service layer patterns, form requests, API resources, events/listeners, jobs/queues, middleware, and testing in Laravel 11+.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Laravel Patterns — Laravel 11+ Best Practices

## 1. Application Architecture

Laravel 11 uses a streamlined directory structure. Organize by module for larger applications.

```
app/
├── Models/              # Eloquent models
├── Services/            # Business logic (one service per domain concept)
├── Http/
│   ├── Controllers/     # Thin controllers — delegate to services
│   ├── Requests/        # Form request validation
│   ├── Resources/       # API response transformers
│   └── Middleware/       # Custom middleware
├── Policies/            # Authorization rules
├── Events/              # Domain events
├── Listeners/           # Event handlers
├── Jobs/                # Background processing
├── Exceptions/          # Custom exception classes
├── Providers/           # Service providers (AppServiceProvider is primary in L11)
└── Console/
    └── Commands/        # Artisan commands
```

### Service Provider Registration (Laravel 11)

```php
// app/Providers/AppServiceProvider.php
class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(InvoiceService::class);
        $this->app->singleton(InventoryService::class);
    }

    public function boot(): void
    {
        Model::shouldBeStrict(! app()->isProduction());
        Model::unguard(); // Or use $fillable per model
    }
}
```

## 2. Service Layer Pattern

All business logic belongs in service classes, never in controllers or models.

```php
// app/Services/InvoiceService.php
class InvoiceService
{
    public function __construct(
        private readonly InventoryService $inventory,
        private readonly TaxCalculator $tax,
    ) {}

    public function create(array $data): Invoice
    {
        return DB::transaction(function () use ($data) {
            $invoice = Invoice::create([
                'branch_id'   => auth()->user()->branch_id,
                'customer_id' => $data['customer_id'],
                'date'        => $data['date'],
                'due_date'    => $data['due_date'],
                'status'      => InvoiceStatus::Draft,
            ]);

            foreach ($data['items'] as $item) {
                $lineItem = $invoice->items()->create([
                    'product_id' => $item['product_id'],
                    'quantity'   => $item['quantity'],
                    'unit_price' => $item['unit_price'],
                    'tax_rate'   => $this->tax->rateFor($item['product_id']),
                ]);

                $this->inventory->reserve(
                    productId: $item['product_id'],
                    quantity: $item['quantity'],
                    referenceType: Invoice::class,
                    referenceId: $invoice->id,
                );
            }

            $invoice->recalculateTotal();
            event(new InvoiceCreated($invoice));

            return $invoice->load('items.product', 'customer');
        });
    }

    public function markAsPaid(Invoice $invoice, array $paymentData): Invoice
    {
        throw_unless(
            $invoice->status === InvoiceStatus::Sent,
            new InvalidInvoiceStateException($invoice, 'paid')
        );

        return DB::transaction(function () use ($invoice, $paymentData) {
            $invoice->update(['status' => InvoiceStatus::Paid, 'paid_at' => now()]);

            $invoice->payments()->create([
                'branch_id' => $invoice->branch_id,
                'amount'    => $paymentData['amount'],
                'method'    => $paymentData['method'],
                'reference' => $paymentData['reference'],
            ]);

            event(new InvoicePaid($invoice));

            return $invoice->fresh();
        });
    }
}
```

## 3. Eloquent ORM

### Model with Multi-Tenant Scoping

```php
// app/Models/Invoice.php
class Invoice extends Model
{
    use SoftDeletes, HasBranch, Auditable;

    protected $fillable = [
        'branch_id', 'customer_id', 'invoice_number',
        'date', 'due_date', 'status', 'subtotal',
        'tax_total', 'total', 'notes', 'paid_at',
    ];

    protected function casts(): array
    {
        return [
            'date'      => 'date',
            'due_date'  => 'date',
            'paid_at'   => 'datetime',
            'subtotal'  => 'decimal:2',
            'tax_total' => 'decimal:2',
            'total'     => 'decimal:2',
            'status'    => InvoiceStatus::class,
        ];
    }

    // --- Global scope for multi-tenant isolation ---
    protected static function booted(): void
    {
        static::addGlobalScope('branch', function (Builder $query) {
            if (auth()->check()) {
                $query->where('invoices.branch_id', auth()->user()->branch_id);
            }
        });

        static::creating(function (Invoice $invoice) {
            $invoice->branch_id ??= auth()->user()?->branch_id;
            $invoice->invoice_number ??= static::generateNumber($invoice->branch_id);
        });
    }

    // --- Relationships ---
    public function items(): HasMany
    {
        return $this->hasMany(InvoiceItem::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    // --- Scopes ---
    public function scopeUnpaid(Builder $query): Builder
    {
        return $query->whereIn('status', [InvoiceStatus::Draft, InvoiceStatus::Sent]);
    }

    public function scopeOverdue(Builder $query): Builder
    {
        return $query->where('status', InvoiceStatus::Sent)
                     ->where('due_date', '<', now());
    }

    public function scopeDateRange(Builder $query, Carbon $from, Carbon $to): Builder
    {
        return $query->whereBetween('date', [$from, $to]);
    }

    // --- Accessors ---
    protected function amountDue(): Attribute
    {
        return Attribute::get(fn () => $this->total - $this->payments->sum('amount'));
    }

    // --- Business methods ---
    public function recalculateTotal(): void
    {
        $this->subtotal  = $this->items->sum(fn ($i) => $i->quantity * $i->unit_price);
        $this->tax_total = $this->items->sum(fn ($i) => $i->quantity * $i->unit_price * $i->tax_rate);
        $this->total     = $this->subtotal + $this->tax_total;
        $this->save();
    }

    private static function generateNumber(int $branchId): string
    {
        $branch = Branch::find($branchId);
        $sequence = static::where('branch_id', $branchId)->withoutGlobalScopes()->count() + 1;

        return sprintf('INV-%s-%s-%05d', $branch->code, now()->format('Y'), $sequence);
    }
}
```

### HasBranch Trait (Reusable Multi-Tenant Concern)

```php
// app/Models/Concerns/HasBranch.php
trait HasBranch
{
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    public function scopeForBranch(Builder $query, int $branchId): Builder
    {
        return $query->where($this->getTable() . '.branch_id', $branchId);
    }
}
```

## 4. Form Request Validation

```php
// app/Http/Requests/CreateInvoiceRequest.php
class CreateInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Invoice::class);
    }

    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'integer', Rule::exists('customers', 'id')
                ->where('branch_id', $this->user()->branch_id)],
            'date'        => ['required', 'date', 'before_or_equal:today'],
            'due_date'    => ['required', 'date', 'after:date'],
            'notes'       => ['nullable', 'string', 'max:1000'],
            'items'                => ['required', 'array', 'min:1', 'max:100'],
            'items.*.product_id'   => ['required', 'integer', Rule::exists('products', 'id')
                ->where('branch_id', $this->user()->branch_id)],
            'items.*.quantity'     => ['required', 'numeric', 'min:0.01', 'max:999999'],
            'items.*.unit_price'   => ['required', 'numeric', 'min:0', 'max:9999999.99'],
        ];
    }

    public function messages(): array
    {
        return [
            'items.min'               => 'At least one line item is required.',
            'items.*.product_id.exists' => 'Product #:position not found in your branch.',
            'due_date.after'           => 'Due date must be after the invoice date.',
        ];
    }
}
```

## 5. API Resources

```php
// app/Http/Resources/InvoiceResource.php
class InvoiceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'invoice_number' => $this->invoice_number,
            'date'           => $this->date->toDateString(),
            'due_date'       => $this->due_date->toDateString(),
            'status'         => $this->status->value,
            'subtotal'       => (float) $this->subtotal,
            'tax_total'      => (float) $this->tax_total,
            'total'          => (float) $this->total,
            'amount_due'     => $this->when($this->relationLoaded('payments'), fn () => (float) $this->amount_due),
            'customer'       => new CustomerResource($this->whenLoaded('customer')),
            'items'          => InvoiceItemResource::collection($this->whenLoaded('items')),
            'created_at'     => $this->created_at->toIso8601String(),
            'updated_at'     => $this->updated_at->toIso8601String(),
        ];
    }
}

// Controller usage — thin controller delegates to service
class InvoiceController extends Controller
{
    public function __construct(private readonly InvoiceService $service) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $invoices = Invoice::with('customer')
            ->when($request->status, fn ($q, $s) => $q->where('status', $s))
            ->when($request->from, fn ($q, $d) => $q->where('date', '>=', $d))
            ->latest('date')
            ->cursorPaginate($request->integer('per_page', 25));

        return InvoiceResource::collection($invoices);
    }

    public function store(CreateInvoiceRequest $request): InvoiceResource
    {
        $invoice = $this->service->create($request->validated());

        return new InvoiceResource($invoice);
    }
}
```

## 6. Events and Listeners

```php
// app/Events/InvoiceCreated.php
class InvoiceCreated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public readonly Invoice $invoice) {}

    public function broadcastOn(): Channel
    {
        return new PrivateChannel("branch.{$this->invoice->branch_id}");
    }
}

// app/Listeners/GenerateInvoicePdf.php
class GenerateInvoicePdf implements ShouldQueue
{
    public function handle(InvoiceCreated $event): void
    {
        $pdf = Pdf::loadView('invoices.pdf', ['invoice' => $event->invoice->load('items.product', 'customer')]);
        $path = "invoices/{$event->invoice->branch_id}/{$event->invoice->invoice_number}.pdf";
        Storage::disk('s3')->put($path, $pdf->output());

        $event->invoice->update(['pdf_path' => $path]);
    }
}

// Register in AppServiceProvider or EventServiceProvider
Event::listen(InvoiceCreated::class, GenerateInvoicePdf::class);
Event::listen(InvoiceCreated::class, SendInvoiceNotification::class);
Event::listen(InvoiceCreated::class, CreateAccountingEntry::class);
```

## 7. Jobs and Queues

```php
// app/Jobs/ProcessBulkInvoices.php
class ProcessBulkInvoices implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;
    public int $backoff = 60;
    public int $timeout = 300;

    public function __construct(
        private readonly int $branchId,
        private readonly array $invoiceIds,
    ) {}

    public function handle(InvoiceService $service): void
    {
        Invoice::withoutGlobalScopes()
            ->where('branch_id', $this->branchId)
            ->whereIn('id', $this->invoiceIds)
            ->chunk(50, function ($invoices) use ($service) {
                foreach ($invoices as $invoice) {
                    $service->finalize($invoice);
                }
            });
    }

    public function failed(Throwable $exception): void
    {
        Log::error('Bulk invoice processing failed', [
            'branch_id'   => $this->branchId,
            'invoice_ids' => $this->invoiceIds,
            'error'       => $exception->getMessage(),
        ]);
    }
}

// Job batching
Bus::batch([
    new ProcessBulkInvoices($branchId, $batch1),
    new ProcessBulkInvoices($branchId, $batch2),
])->name("bulk-invoices-branch-{$branchId}")
  ->allowFailures()
  ->onQueue('invoices')
  ->dispatch();
```

## 8. Middleware

### Tenant Scoping Middleware

```php
// app/Http/Middleware/EnsureBranchScope.php
class EnsureBranchScope
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! $request->user()?->branch_id) {
            abort(403, 'No branch assigned to this user.');
        }

        // Bind branch for dependency injection
        app()->instance('current_branch_id', $request->user()->branch_id);

        return $next($request);
    }
}

// bootstrap/app.php (Laravel 11)
return Application::configure(basePath: dirname(__DIR__))
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->api(append: [
            EnsureBranchScope::class,
        ]);
    })
    ->create();
```

## 9. Exception Handling

```php
// app/Exceptions/InvoiceNotFoundException.php
class InvoiceNotFoundException extends RuntimeException
{
    public function __construct(public readonly int $invoiceId)
    {
        parent::__construct("Invoice #{$invoiceId} not found.");
    }

    public function render(Request $request): JsonResponse
    {
        return response()->json(['message' => $this->getMessage()], 404);
    }
}

// app/Exceptions/InsufficientStockException.php
class InsufficientStockException extends DomainException
{
    public function __construct(
        public readonly Product $product,
        public readonly float $requested,
        public readonly float $available,
    ) {
        parent::__construct("Insufficient stock for {$product->name}: requested {$requested}, available {$available}.");
    }

    public function render(): JsonResponse
    {
        return response()->json([
            'message' => $this->getMessage(),
            'errors'  => ['quantity' => [$this->getMessage()]],
        ], 422);
    }

    public function report(): void
    {
        Log::warning('Insufficient stock', [
            'product_id' => $this->product->id,
            'branch_id'  => $this->product->branch_id,
            'requested'  => $this->requested,
            'available'  => $this->available,
        ]);
    }
}
```

## 10. Artisan Commands

```php
// app/Console/Commands/RecalculateInvoiceTotals.php
class RecalculateInvoiceTotals extends Command
{
    protected $signature = 'invoices:recalculate
                            {--branch= : Specific branch ID}
                            {--dry-run : Show changes without saving}';

    protected $description = 'Recalculate all invoice totals from line items';

    public function handle(): int
    {
        $query = Invoice::withoutGlobalScopes()->with('items');

        if ($branchId = $this->option('branch')) {
            $query->where('branch_id', $branchId);
        }

        $updated = 0;
        $query->chunk(100, function ($invoices) use (&$updated) {
            foreach ($invoices as $invoice) {
                $newTotal = $invoice->items->sum(fn ($i) => $i->quantity * $i->unit_price);

                if ((float) $invoice->total !== $newTotal) {
                    $this->line("Invoice {$invoice->invoice_number}: {$invoice->total} -> {$newTotal}");
                    if (! $this->option('dry-run')) {
                        $invoice->recalculateTotal();
                    }
                    $updated++;
                }
            }
        });

        $this->info("{$updated} invoices " . ($this->option('dry-run') ? 'would be' : '') . " updated.");

        return Command::SUCCESS;
    }
}
```

## 11. Database Transactions

```php
// Nested transaction with savepoints
DB::transaction(function () use ($order) {
    $invoice = Invoice::create([...]);

    try {
        DB::transaction(function () use ($order) {
            $this->inventory->deductStock($order);
        });
    } catch (InsufficientStockException $e) {
        // Inner transaction rolls back, outer continues
        $invoice->update(['status' => InvoiceStatus::PendingStock]);
        Log::warning('Order created but stock unavailable', ['order_id' => $order->id]);
    }
}, attempts: 3); // Retry up to 3 times on deadlock
```

## 12. Caching Patterns

```php
// Cache with tags for easy invalidation
$products = Cache::tags(["branch:{$branchId}", 'products'])
    ->remember("products:branch:{$branchId}:page:{$page}", now()->addMinutes(15), function () use ($branchId, $page) {
        return Product::where('branch_id', $branchId)
            ->select('id', 'name', 'sku', 'price', 'stock_quantity')
            ->paginate(25, ['*'], 'page', $page);
    });

// Invalidate on product update
Cache::tags(["branch:{$product->branch_id}", 'products'])->flush();

// Model observer for automatic cache invalidation
class ProductObserver
{
    public function saved(Product $product): void
    {
        Cache::tags(["branch:{$product->branch_id}", 'products'])->flush();
    }

    public function deleted(Product $product): void
    {
        Cache::tags(["branch:{$product->branch_id}", 'products'])->flush();
    }
}
```

## 13. Testing

### Feature Test (API Endpoint)

```php
class InvoiceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_invoice_with_items(): void
    {
        $branch = Branch::factory()->create();
        $user = User::factory()->for($branch)->create();
        $customer = Customer::factory()->for($branch)->create();
        $product = Product::factory()->for($branch)->create(['price' => 100.00]);

        $response = $this->actingAs($user)->postJson('/api/v1/invoices', [
            'customer_id' => $customer->id,
            'date'        => '2026-03-01',
            'due_date'    => '2026-03-31',
            'items'       => [
                ['product_id' => $product->id, 'quantity' => 2, 'unit_price' => 100.00],
            ],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.total', 200.00)
            ->assertJsonPath('data.status', 'draft')
            ->assertJsonCount(1, 'data.items');

        $this->assertDatabaseHas('invoices', [
            'branch_id'   => $branch->id,
            'customer_id' => $customer->id,
        ]);
    }

    public function test_tenant_isolation_prevents_cross_branch_access(): void
    {
        $branchA = Branch::factory()->create();
        $branchB = Branch::factory()->create();
        $userA = User::factory()->for($branchA)->create();
        $invoiceB = Invoice::factory()->for($branchB)->create();

        $response = $this->actingAs($userA)->getJson("/api/v1/invoices/{$invoiceB->id}");

        $response->assertNotFound();
    }

    public function test_validation_rejects_invalid_data(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/v1/invoices', [
            'customer_id' => null,
            'date'        => 'not-a-date',
            'items'       => [],
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['customer_id', 'date', 'due_date', 'items']);
    }
}
```

### Unit Test (Service Layer)

```php
class InvoiceServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_mark_as_paid_updates_status_and_creates_payment(): void
    {
        $invoice = Invoice::factory()->sent()->create(['total' => 500.00]);
        $service = app(InvoiceService::class);

        $result = $service->markAsPaid($invoice, [
            'amount'    => 500.00,
            'method'    => 'bank_transfer',
            'reference' => 'TXN-12345',
        ]);

        $this->assertEquals(InvoiceStatus::Paid, $result->status);
        $this->assertNotNull($result->paid_at);
        $this->assertDatabaseHas('payments', [
            'invoice_id' => $invoice->id,
            'amount'     => 500.00,
        ]);

        Event::assertDispatched(InvoicePaid::class);
    }

    public function test_mark_as_paid_rejects_draft_invoice(): void
    {
        $invoice = Invoice::factory()->draft()->create();
        $service = app(InvoiceService::class);

        $this->expectException(InvalidInvoiceStateException::class);
        $service->markAsPaid($invoice, ['amount' => 100, 'method' => 'cash', 'reference' => '']);
    }
}
```

### Database Testing with Factories

```php
// database/factories/InvoiceFactory.php
class InvoiceFactory extends Factory
{
    protected $model = Invoice::class;

    public function definition(): array
    {
        return [
            'branch_id'      => Branch::factory(),
            'customer_id'    => Customer::factory(),
            'invoice_number' => fn () => 'INV-TEST-' . $this->faker->unique()->numerify('#####'),
            'date'           => now(),
            'due_date'       => now()->addDays(30),
            'status'         => InvoiceStatus::Draft,
            'subtotal'       => 0,
            'tax_total'      => 0,
            'total'          => 0,
        ];
    }

    public function sent(): static
    {
        return $this->state(['status' => InvoiceStatus::Sent]);
    }

    public function draft(): static
    {
        return $this->state(['status' => InvoiceStatus::Draft]);
    }

    public function overdue(): static
    {
        return $this->state([
            'status'   => InvoiceStatus::Sent,
            'due_date' => now()->subDays(15),
        ]);
    }
}
```
