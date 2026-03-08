---
name: testing-patterns
description: Use when writing or designing tests. Covers test architecture, PHPUnit/Pest for backend, Vitest for frontend, Cypress/Playwright for E2E, test factories, mocking strategies, multi-tenant isolation testing, and CI integration.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Testing Patterns

## 1. Test Architecture

**Pyramid**: 60% unit (services, models, helpers) | 30% integration (API + DB) | 10% E2E (critical flows).

| Category | Tools | Speed Target |
|----------|-------|-------------|
| Unit | Pest, Vitest | < 10ms each |
| Integration | Pest Feature | < 500ms each |
| E2E | Cypress, Playwright | < 30s each |
| Contract | Pact, Spectral | < 100ms each |
| Performance | k6 | Minutes |

**Directory structure**: `tests/Unit/{Services,Models,Helpers}`, `tests/Feature/{Api,MultiTenant,Workflows}`, `tests/E2E/`, `tests/Factories/`, `tests/Fixtures/`.

**Naming**: Files `{Subject}Test.php`. Tests: `it('creates an invoice with correct totals')`. Bug regressions include ticket: `it('calculates tax correctly (fixes #167)')`.

---

## 2. Pest Patterns (Backend)

### Describe/It with Setup

```php
describe('PayrollService', function () {
    beforeEach(function () {
        $this->branch = Branch::factory()->create();
        $this->user = User::factory()->for($this->branch)->create();
        $this->actingAs($this->user);
        $this->service = app(PayrollService::class);
    });

    it('sums basic pay and allowances', function () {
        $employee = Employee::factory()
            ->has(SalaryComponent::factory()->state(['type' => 'basic', 'amount' => 5000]))
            ->has(SalaryComponent::factory()->state(['type' => 'housing', 'amount' => 1500]))
            ->create(['branch_id' => $this->branch->id]);

        expect($this->service->calculateSalary($employee, '2026-03')->gross)->toBe(6500.0);
    });
});
```

### Datasets (Parameterized)

```php
it('validates status transitions', function (string $from, string $to, bool $allowed) {
    $invoice = Invoice::factory()->create(['status' => $from, 'branch_id' => $this->branch->id]);
    if ($allowed) { expect(fn () => $invoice->transitionTo($to))->not->toThrow(Exception::class); }
    else { expect(fn () => $invoice->transitionTo($to))->toThrow(InvalidStatusTransition::class); }
})->with([
    'draft to sent' => ['draft', 'sent', true],
    'sent to paid' => ['sent', 'paid', true],
    'draft to paid' => ['draft', 'paid', false],
    'paid to draft' => ['paid', 'draft', false],
]);
```

### Custom Expectations

```php
// tests/Pest.php
expect()->extend('toBeValidMoney', function () {
    return $this->toBeFloat()->toBeGreaterThanOrEqual(0)->and(round($this->value, 2))->toBe($this->value);
});
```

---

## 3. Feature Tests (API)

```php
it('creates an invoice and returns 201', function () {
    $customer = Customer::factory()->create(['branch_id' => $this->branch->id]);
    $product = Product::factory()->create(['branch_id' => $this->branch->id, 'price' => 100]);

    $this->postJson('/api/v1/invoices', [
        'customer_id' => $customer->id, 'date' => '2026-03-06', 'due_date' => '2026-04-05',
        'items' => [['product_id' => $product->id, 'quantity' => 3, 'price' => 100]],
    ])->assertCreated()
      ->assertJsonStructure(['data' => ['id', 'invoice_number', 'total', 'status']])
      ->assertJsonPath('data.status', 'draft');
});

it('returns 422 with validation errors', function () {
    $this->postJson('/api/v1/invoices', [])->assertUnprocessable()
         ->assertJsonValidationErrors(['customer_id', 'date', 'due_date', 'items']);
});
```

**Required test cases per endpoint**: 201/200 success, 422 validation, 401 unauth, 403 forbidden, 404 for other branch (tenant isolation).

---

## 4. Model Factories

```php
class InvoiceFactory extends Factory
{
    public function definition(): array
    {
        return [
            'branch_id' => Branch::factory(), 'customer_id' => Customer::factory(),
            'invoice_number' => $this->faker->unique()->numerify('INV-####'),
            'date' => $this->faker->date(), 'due_date' => fn ($a) => Carbon::parse($a['date'])->addDays(30),
            'status' => 'draft', 'subtotal' => 0, 'tax' => 0, 'total' => 0,
        ];
    }

    public function paid(): static { return $this->state(fn () => ['status' => 'paid', 'paid_at' => now()]); }
    public function overdue(): static { return $this->state(fn () => ['status' => 'unpaid', 'due_date' => now()->subDays(30)]); }

    public function withItems(int $count = 3): static
    {
        return $this->afterCreating(function (Invoice $inv) use ($count) {
            InvoiceItem::factory()->count($count)->create(['invoice_id' => $inv->id]);
            $inv->recalculateTotals();
        });
    }

    public function forBranch(Branch $branch): static
    {
        return $this->state(fn () => ['branch_id' => $branch->id])
            ->for(Customer::factory()->state(['branch_id' => $branch->id]), 'customer');
    }
}

// Usage: Invoice::factory()->forBranch($branch)->withItems(5)->paid()->create();
```

---

## 5. Mocking

