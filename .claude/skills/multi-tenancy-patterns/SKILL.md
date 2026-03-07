---
name: multi-tenancy-patterns
description: Use when implementing or reviewing multi-tenant features. Covers shared database with branch_id isolation, tenant resolution, data scoping, cross-tenant prevention, tenant-aware caching, queues, file storage, and testing strategies.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Multi-Tenancy Patterns

Comprehensive guide for implementing multi-tenant data isolation in a shared-database Laravel application using the `branch_id` pattern.

---

## 1. Multi-Tenancy Models

Three primary approaches exist for multi-tenant architectures. This platform uses the **shared database, shared schema** model.

### Shared Database, Shared Schema (Our Approach)
Every table includes a `branch_id` column. All tenants share one database and one schema. Isolation is enforced at the query level through global scopes and middleware.

**Advantages:**
- Simple infrastructure (one database to manage, back up, migrate)
- Low per-tenant cost; scales to thousands of tenants without provisioning
- Straightforward cross-tenant reporting for company-level views
- Single migration path for all tenants

**Disadvantages:**
- Requires discipline: every query must be scoped (global scopes mitigate this)
- Noisy-neighbor risk if one tenant generates heavy load
- Data leak risk if scoping is bypassed incorrectly

### Separate Database per Tenant
Each tenant gets its own database. Connection is resolved at runtime.

**Advantages:** Strong isolation, easy per-tenant backup/restore, no noisy-neighbor.
**Disadvantages:** Migration complexity (run against every database), high operational cost, cross-tenant reporting requires federation.

### Separate Schema per Tenant
One database server, but each tenant has its own schema (PostgreSQL schemas).

**Advantages:** Better isolation than shared schema, single server to manage.
**Disadvantages:** Schema migration across hundreds of schemas, connection pooling complexity.

### Decision Summary

| Factor | Shared Schema | Separate DB | Separate Schema |
|--------|--------------|-------------|-----------------|
| Isolation strength | Query-level | Database-level | Schema-level |
| Operational cost | Low | High | Medium |
| Migration effort | Single run | Per-tenant run | Per-schema run |
| Cross-tenant reports | Easy | Hard | Medium |
| Tenant count scale | Thousands | Hundreds | Hundreds |
| Our choice | Yes | No | No |

---

## 2. The branch_id Pattern

Every data table includes a `branch_id` foreign key that references the `branches` table. This column is the foundation of all tenant isolation.

### Entity Relationship

```
companies (1) ---> branches (many) ---> users (many)
                                   ---> invoices (many)
                                   ---> products (many)
                                   ---> journal_entries (many)
                                   ---> ... (all domain tables)
```

### Migration Template

```php
// database/migrations/2026_03_07_create_invoices_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('branch_id')->constrained()->index();
            $table->foreignId('customer_id')->constrained();
            $table->string('invoice_number');
            $table->date('date');
            $table->date('due_date');
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->string('status')->default('draft');
            $table->timestamps();
            $table->softDeletes();

            // Composite index for common tenant-scoped queries
            $table->index(['branch_id', 'status', 'date']);
            // Unique constraint scoped to branch
            $table->unique(['branch_id', 'invoice_number']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoices');
    }
};
```

### Key Rules
- `branch_id` is **non-nullable** on every domain table
- Add a composite index on `(branch_id, ...)` for frequently filtered columns
- Unique constraints must be scoped to `branch_id` (e.g., invoice numbers are unique per branch, not globally)
- The `branches`, `companies`, and `migrations` tables do NOT have `branch_id`

---

## 3. Tenant Resolution

Tenant context must be established early in the request lifecycle. The authenticated user's `branch_id` is the primary resolution mechanism.

### Authentication-Based Resolution (Primary)

```php
// app/Http/Middleware/SetBranchContext.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Services\TenantContext;

class SetBranchContext
{
    public function __construct(private TenantContext $context) {}

    public function handle(Request $request, Closure $next)
    {
        if ($request->user()) {
            $this->context->set($request->user()->branch_id);
        }

        return $next($request);
    }
}
```

### Tenant Context Service

```php
// app/Services/TenantContext.php

namespace App\Services;

class TenantContext
{
    private ?int $branchId = null;

    public function set(int $branchId): void
    {
        $this->branchId = $branchId;
    }

    public function id(): ?int
    {
        return $this->branchId;
    }

    public function require(): int
    {
        if ($this->branchId === null) {
            throw new \RuntimeException('Branch context not set.');
        }
        return $this->branchId;
    }

    public function isSet(): bool
    {
        return $this->branchId !== null;
    }
}
```

