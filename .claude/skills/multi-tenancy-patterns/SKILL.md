---
name: multi-tenancy-patterns
description: Use when implementing or reviewing multi-tenant features. Covers shared database with branch_id isolation, tenant resolution, data scoping, cross-tenant prevention, tenant-aware caching, queues, file storage, and testing strategies.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Multi-Tenancy Patterns

Shared-database multi-tenancy using the `branch_id` pattern in Laravel.

---

## 1. Architecture Decision

| Factor | Shared Schema (ours) | Separate DB | Separate Schema |
|--------|---------------------|-------------|-----------------|
| Isolation | Query-level | Database-level | Schema-level |
| Ops cost | Low | High | Medium |
| Migrations | Single run | Per-tenant | Per-schema |
| Cross-tenant reports | Easy | Hard | Medium |
| Scale | Thousands | Hundreds | Hundreds |

We use **shared database, shared schema** with `branch_id` on every domain table.

```
companies (1) ---> branches (many) ---> users, invoices, products, ... (all scoped)
```

---

## 2. Migration Template

```php
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

    $table->index(['branch_id', 'status', 'date']);
    $table->unique(['branch_id', 'invoice_number']); // scoped uniqueness
});
```

**Rules**: `branch_id` is non-nullable, composite indexes on `(branch_id, ...)`, unique constraints scoped to `branch_id`. Exempt tables: `companies`, `branches`, `migrations`, `jobs`, `cache`.

---

## 3. Tenant Resolution

### Middleware (Primary: auth-based)

```php
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

**Alternatives**: Subdomain-based (`acme.app.example.com` -> lookup branch by slug), Header-based (`X-Branch-Id` header with access verification).

---

## 4. HasBranch Trait + BranchScope

```php
// app/Models/Scopes/BranchScope.php
class BranchScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        if (auth()->check() && auth()->user()->branch_id) {
            $builder->where($model->getTable() . '.branch_id', auth()->user()->branch_id);
        }
    }
}

// app/Models/Concerns/HasBranch.php
trait HasBranch
{
    public static function bootHasBranch(): void
    {
        static::addGlobalScope(new BranchScope());
        static::creating(function ($model) {
            if (empty($model->branch_id) && auth()->check()) {
                $model->branch_id = auth()->user()->branch_id;
            }
        });
    }

    public function branch(): BelongsTo { return $this->belongsTo(Branch::class); }

    public function scopeForBranch($query, int $branchId)
    {
        return $query->withoutGlobalScope(BranchScope::class)->where('branch_id', $branchId);
    }
}
```

**Critical**: Always qualify table name in scope (`$model->getTable() . '.branch_id'`) to avoid JOIN ambiguity.

### Bypassing for Reports

```php
// Company-level aggregation (requires company-admin role check)
Invoice::withoutGlobalScope(BranchScope::class)
    ->whereHas('branch', fn ($q) => $q->where('company_id', $companyId))
    ->where('status', 'paid')->sum('total_amount');
```

---

## 5. Cross-Tenant Prevention

### Foreign Key Validation in Requests

```php
public function rules(): array
{
    $branchId = auth()->user()->branch_id;
    return [
        'customer_id' => ['required', Rule::exists('customers', 'id')->where('branch_id', $branchId)],
        'items.*.product_id' => ['required', Rule::exists('products', 'id')->where('branch_id', $branchId)],
    ];
}
```

### Raw Query Safety

Eloquent with global scopes is safe. Raw `DB::table()` queries bypass scopes -- always add `->where('branch_id', auth()->user()->branch_id)` manually.

---

## 6. Tenant-Aware Caching

Namespace all cache keys per tenant to prevent data leaks.

```php
class TenantCache
{
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

    public static function flushBranch(int $branchId): void
    {
        Cache::tags(["branch:{$branchId}"])->flush();
    }
}
```

---

## 7. Tenant-Aware Queues

Jobs must carry `branchId` and restore context in `handle()`.

```php
trait TenantAware
{
    public int $branchId;

    public function initializeTenantAware(): void
    {
        if (auth()->check()) $this->branchId = auth()->user()->branch_id;
    }

    protected function setTenantContext(): void
    {
        $branch = Branch::findOrFail($this->branchId);
        $admin = $branch->users()->where('role', 'admin')->first();
        if ($admin) auth()->login($admin);
        app(TenantContext::class)->set($this->branchId);
    }
}
```

For high-volume tenants, dispatch to branch-specific queues: `->onQueue("branch-{$branchId}")`.

---

## 8. Tenant-Aware File Storage

```
storage/app/tenants/branch-{id}/invoices/
                                 /logos/
                                 /imports/
```

Prefix all paths with `tenants/branch-{branchId}/`. On downloads, verify the resolved path starts with the tenant prefix to prevent traversal attacks.

---

## 9. Inter-Branch Operations

Transfers, shared catalogs, and consolidated reports legitimately span branches. Requirements:
- Verify both branches belong to the same company
- Use `withoutGlobalScope(BranchScope::class)` with explicit `branch_id` assignment
- Wrap in DB transaction
- Log audit trail for both branches
- Require company-admin or explicit transfer permission

For company-level shared resources (product catalog, tax rates), use `company_id` with a `CompanyScope` instead.

---

## 10. Testing Multi-Tenancy

### Test Helper Trait

```php
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
}
```

### Required Test Cases (every feature)

1. User only sees own branch data in list endpoints
2. GET/PUT/DELETE on other branch record returns 404
3. Creating a record auto-sets `branch_id`
4. Cross-branch foreign key (e.g., other branch's customer) returns 422
5. `branch_id` is immutable on update

---

## Checklist for New Multi-Tenant Features

- [ ] Migration includes `branch_id` with foreign key and index
- [ ] Model uses `HasBranch` trait
- [ ] Unique constraints scoped to `branch_id`
- [ ] Form requests validate foreign keys with `branch_id` where clause
- [ ] Raw/DB queries explicitly filter by `branch_id`
- [ ] Cache keys prefixed with branch identifier
- [ ] Queued jobs carry `branch_id` and restore context in `handle()`
- [ ] File storage uses tenant-prefixed paths
- [ ] Feature tests verify isolation across branches
- [ ] Inter-branch operations require authorization and audit logging