```php
// Mail
Mail::fake();
$this->postJson("/api/v1/invoices/{$invoice->id}/send");
Mail::assertSent(InvoiceMail::class, fn ($m) => $m->hasTo($invoice->customer->email));

// Queue
Queue::fake();
$this->postJson("/api/v1/invoices/{$invoice->id}/generate-pdf");
Queue::assertPushed(GenerateInvoicePdf::class, fn ($j) => $j->invoice->id === $invoice->id);

// HTTP (third-party APIs)
Http::fake(['api.exchangerate.com/*' => Http::response(['rates' => ['AED' => 3.67]], 200)]);
expect(app(CurrencyService::class)->getRate('USD', 'AED'))->toBe(3.67);

// Spy (side-effect verification)
$spy = Mockery::spy(AuditLogger::class);
$this->app->instance(AuditLogger::class, $spy);
// ... perform action ...
$spy->shouldHaveReceived('log')->with('invoice.deleted', Mockery::on(fn ($d) => $d['invoice_id'] === $id))->once();

// Storage
Storage::fake('s3');
// ... upload action ...
Storage::disk('s3')->assertExists("invoices/{$id}/receipt.pdf");
```

---

## 6. Multi-Tenant Isolation (required for every feature)

```php
describe('Multi-Tenant Isolation', function () {
    beforeEach(function () {
        $this->branchA = Branch::factory()->create();
        $this->branchB = Branch::factory()->create();
        $this->userA = User::factory()->for($this->branchA)->create();
        $this->userB = User::factory()->for($this->branchB)->create();
    });

    it('scopes index to current branch', function () {
        Invoice::factory()->count(5)->create(['branch_id' => $this->branchA->id]);
        Invoice::factory()->count(3)->create(['branch_id' => $this->branchB->id]);
        $this->actingAs($this->userA)->getJson('/api/v1/invoices')->assertJsonCount(5, 'data');
        $this->actingAs($this->userB)->getJson('/api/v1/invoices')->assertJsonCount(3, 'data');
    });

    it('returns 404 for cross-branch access', function () {
        $inv = Invoice::factory()->create(['branch_id' => $this->branchA->id]);
        $this->actingAs($this->userB);
        $this->getJson("/api/v1/invoices/{$inv->id}")->assertNotFound();
        $this->putJson("/api/v1/invoices/{$inv->id}", [])->assertNotFound();
        $this->deleteJson("/api/v1/invoices/{$inv->id}")->assertNotFound();
    });

    it('branch_id is immutable on update', function () {
        $this->actingAs($this->userA);
        $inv = Invoice::factory()->create(['branch_id' => $this->branchA->id]);
        $this->putJson("/api/v1/invoices/{$inv->id}", ['branch_id' => $this->branchB->id]);
        expect($inv->fresh()->branch_id)->toBe($this->branchA->id);
    });
});
```

Reusable trait: `assertBranchIsolation(string $endpoint, string $factoryClass)` creates records in branch A, asserts 404 from branch B user.

---

## 7. Frontend Testing (Vitest)

```typescript
// Component
const wrapper = mount(InvoiceForm, {
  props: { customerId: 1 },
  global: { plugins: [createTestingPinia({ createSpy: vi.fn })] },
});
await wrapper.find('[data-testid="add-item"]').trigger('click');
expect(wrapper.findAll('[data-testid="line-item"]')).toHaveLength(1);

// Mock API
vi.mock('@/services/api', () => ({ api: { get: vi.fn(), post: vi.fn() } }));
vi.mocked(api.get).mockResolvedValue({ data: { data: [{ id: 1 }], meta: { total: 1 } } });
```

---

## 8. E2E (Cypress / Playwright)

**Cypress**: Page Object pattern with `cy.get('[data-cy="..."]')`. Custom commands for `login` (using `cy.session`), `createInvoice`. API stubbing with `cy.intercept`.

**Playwright**: Fixture-based with `test.extend<Fixtures>()`. Page objects with `getByTestId` locators. Config: `fullyParallel: true`, `trace: 'on-first-retry'`, `screenshot: 'only-on-failure'`.

---

## 9. CI Integration

```yaml
backend:
  services: { postgres: { image: postgres:16 } }
  steps:
    - composer install
    - php artisan test --parallel --processes=4 --coverage-clover=coverage.xml

frontend:
  steps:
    - npm ci
    - npx vitest run --coverage

e2e:
  needs: [backend, frontend]
  steps:
    - docker compose -f docker-compose.test.yml up -d
    - cypress run (wait-on http://localhost:8000/api/health)
```

Coverage threshold: `--coverage-min=80`. Flaky test detection with `--retry=2`.

---

## 10. Test Data Rules

- **Factory-first**: Every test creates its own data. Never hardcode IDs or rely on seeders.
- **Isolation**: `RefreshDatabase` for feature tests. Faked services reset per test.
- **Time**: Use `Carbon::setTestNow()`, reset in tearDown.
- **Global config**: `uses(TestCase::class, RefreshDatabase::class)->in('Feature');`

---

## Quick Reference

```bash
# Backend
php artisan test --parallel --processes=4     # parallel
php artisan test --filter=InvoiceService      # filter
php artisan test --coverage --min=80          # coverage gate

# Frontend
npx vitest run --coverage                    # with coverage

# E2E
npx cypress run                              # headless
npx playwright test --trace on               # with trace

# Performance
k6 run tests/performance/api-load.js
```