### Subdomain-Based Resolution (Alternative)

```php
// For platforms where tenants access via subdomain: acme.app.example.com

public function handle(Request $request, Closure $next)
{
    $subdomain = explode('.', $request->getHost())[0];
    $branch = Branch::where('slug', $subdomain)->firstOrFail();
    $this->context->set($branch->id);

    return $next($request);
}
```

### Header-Based Resolution (API Clients)

```php
// For API clients that specify tenant via X-Branch-Id header

public function handle(Request $request, Closure $next)
{
    if ($branchId = $request->header('X-Branch-Id')) {
        // Verify the user has access to this branch
        $user = $request->user();
        if (!$user->canAccessBranch((int) $branchId)) {
            abort(403, 'Access denied to this branch.');
        }
        $this->context->set((int) $branchId);
    }

    return $next($request);
}
```

---

## 4. HasBranch Trait

A reusable trait applied to every tenant-scoped model. It handles automatic scoping on reads and automatic `branch_id` injection on creates.

```php
// app/Models/Concerns/HasBranch.php

namespace App\Models\Concerns;

use App\Models\Branch;
use App\Models\Scopes\BranchScope;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

trait HasBranch
{
    public static function bootHasBranch(): void
    {
        // Apply global scope for all queries
        static::addGlobalScope(new BranchScope());

        // Auto-set branch_id when creating a new record
        static::creating(function ($model) {
            if (empty($model->branch_id) && auth()->check()) {
                $model->branch_id = auth()->user()->branch_id;
            }
        });
    }

    /**
     * Relationship to the owning branch.
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * Scope to a specific branch (overrides global scope).
     */
    public function scopeForBranch($query, int $branchId)
    {
        return $query->withoutGlobalScope(BranchScope::class)
                     ->where('branch_id', $branchId);
    }
}
```

### Model Usage

```php
// app/Models/Invoice.php

namespace App\Models;

use App\Models\Concerns\HasBranch;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Invoice extends Model
{
    use SoftDeletes, HasBranch;

    protected $fillable = [
        'customer_id',
        'invoice_number',
        'date',
        'due_date',
        'total_amount',
        'status',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(InvoiceItem::class);
    }
}
```

With this trait, `Invoice::all()` automatically returns only records for the current user's branch. `Invoice::create([...])` automatically sets `branch_id`.

---

## 5. Global Scopes

### BranchScope Implementation

```php
// app/Models/Scopes/BranchScope.php

namespace App\Models\Scopes;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

class BranchScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        if (auth()->check() && auth()->user()->branch_id) {
            $builder->where(
                $model->getTable() . '.branch_id',
                auth()->user()->branch_id
            );
        }
    }
}
```

### Bypassing for Admin and Reports

```php
// Company-level report: aggregate across all branches of a company
$companyRevenue = Invoice::withoutGlobalScope(BranchScope::class)
    ->whereHas('branch', function ($q) use ($companyId) {
        $q->where('company_id', $companyId);
    })
    ->where('status', 'paid')
    ->sum('total_amount');

// Admin viewing a specific branch (not their own)
$branchInvoices = Invoice::forBranch($targetBranchId)->get();

// System-level operations (e.g., scheduled jobs)
$allOverdue = Invoice::withoutGlobalScope(BranchScope::class)
    ->where('status', 'unpaid')
    ->where('due_date', '<', now())
    ->get();
```

### Important: Always qualify the table name in BranchScope to avoid ambiguity in JOINs. Use `$model->getTable() . '.branch_id'` instead of bare `'branch_id'`.

---

## 6. Migration Enforcement

Every migration that creates or modifies a domain table must include `branch_id`. This is enforced by a PostToolUse hook.

### Hook: migration-check.sh

The hook at `.claude/hooks/migration-check.sh` scans newly written migration files. If a `Schema::create` call is found without a `branch_id` column, the hook emits a warning. Exempt tables (companies, branches, migrations, password_resets, personal_access_tokens, jobs, failed_jobs, cache) are skipped.

### Manual Checklist for Migration Review
1. Does the new table have `branch_id`? (Unless it is a system table)
2. Is `branch_id` a foreign key referencing `branches`?
3. Is there an index on `branch_id`?
4. Are unique constraints scoped to `branch_id`?
5. Does the `down()` method fully reverse the `up()`?

---

## 7. Cross-Tenant Prevention

Cross-tenant data leaks are the most critical risk in shared-schema multi-tenancy.

### Foreign Key Validation

When creating records that reference other tenant-scoped tables, validate that the referenced record belongs to the same branch.

```php
// app/Http/Requests/CreateInvoiceRequest.php

public function rules(): array
{
    $branchId = auth()->user()->branch_id;

    return [
        'customer_id' => [
            'required',
            Rule::exists('customers', 'id')->where('branch_id', $branchId),
        ],
        'items.*.product_id' => [
            'required',
            Rule::exists('products', 'id')->where('branch_id', $branchId),
        ],
    ];
}
```

### Relationship Loading Safety

Global scopes apply to eager-loaded relationships automatically. However, raw queries and manual joins bypass scopes. Always verify:

```php
// SAFE: Global scope applies to both Invoice and Customer
$invoices = Invoice::with('customer')->get();

// DANGEROUS: Raw query bypasses global scope
$invoices = DB::table('invoices')
    ->where('customer_id', $customerId)
    ->get();
// FIX: Always add branch_id filter in raw queries
$invoices = DB::table('invoices')
    ->where('branch_id', auth()->user()->branch_id)
    ->where('customer_id', $customerId)
    ->get();
```

### Service-Level Guard

```php
// app/Services/InvoiceService.php

public function findOrFail(int $id): Invoice
{
    // Global scope already filters by branch_id
    // findOrFail will throw 404 if not found in current branch
    return Invoice::findOrFail($id);
}

public function attachCustomer(Invoice $invoice, int $customerId): void
{
    // Verify customer belongs to same branch before attaching
    $customer = Customer::findOrFail($customerId);

    if ($customer->branch_id !== $invoice->branch_id) {
        throw new \DomainException('Customer does not belong to the same branch.');
    }

    $invoice->update(['customer_id' => $customerId]);
}
```

---

## 8. Tenant-Aware Caching

Cache keys must be namespaced per tenant to prevent data leaks through the cache layer.

### Cache Key Prefixing

```php
// app/Services/TenantCache.php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

class TenantCache
{
    /**
     * Generate a tenant-scoped cache key.
     */
    public static function key(string $key): string
    {
        $branchId = auth()->user()->branch_id ?? 'global';
        return "branch:{$branchId}:{$key}";
    }

    public static function get(string $key, mixed $default = null): mixed
    {
        return Cache::get(self::key($key), $default);
    }

    public static function put(string $key, mixed $value, int $ttl = 300): void
    {
        Cache::put(self::key($key), $value, $ttl);
    }

    public static function forget(string $key): void
    {
        Cache::forget(self::key($key));
    }

    /**
     * Flush all cache entries for a specific branch.
     * Requires a cache driver that supports tags (Redis, Memcached).
     */
    public static function flushBranch(int $branchId): void
    {
        Cache::tags(["branch:{$branchId}"])->flush();
    }
}
```

### Usage in Services

```php
public function getDashboardStats(): array
{
    return TenantCache::get('dashboard:stats') ?? $this->buildAndCacheStats();
}

private function buildAndCacheStats(): array
{
    $stats = [
        'total_invoices' => Invoice::count(),
        'unpaid_amount' => Invoice::unpaid()->sum('total_amount'),
        'customers' => Customer::count(),
    ];

    TenantCache::put('dashboard:stats', $stats, 300);
    return $stats;
}
```

---

## 9. Tenant-Aware Queues

Background jobs must carry tenant context so they execute within the correct branch scope.

### Tenant-Aware Job Base Class

```php
// app/Jobs/Concerns/TenantAware.php

namespace App\Jobs\Concerns;

trait TenantAware
{
    public int $branchId;

    public function initializeTenantAware(): void
    {
        if (auth()->check()) {
            $this->branchId = auth()->user()->branch_id;
        }
    }

    /**
     * Set tenant context before the job executes.
     * Call this at the start of handle().
     */
    protected function setTenantContext(): void
    {
        $branch = \App\Models\Branch::findOrFail($this->branchId);
        $admin = $branch->users()->where('role', 'admin')->first();

        if ($admin) {
            auth()->login($admin);
        }

        app(\App\Services\TenantContext::class)->set($this->branchId);
    }
}
```

### Job Implementation

```php
// app/Jobs/GenerateInvoicePdf.php

namespace App\Jobs;

use App\Jobs\Concerns\TenantAware;
use App\Models\Invoice;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateInvoicePdf implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels, TenantAware;

    public function __construct(
        public int $invoiceId
    ) {
        $this->initializeTenantAware();
    }

    public function handle(): void
    {
        $this->setTenantContext();

        // Global scope is now active for this branch
        $invoice = Invoice::with(['customer', 'items'])->findOrFail($this->invoiceId);
        // ... generate PDF
    }
}
```

### Queue Isolation (Optional)

For high-volume tenants, use dedicated queue names:

```php
// Dispatch to a branch-specific queue
GenerateInvoicePdf::dispatch($invoiceId)
    ->onQueue("branch-{$branchId}");
```

---

## 10. Tenant-Aware File Storage

Uploaded files must be segregated by tenant to prevent unauthorized access.

### Storage Path Convention

```
storage/
└── app/
    └── tenants/
        ├── branch-1/
        │   ├── invoices/
        │   │   └── INV-001.pdf
        │   ├── logos/
        │   └── imports/
        ├── branch-2/
        │   ├── invoices/
        │   └── logos/
        └── branch-3/
```

### TenantStorage Service

```php
// app/Services/TenantStorage.php

namespace App\Services;

use Illuminate\Support\Facades\Storage;

class TenantStorage
{
    /**
     * Get the storage path prefix for the current tenant.
     */
    public static function prefix(): string
    {
        $branchId = auth()->user()->branch_id;
        return "tenants/branch-{$branchId}";
    }

    public static function put(string $path, $contents): string
    {
        $fullPath = self::prefix() . '/' . ltrim($path, '/');
        Storage::put($fullPath, $contents);
        return $fullPath;
    }

    public static function get(string $path): ?string
    {
        $fullPath = self::prefix() . '/' . ltrim($path, '/');
        return Storage::get($fullPath);
    }

    public static function url(string $path): string
    {
        $fullPath = self::prefix() . '/' . ltrim($path, '/');
        return Storage::temporaryUrl($fullPath, now()->addMinutes(30));
    }

    public static function delete(string $path): bool
    {
        $fullPath = self::prefix() . '/' . ltrim($path, '/');
        return Storage::delete($fullPath);
    }
}
```

### Access Control for Downloads

```php
// app/Http/Controllers/FileController.php

public function download(string $path)
{
    $fullPath = TenantStorage::prefix() . '/' . $path;

    // Verify the file path starts with the tenant prefix (prevent traversal)
    if (!str_starts_with($fullPath, TenantStorage::prefix())) {
        abort(403);
    }

    if (!Storage::exists($fullPath)) {
        abort(404);
    }

    return Storage::download($fullPath);
}
```

---

## 11. Reporting Across Tenants

Company administrators need consolidated views across branches. This requires carefully bypassing the global scope.

### Company-Level Report Service

```php
// app/Services/CompanyReportService.php

namespace App\Services;

use App\Models\Invoice;
use App\Models\Scopes\BranchScope;

class CompanyReportService
{
    /**
     * Revenue per branch for the given company.
     * Only callable by users with company-admin role.
     */
    public function revenueByBranch(int $companyId, string $from, string $to): array
    {
        return Invoice::withoutGlobalScope(BranchScope::class)
            ->join('branches', 'invoices.branch_id', '=', 'branches.id')
            ->where('branches.company_id', $companyId)
            ->where('invoices.status', 'paid')
            ->whereBetween('invoices.date', [$from, $to])
            ->selectRaw('branches.name as branch_name, SUM(invoices.total_amount) as revenue')
            ->groupBy('branches.id', 'branches.name')
            ->orderByDesc('revenue')
            ->get()
            ->toArray();
    }
}
```

### Authorization Guard

```php
// Always verify the user has company-admin access before bypassing scope
public function consolidatedReport(Request $request, CompanyReportService $service)
{
    $user = $request->user();

    if (!$user->hasRole('company-admin')) {
        abort(403, 'Only company administrators can view consolidated reports.');
    }

    $data = $service->revenueByBranch(
        $user->company_id,
        $request->input('from'),
        $request->input('to')
    );

    return response()->json(['data' => $data]);
}
```

---

## 12. Data Seeding

Multi-tenant seeders must create data scoped to specific branches for development and demo environments.

### Branch-Aware Seeder

```php
// database/seeders/InvoiceSeeder.php

namespace Database\Seeders;

use App\Models\Branch;
use App\Models\Customer;
use App\Models\Invoice;
use App\Models\Scopes\BranchScope;
use Illuminate\Database\Seeder;

class InvoiceSeeder extends Seeder
{
    public function run(): void
    {
        $branches = Branch::all();

        foreach ($branches as $branch) {
            // Get customers for this branch (bypass global scope in seeder)
            $customers = Customer::withoutGlobalScope(BranchScope::class)
                ->where('branch_id', $branch->id)
                ->pluck('id');

            if ($customers->isEmpty()) {
                continue;
            }

            // Create 50 invoices per branch
            Invoice::factory()
                ->count(50)
                ->sequence(fn ($seq) => [
                    'branch_id' => $branch->id,
                    'customer_id' => $customers->random(),
                    'invoice_number' => sprintf('INV-%s-%04d', $branch->code, $seq->index + 1),
                ])
                ->create();
        }
    }
}
```

### Factory with Branch Support

```php
// database/factories/InvoiceFactory.php

class InvoiceFactory extends Factory
{
    public function definition(): array
    {
        return [
            'branch_id' => Branch::factory(),
            'customer_id' => Customer::factory(),
            'invoice_number' => 'INV-' . $this->faker->unique()->numerify('####'),
            'date' => $this->faker->dateTimeBetween('-6 months', 'now'),
            'due_date' => $this->faker->dateTimeBetween('now', '+3 months'),
            'total_amount' => $this->faker->randomFloat(2, 100, 50000),
            'status' => $this->faker->randomElement(['draft', 'sent', 'paid', 'overdue']),
        ];
    }
}
```

---

## 13. Testing Multi-Tenancy

Testing tenant isolation is critical. Every feature test should verify that data does not leak across branches.

### Test Helper Trait

```php
// tests/Concerns/WithTenancy.php

namespace Tests\Concerns;

use App\Models\Branch;
use App\Models\Company;
use App\Models\User;

trait WithTenancy
{
    protected Branch $branch;
    protected Branch $otherBranch;
    protected User $user;
    protected User $otherUser;

    protected function setUpTenancy(): void
    {
        $company = Company::factory()->create();

        $this->branch = Branch::factory()->for($company)->create();
        $this->otherBranch = Branch::factory()->for($company)->create();

        $this->user = User::factory()->create(['branch_id' => $this->branch->id]);
        $this->otherUser = User::factory()->create(['branch_id' => $this->otherBranch->id]);
    }

    protected function actingAsTenant(): static
    {
        return $this->actingAs($this->user);
    }

    protected function actingAsOtherTenant(): static
    {
        return $this->actingAs($this->otherUser);
    }
}
```

### Isolation Test

```php
// tests/Feature/InvoiceTenancyTest.php

namespace Tests\Feature;

use App\Models\Invoice;
use Tests\Concerns\WithTenancy;
use Tests\TestCase;

class InvoiceTenancyTest extends TestCase
{
    use WithTenancy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->setUpTenancy();
    }

    public function test_user_only_sees_own_branch_invoices(): void
    {
        $ownInvoice = Invoice::factory()->create(['branch_id' => $this->branch->id]);
        $otherInvoice = Invoice::factory()->create(['branch_id' => $this->otherBranch->id]);

        $this->actingAsTenant()
            ->getJson('/api/v1/invoices')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $ownInvoice->id);
    }

    public function test_user_cannot_access_other_branch_invoice(): void
    {
        $otherInvoice = Invoice::factory()->create(['branch_id' => $this->otherBranch->id]);

        $this->actingAsTenant()
            ->getJson("/api/v1/invoices/{$otherInvoice->id}")
            ->assertNotFound();
    }

    public function test_user_cannot_update_other_branch_invoice(): void
    {
        $otherInvoice = Invoice::factory()->create(['branch_id' => $this->otherBranch->id]);

        $this->actingAsTenant()
            ->putJson("/api/v1/invoices/{$otherInvoice->id}", ['status' => 'paid'])
            ->assertNotFound();
    }

    public function test_user_cannot_delete_other_branch_invoice(): void
    {
        $otherInvoice = Invoice::factory()->create(['branch_id' => $this->otherBranch->id]);

        $this->actingAsTenant()
            ->deleteJson("/api/v1/invoices/{$otherInvoice->id}")
            ->assertNotFound();
    }

    public function test_creating_invoice_auto_sets_branch_id(): void
    {
        $this->actingAsTenant()
            ->postJson('/api/v1/invoices', [
                'customer_id' => $this->createCustomerForBranch($this->branch)->id,
                'date' => '2026-03-07',
                'due_date' => '2026-04-07',
                'items' => [['product_id' => 1, 'quantity' => 1, 'price' => 100]],
            ])
            ->assertCreated();

        $this->assertDatabaseHas('invoices', [
            'branch_id' => $this->branch->id,
        ]);
    }

    public function test_cross_branch_foreign_key_rejected(): void
    {
        $otherCustomer = Customer::factory()->create(['branch_id' => $this->otherBranch->id]);

        $this->actingAsTenant()
            ->postJson('/api/v1/invoices', [
                'customer_id' => $otherCustomer->id,
                'date' => '2026-03-07',
                'due_date' => '2026-04-07',
                'items' => [['product_id' => 1, 'quantity' => 1, 'price' => 100]],
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('customer_id');
    }
}
```

---

## 14. Inter-Branch Operations

Some operations legitimately span branches: inventory transfers, shared product catalogs, consolidated financial statements.

### Inter-Branch Transfer

```php
// app/Services/InterBranchTransferService.php

namespace App\Services;

use App\Models\Branch;
use App\Models\StockMovement;
use App\Models\Scopes\BranchScope;
use Illuminate\Support\Facades\DB;

class InterBranchTransferService
{
    /**
     * Transfer stock from one branch to another.
     * Requires company-admin or transfer permission.
     */
    public function transfer(
        int $productId,
        int $fromBranchId,
        int $toBranchId,
        float $quantity,
        int $userId
    ): array {
        return DB::transaction(function () use ($productId, $fromBranchId, $toBranchId, $quantity, $userId) {
            // Verify both branches belong to the same company
            $fromBranch = Branch::findOrFail($fromBranchId);
            $toBranch = Branch::findOrFail($toBranchId);

            if ($fromBranch->company_id !== $toBranch->company_id) {
                throw new \DomainException('Cannot transfer between different companies.');
            }

            // Create outbound movement (source branch)
            $outbound = StockMovement::withoutGlobalScope(BranchScope::class)->create([
                'branch_id' => $fromBranchId,
                'product_id' => $productId,
                'quantity' => -$quantity,
                'type' => 'transfer_out',
                'reference_branch_id' => $toBranchId,
                'created_by' => $userId,
            ]);

            // Create inbound movement (destination branch)
            $inbound = StockMovement::withoutGlobalScope(BranchScope::class)->create([
                'branch_id' => $toBranchId,
                'product_id' => $productId,
                'quantity' => $quantity,
                'type' => 'transfer_in',
                'reference_branch_id' => $fromBranchId,
                'created_by' => $userId,
            ]);

            // Log audit trail for both branches
            activity()
                ->causedBy($userId)
                ->withProperties([
                    'product_id' => $productId,
                    'quantity' => $quantity,
                    'from_branch' => $fromBranchId,
                    'to_branch' => $toBranchId,
                ])
                ->log('inter_branch_transfer');

            return [
                'outbound' => $outbound,
                'inbound' => $inbound,
            ];
        });
    }
}
```

### Shared Resources Pattern

Some resources (e.g., a global product catalog or company-wide tax rates) are shared across branches but scoped to the company level.

```php
// Company-level resources use company_id instead of branch_id
// They are accessed via a separate scope:

class CompanyScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        if (auth()->check()) {
            $builder->where(
                $model->getTable() . '.company_id',
                auth()->user()->company_id
            );
        }
    }
}
```

---

## Quick Reference: Checklist for New Multi-Tenant Features

- [ ] Migration includes `branch_id` column with foreign key and index
- [ ] Model uses `HasBranch` trait
- [ ] Unique constraints are scoped to `branch_id`
- [ ] Form requests validate foreign keys with `branch_id` where clause
- [ ] Raw/DB queries explicitly filter by `branch_id`
- [ ] Cache keys are prefixed with branch identifier
- [ ] Queued jobs carry `branch_id` and restore context in `handle()`
- [ ] File storage uses tenant-prefixed paths
- [ ] Feature tests verify isolation (cannot read/write other branch data)
- [ ] Cross-tenant foreign key references are rejected with validation error
- [ ] Inter-branch operations require explicit authorization and audit logging
